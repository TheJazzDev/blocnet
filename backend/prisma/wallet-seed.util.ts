import {
  type ChainEnvironment,
  KycStatus,
  LedgerAccountType,
  type Prisma,
  type PrismaClient,
  WalletStatus,
} from '@prisma/client';
import { createHash } from 'crypto';

const BNT_CURRENCY = 'BNT';

export type WalletBackfillOptions = {
  chainEnvironment: ChainEnvironment;
  chainId: number;
  walletEnabled: boolean;
  forceReadyMock?: boolean;
};

export type WalletBackfillResult = {
  processedUsers: number;
  walletsCreated: number;
  walletsUpdated: number;
  kycProfilesCreated: number;
  userAccountsEnsured: number;
  holdAccountsEnsured: number;
};

export function parseBooleanEnv(value: string | undefined, fallback = false): boolean {
  if (value == null || value.trim().length === 0) {
    return fallback;
  }

  switch (value.trim().toLowerCase()) {
    case '1':
    case 'true':
    case 'yes':
    case 'y':
    case 'on':
      return true;
    case '0':
    case 'false':
    case 'no':
    case 'n':
    case 'off':
      return false;
    default:
      return fallback;
  }
}

export function resolveWalletChainEnvironment(
  rawValue: string | undefined,
): ChainEnvironment {
  return rawValue?.trim().toLowerCase() === 'mainnet' ? 'mainnet' : 'testnet';
}

export function resolveWalletChainId(
  chainEnvironment: ChainEnvironment,
  env: NodeJS.ProcessEnv,
): number {
  const defaultChainId = chainEnvironment === 'mainnet' ? '56' : '97';
  const raw = env.BSC_CHAIN_ID?.trim() || defaultChainId;
  const parsed = Number(raw);

  if (!Number.isFinite(parsed) || parsed <= 0) {
    throw new Error(`Invalid chain id value: ${raw}`);
  }

  return parsed;
}

export async function backfillWalletDomainForUsers(
  prisma: PrismaClient,
  userIds: string[],
  options: WalletBackfillOptions,
): Promise<WalletBackfillResult> {
  const uniqueUserIds = [...new Set(userIds.map((id) => id.trim()).filter(Boolean))];

  if (uniqueUserIds.length === 0) {
    return {
      processedUsers: 0,
      walletsCreated: 0,
      walletsUpdated: 0,
      kycProfilesCreated: 0,
      userAccountsEnsured: 0,
      holdAccountsEnsured: 0,
    };
  }

  const [existingWalletRows, existingKycRows] = await Promise.all([
    prisma.userWallet.findMany({
      where: { userId: { in: uniqueUserIds } },
      select: {
        id: true,
        userId: true,
        chainEnvironment: true,
        chainId: true,
        status: true,
        address: true,
        providerWalletId: true,
        provisionedAt: true,
        failureReason: true,
      },
    }),
    prisma.kycProfile.findMany({
      where: { userId: { in: uniqueUserIds } },
      select: { userId: true },
    }),
  ]);

  const existingWalletByUserId = new Map(
    existingWalletRows.map((row) => [row.userId, row]),
  );
  const existingKycUserIds = new Set(existingKycRows.map((row) => row.userId));

  let walletsCreated = 0;
  let walletsUpdated = 0;
  let kycProfilesCreated = 0;
  let userAccountsEnsured = 0;
  let holdAccountsEnsured = 0;

  for (const userId of uniqueUserIds) {
    if (!existingKycUserIds.has(userId)) {
      kycProfilesCreated += 1;
    }

    await prisma.kycProfile.upsert({
      where: { userId },
      update: {},
      create: {
        userId,
        status: KycStatus.not_submitted,
        tier: 'basic',
      },
    });

    const existingWallet = existingWalletByUserId.get(userId);
    const mockWallet =
      options.forceReadyMock === true
        ? createDeterministicMockWallet(userId)
        : null;

    let walletId: string;

    if (!existingWallet) {
      const createdWallet = await prisma.userWallet.create({
        data: {
          userId,
          chainEnvironment: options.chainEnvironment,
          chainId: options.chainId,
          status: mockWallet
            ? WalletStatus.ready
            : options.walletEnabled
              ? WalletStatus.provisioning
              : WalletStatus.disabled,
          providerWalletId: mockWallet?.providerWalletId,
          address: mockWallet?.address,
          provisionedAt: mockWallet ? new Date() : null,
          failureReason: null,
        },
        select: { id: true },
      });

      walletId = createdWallet.id;
      walletsCreated += 1;
    } else {
      walletId = existingWallet.id;

      const updateData: Prisma.UserWalletUpdateInput = {};

      if (existingWallet.chainEnvironment !== options.chainEnvironment) {
        updateData.chainEnvironment = options.chainEnvironment;
      }
      if (existingWallet.chainId !== options.chainId) {
        updateData.chainId = options.chainId;
      }

      if (mockWallet) {
        if (existingWallet.status !== WalletStatus.ready) {
          updateData.status = WalletStatus.ready;
        }
        if (existingWallet.providerWalletId !== mockWallet.providerWalletId) {
          updateData.providerWalletId = mockWallet.providerWalletId;
        }
        if (existingWallet.address !== mockWallet.address) {
          updateData.address = mockWallet.address;
        }
        if (!existingWallet.provisionedAt) {
          updateData.provisionedAt = new Date();
        }
        if (existingWallet.failureReason !== null) {
          updateData.failureReason = null;
        }
      } else if (!options.walletEnabled) {
        if (existingWallet.status !== WalletStatus.disabled) {
          updateData.status = WalletStatus.disabled;
        }
      } else if (existingWallet.status === WalletStatus.disabled) {
        updateData.status = WalletStatus.provisioning;
      }

      if (Object.keys(updateData).length > 0) {
        await prisma.userWallet.update({
          where: { id: existingWallet.id },
          data: updateData,
        });
        walletsUpdated += 1;
      }
    }

    await prisma.ledgerAccount.upsert({
      where: {
        userId_accountType_currency: {
          userId,
          accountType: LedgerAccountType.user,
          currency: BNT_CURRENCY,
        },
      },
      update: {
        walletId,
      },
      create: {
        userId,
        walletId,
        accountType: LedgerAccountType.user,
        currency: BNT_CURRENCY,
      },
    });
    userAccountsEnsured += 1;

    await prisma.ledgerAccount.upsert({
      where: {
        userId_accountType_currency: {
          userId,
          accountType: LedgerAccountType.hold,
          currency: BNT_CURRENCY,
        },
      },
      update: {
        walletId,
      },
      create: {
        userId,
        walletId,
        accountType: LedgerAccountType.hold,
        currency: BNT_CURRENCY,
      },
    });
    holdAccountsEnsured += 1;
  }

  return {
    processedUsers: uniqueUserIds.length,
    walletsCreated,
    walletsUpdated,
    kycProfilesCreated,
    userAccountsEnsured,
    holdAccountsEnsured,
  };
}

function createDeterministicMockWallet(userId: string) {
  const hash = createHash('sha256').update(`wallet-seed:${userId}`).digest('hex');

  return {
    providerWalletId: `seed_mock_${hash.slice(0, 24)}`,
    address: `0x${hash.slice(0, 40)}`,
  };
}
