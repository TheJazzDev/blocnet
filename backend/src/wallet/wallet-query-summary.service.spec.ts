import { Prisma, WalletAsset } from '@prisma/client';
import { WalletQueryService } from './wallet-query.service';
import { WalletAssetPricingService } from './wallet-asset-pricing.service';
import { WalletConfigService } from './wallet-config.service';
import { WalletProvisioningService } from './wallet-provisioning.service';
import { PrismaService } from '../prisma/prisma.service';
import { WalletAdminService } from './wallet-admin.service';
import { AuditLogService } from '../audit-log/audit-log.service';
import { WalletDepositIndexerService } from './wallet-deposit-indexer.service';
import { TurnkeyCustodyAdapter } from './custody/turnkey-custody.adapter';

/**
 * `GET /wallet/me` is reachable by any signed-in user and returns their own
 * wallet. "Their own" is not a licence to hand over custody internals: the
 * provider name, the provider's internal wallet id and the raw provider error
 * string are operational detail that belongs on the admin surface only.
 *
 * These tests pin both halves of that split — the user payload must not carry
 * the three fields, and the admin payload must keep the detail it has today.
 */
const wallet = {
  id: 'wallet-1',
  userId: 'user-1',
  status: 'ready',
  address: '0xabc',
  chainId: 97,
  chainEnvironment: 'testnet',
  provider: 'turnkey',
  providerWalletId: 'tk-wallet-abc',
  failureReason: 'provider rejected sub-organization creation: 429 rate limit',
  provisionedAt: new Date('2026-01-01T00:00:00.000Z'),
};

const CUSTODY_FIELDS = ['provider', 'providerWalletId', 'failureReason'];

describe('WalletQueryService.getWalletSummary', () => {
  const account = {
    currency: WalletAsset.BNT,
    available: new Prisma.Decimal('10.5'),
    pending: new Prisma.Decimal('1'),
    locked: new Prisma.Decimal('0'),
  };

  const walletProvisioningService = {
    ensureWalletForUser: jest.fn().mockResolvedValue(wallet),
    ensureUserLedgerAccount: jest.fn().mockResolvedValue(account),
  } as unknown as WalletProvisioningService;

  const walletConfigService = {
    walletEnabled: true,
    depositsEnabled: true,
    withdrawalsEnabled: false,
    supportedAssets: [WalletAsset.BNT],
    withdrawalEnabledAssets: [WalletAsset.BNT],
    getAssetKind: () => 'token',
  } as unknown as WalletConfigService;

  const prisma = {
    kycProfile: {
      findUnique: jest.fn().mockResolvedValue(null),
    },
  } as unknown as PrismaService;

  const walletAssetPricingService = {
    getUsdPrices: jest.fn().mockResolvedValue({
      [WalletAsset.BNT]: { usdPrice: '0.5', source: 'oracle' },
    }),
  } as unknown as WalletAssetPricingService;

  let service: WalletQueryService;

  beforeEach(() => {
    service = new WalletQueryService(
      prisma,
      walletConfigService,
      walletProvisioningService,
      walletAssetPricingService,
    );
  });

  it('returns only the user-facing wallet coordinates', async () => {
    const summary = await service.getWalletSummary('user-1');

    expect(summary.wallet).toEqual({
      id: 'wallet-1',
      status: 'ready',
      address: '0xabc',
      chainId: 97,
      chainEnvironment: 'testnet',
      provisionedAt: wallet.provisionedAt,
    });
  });

  it.each(CUSTODY_FIELDS)(
    'does not expose %s on the user payload',
    async (field) => {
      const summary = await service.getWalletSummary('user-1');

      expect(summary.wallet).not.toHaveProperty(field);
    },
  );

  it('never serialises the provider wallet id or provider error anywhere in the payload', async () => {
    const summary = await service.getWalletSummary('user-1');
    const serialised = JSON.stringify(summary);

    expect(serialised).not.toContain('tk-wallet-abc');
    expect(serialised).not.toContain('provider rejected');
  });

  it('still reports wallet state through status, which is what a user can act on', async () => {
    (
      walletProvisioningService.ensureWalletForUser as jest.Mock
    ).mockResolvedValueOnce({
      ...wallet,
      status: 'disabled',
    });

    const summary = await service.getWalletSummary('user-1');

    expect(summary.wallet.status).toBe('disabled');
    expect(summary.features.userWalletEnabled).toBe(false);
  });
});

describe('WalletAdminService keeps custody detail', () => {
  const prisma = {
    profile: {
      findMany: jest.fn().mockResolvedValue([
        {
          id: 'user-1',
          email: 'user@example.com',
          displayName: 'User One',
          username: 'userone',
          roles: [{ role: 'user' }],
          createdAt: new Date('2026-01-01T00:00:00.000Z'),
          wallet,
          kycProfile: null,
        },
      ]),
      count: jest.fn().mockResolvedValue(1),
      findUnique: jest.fn().mockResolvedValue({
        id: 'user-1',
        email: 'user@example.com',
        displayName: 'User One',
      }),
    },
    ledgerAccount: {
      findMany: jest.fn().mockResolvedValue([]),
    },
    userWallet: {
      findUnique: jest.fn().mockResolvedValue(wallet),
      update: jest.fn().mockResolvedValue({
        ...wallet,
        status: 'disabled',
        failureReason: 'Disabled by admin',
        updatedAt: new Date('2026-02-01T00:00:00.000Z'),
      }),
    },
  } as unknown as PrismaService;

  const auditLogService = {
    create: jest.fn().mockResolvedValue(undefined),
  } as unknown as AuditLogService;

  const walletConfigService = {
    walletChainEnvironment: 'testnet',
    walletProvisionChainId: 97,
  } as unknown as WalletConfigService;

  let service: WalletAdminService;

  beforeEach(() => {
    service = new WalletAdminService(
      prisma,
      auditLogService,
      walletConfigService,
      {} as unknown as WalletDepositIndexerService,
      {} as unknown as TurnkeyCustodyAdapter,
    );
  });

  it('still returns the provider wallet id on the admin user list', async () => {
    const result = await service.listWalletUsers({});

    expect(result.data[0].wallet).toEqual(
      expect.objectContaining({
        id: 'wallet-1',
        status: 'ready',
        address: '0xabc',
        providerWalletId: 'tk-wallet-abc',
        chainId: 97,
      }),
    );
  });

  it('still returns the provider wallet id when an admin toggles wallet status', async () => {
    const result = await service.updateWalletUserStatus(
      'admin-1',
      'user-1',
      true,
    );

    expect(result.wallet.providerWalletId).toBe('tk-wallet-abc');
    expect(result.wallet.status).toBe('disabled');
  });
});
