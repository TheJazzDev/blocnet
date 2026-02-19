import { Inject, Injectable, Logger } from '@nestjs/common';
import {
  KycStatus,
  LedgerAccountType,
  WalletStatus,
  type LedgerAccount,
  type UserWallet,
} from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { FinancialAuditActions } from '../common/constants/financial-audit-actions';
import { createDeterministicIdempotencyKey } from '../common/utils/idempotency.util';
import { PrismaService } from '../prisma/prisma.service';
import { CUSTODY_ADAPTER } from './custody/custody.adapter';
import type { CustodyAdapter } from './custody/custody.adapter';
import { WalletConfigService } from './wallet-config.service';

@Injectable()
export class WalletProvisioningService {
  private readonly logger = new Logger(WalletProvisioningService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
    private readonly walletConfigService: WalletConfigService,
    @Inject(CUSTODY_ADAPTER) private readonly custodyAdapter: CustodyAdapter,
  ) {}

  async ensureWalletForUser(userId: string): Promise<UserWallet> {
    await this.prisma.kycProfile.upsert({
      where: { userId },
      update: {},
      create: {
        userId,
        status: KycStatus.not_submitted,
        tier: 'basic',
      },
    });

    let wallet = await this.prisma.userWallet.findUnique({
      where: { userId },
    });

    if (!wallet) {
      wallet = await this.prisma.userWallet.create({
        data: {
          userId,
          chainEnvironment: 'testnet',
          chainId: this.walletConfigService.bscTestnetChainId,
          status: this.walletConfigService.walletEnabled
            ? WalletStatus.provisioning
            : WalletStatus.disabled,
        },
      });

      await this.auditLogService.create({
        actorId: userId,
        action: FinancialAuditActions.WalletProvisionQueued,
        resourceType: 'user_wallet',
        resourceId: wallet.id,
      });
    }

    await this.ensureUserLedgerAccount(userId, wallet.id);

    if (!this.walletConfigService.walletEnabled) {
      if (wallet.status !== WalletStatus.disabled) {
        wallet = await this.prisma.userWallet.update({
          where: { id: wallet.id },
          data: {
            status: WalletStatus.disabled,
          },
        });
      }
      return wallet;
    }

    if (wallet.status === WalletStatus.ready && wallet.address) {
      return wallet;
    }

    if (
      wallet.status === WalletStatus.error &&
      wallet.lastProvisionAttemptAt &&
      Date.now() - wallet.lastProvisionAttemptAt.getTime() < 60_000
    ) {
      return wallet;
    }

    try {
      await this.prisma.userWallet.update({
        where: { id: wallet.id },
        data: {
          status: WalletStatus.provisioning,
          failureReason: null,
          lastProvisionAttemptAt: new Date(),
        },
      });

      const provisioned = await this.custodyAdapter.createWallet({
        userId,
        idempotencyKey: createDeterministicIdempotencyKey(
          'wallet-provision',
          userId,
        ),
      });

      wallet = await this.prisma.userWallet.update({
        where: { id: wallet.id },
        data: {
          providerWalletId: provisioned.providerWalletId,
          address: provisioned.address,
          status: WalletStatus.ready,
          provisionedAt: new Date(),
          failureReason: null,
        },
      });

      await this.auditLogService.create({
        actorId: userId,
        action: FinancialAuditActions.WalletProvisionReady,
        resourceType: 'user_wallet',
        resourceId: wallet.id,
        metadata: {
          providerWalletId: provisioned.providerWalletId,
          address: provisioned.address,
        },
      });
      return wallet;
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'wallet provisioning failed';

      this.logger.warn(
        `Wallet provisioning failed userId=${userId} reason=${message}`,
      );

      wallet = await this.prisma.userWallet.update({
        where: { id: wallet.id },
        data: {
          status: WalletStatus.error,
          failureReason: message,
          lastProvisionAttemptAt: new Date(),
        },
      });

      await this.auditLogService.create({
        actorId: userId,
        action: FinancialAuditActions.WalletProvisionFailed,
        resourceType: 'user_wallet',
        resourceId: wallet.id,
        metadata: {
          reason: message,
        },
      });

      return wallet;
    }
  }

  async ensureUserLedgerAccount(
    userId: string,
    walletId: string,
    accountType: LedgerAccountType = LedgerAccountType.user,
  ): Promise<LedgerAccount> {
    return this.prisma.ledgerAccount.upsert({
      where: {
        userId_accountType_currency: {
          userId,
          accountType,
          currency: 'BNT',
        },
      },
      update: {
        walletId,
      },
      create: {
        userId,
        walletId,
        accountType,
        currency: 'BNT',
      },
    });
  }

  async ensurePlatformAccount(
    accountType: 'treasury' | 'fee',
  ): Promise<LedgerAccount> {
    const existing = await this.prisma.ledgerAccount.findFirst({
      where: {
        userId: null,
        accountType,
        currency: 'BNT',
      },
    });

    if (existing) {
      return existing;
    }

    return this.prisma.ledgerAccount.create({
      data: {
        userId: null,
        accountType,
        currency: 'BNT',
      },
    });
  }
}
