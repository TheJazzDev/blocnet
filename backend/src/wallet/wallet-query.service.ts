import { Injectable } from '@nestjs/common';
import {
  KycStatus,
  LedgerAccountType,
  LedgerReason,
  Prisma,
  WalletAsset,
  WalletStatus,
  WithdrawalStatus,
  type LedgerEntry,
  type UserWallet,
} from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { PrismaService } from '../prisma/prisma.service';
import { normalizePagination } from '../common/utils/pagination.util';
import { ListWalletTransactionsQuery } from './dto/list-wallet-transactions.query';
import { ListWithdrawalsQuery } from './dto/list-withdrawals.query';
import { DECIMAL_ZERO, toDecimalString } from './types/decimal';
import { normalizeWalletAsset, WALLET_ASSETS } from './wallet-asset.util';
import { WalletAssetPricingService } from './wallet-asset-pricing.service';
import { WalletConfigService } from './wallet-config.service';
import { WalletProvisioningService } from './wallet-provisioning.service';
import { BadRequestException } from '@nestjs/common';

@Injectable()
export class WalletQueryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly walletConfigService: WalletConfigService,
    private readonly walletProvisioningService: WalletProvisioningService,
    private readonly walletAssetPricingService: WalletAssetPricingService,
  ) {}

  async getWalletSummary(userId: string) {
    const wallet =
      await this.walletProvisioningService.ensureWalletForUser(userId);

    const supportedAssets = this.walletConfigService.supportedAssets;
    const [kycProfile, prices] = await Promise.all([
      this.prisma.kycProfile.findUnique({
        where: { userId },
        select: {
          status: true,
          tier: true,
          submittedAt: true,
          reviewedAt: true,
        },
      }),
      this.walletAssetPricingService.getUsdPrices(supportedAssets),
    ]);

    const userAccounts = await Promise.all(
      supportedAssets.map((asset) =>
        this.walletProvisioningService.ensureUserLedgerAccount(
          userId,
          wallet.id,
          LedgerAccountType.user,
          asset,
        ),
      ),
    );

    const accountByAsset = new Map<
      WalletAsset,
      (typeof userAccounts)[number]
    >();
    for (const account of userAccounts) {
      const currency = normalizeWalletAsset(account.currency);
      if (!currency) continue;
      accountByAsset.set(currency, account);
    }

    const bntAccount = accountByAsset.get(WalletAsset.BNT);

    const assets = supportedAssets.map((asset) => {
      const account = accountByAsset.get(asset);
      const available = account ? toDecimalString(account.available) : '0';
      const pending = account ? toDecimalString(account.pending) : '0';
      const locked = account ? toDecimalString(account.locked) : '0';
      const price = prices[asset];
      const usdValue = new Prisma.Decimal(available)
        .mul(new Prisma.Decimal(price.usdPrice))
        .toString();

      return {
        asset,
        symbol: asset,
        name: this.getAssetLabel(asset),
        network: 'BSC',
        assetKind: this.walletConfigService.getAssetKind(asset),
        available,
        pending,
        locked,
        usdPrice: price.usdPrice,
        usdValue,
        priceSource: price.source,
      };
    });

    const totalUsdValue = assets.reduce((total, item) => {
      return total.add(new Prisma.Decimal(item.usdValue));
    }, DECIMAL_ZERO);

    return {
      wallet: this.toWalletSummary(wallet),
      balances: {
        available: bntAccount ? toDecimalString(bntAccount.available) : '0',
        pending: bntAccount ? toDecimalString(bntAccount.pending) : '0',
        locked: bntAccount ? toDecimalString(bntAccount.locked) : '0',
      },
      assets,
      totals: {
        usdValue: totalUsdValue.toString(),
      },
      kyc: {
        status: kycProfile?.status ?? KycStatus.not_submitted,
        tier: kycProfile?.tier ?? 'basic',
        submittedAt: kycProfile?.submittedAt ?? null,
        reviewedAt: kycProfile?.reviewedAt ?? null,
      },
      features: {
        walletEnabled: this.walletConfigService.walletEnabled,
        userWalletEnabled: wallet.status !== WalletStatus.disabled,
        depositsEnabled: this.walletConfigService.depositsEnabled,
        withdrawalsEnabled: this.walletConfigService.withdrawalsEnabled,
        supportedAssets,
        transferEnabledAssets: this.walletConfigService.withdrawalEnabledAssets,
        withdrawalEnabledAssets:
          this.walletConfigService.withdrawalEnabledAssets,
      },
    };
  }

  async getWalletHealth(userId: string) {
    const wallet =
      await this.walletProvisioningService.ensureWalletForUser(userId);
    const account =
      await this.walletProvisioningService.ensureUserLedgerAccount(
        userId,
        wallet.id,
      );

    const isMainnet = wallet.chainEnvironment === 'mainnet';
    const rpcUrl = isMainnet
      ? this.walletConfigService.bscRpcMainnet
      : this.walletConfigService.bscRpcTestnet;
    const tokenAddress = isMainnet
      ? this.walletConfigService.bntTokenAddressMainnet
      : this.walletConfigService.bntTokenAddressTestnet;
    const treasuryWalletId = isMainnet
      ? this.walletConfigService.treasuryWalletIdMainnet
      : this.walletConfigService.treasuryWalletIdTestnet;
    const treasurySweepAddress = isMainnet
      ? this.walletConfigService.treasurySweepAddressMainnet
      : this.walletConfigService.treasurySweepAddressTestnet;

    return {
      timestamp: new Date().toISOString(),
      flags: {
        walletEnabled: this.walletConfigService.walletEnabled,
        depositsEnabled: this.walletConfigService.depositsEnabled,
        withdrawalsEnabled: this.walletConfigService.withdrawalsEnabled,
        turnkeyMode: this.walletConfigService.turnkeyMode,
        turnkeyExecutionMode: this.walletConfigService.turnkeyExecutionMode,
      },
      wallet: this.toWalletSummary(wallet),
      balances: {
        available: toDecimalString(account.available),
        pending: toDecimalString(account.pending),
        locked: toDecimalString(account.locked),
      },
      network: {
        chainEnvironment: wallet.chainEnvironment,
        chainId: wallet.chainId,
        rpcConfigured: Boolean(rpcUrl),
        tokenAddressConfigured: Boolean(tokenAddress),
        tokenAddress: tokenAddress ?? null,
        treasuryWalletIdConfigured: Boolean(treasuryWalletId),
        treasurySweepAddressConfigured: Boolean(treasurySweepAddress),
      },
    };
  }

  async listWalletTransactions(
    userId: string,
    query: ListWalletTransactionsQuery,
  ) {
    await this.walletProvisioningService.ensureWalletForUser(userId);

    const selectedAsset = query.asset
      ? this.resolveRequestedAsset(query.asset)
      : null;

    const { limit, offset } = normalizePagination(query.offset, query.limit);

    const entries = await this.prisma.ledgerEntry.findMany({
      where: {
        OR: [
          {
            debitAccount: {
              userId,
              accountType: {
                in: [LedgerAccountType.user, LedgerAccountType.hold],
              },
              ...(selectedAsset ? { currency: selectedAsset } : {}),
            },
          },
          {
            creditAccount: {
              userId,
              accountType: {
                in: [LedgerAccountType.user, LedgerAccountType.hold],
              },
              ...(selectedAsset ? { currency: selectedAsset } : {}),
            },
          },
        ],
      },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: limit,
      include: {
        debitAccount: {
          select: {
            userId: true,
            accountType: true,
            currency: true,
            user: {
              select: {
                id: true,
                username: true,
                displayName: true,
              },
            },
            wallet: {
              select: {
                address: true,
              },
            },
          },
        },
        creditAccount: {
          select: {
            userId: true,
            accountType: true,
            currency: true,
            user: {
              select: {
                id: true,
                username: true,
                displayName: true,
              },
            },
            wallet: {
              select: {
                address: true,
              },
            },
          },
        },
      },
    });

    return entries.map((entry) => this.toTransactionResponse(userId, entry));
  }

  async getKycStatus(userId: string) {
    await this.walletProvisioningService.ensureWalletForUser(userId);

    const profile = await this.prisma.kycProfile.findUnique({
      where: { userId },
      select: {
        status: true,
        tier: true,
        submittedAt: true,
        reviewedAt: true,
        reviewNote: true,
      },
    });

    return {
      status: profile?.status ?? KycStatus.not_submitted,
      tier: profile?.tier ?? 'basic',
      submittedAt: profile?.submittedAt ?? null,
      reviewedAt: profile?.reviewedAt ?? null,
      reviewNote: profile?.reviewNote ?? null,
    };
  }

  async listWithdrawals(userId: string, query: ListWithdrawalsQuery) {
    await this.walletProvisioningService.ensureWalletForUser(userId);
    const selectedAsset = query.asset
      ? this.resolveRequestedAsset(query.asset)
      : null;
    const { limit, offset } = normalizePagination(query.offset, query.limit);

    const rows = await this.prisma.withdrawalRequest.findMany({
      where: {
        userId,
        ...(query.status ? { status: query.status } : {}),
        ...(selectedAsset ? { asset: selectedAsset } : {}),
      },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: limit,
    });

    return rows.map((row) => this.toWithdrawalResponse(row));
  }

  private toWalletSummary(wallet: UserWallet) {
    return {
      id: wallet.id,
      status: wallet.status,
      address: wallet.address,
      chainId: wallet.chainId,
      chainEnvironment: wallet.chainEnvironment,
      provider: wallet.provider,
      providerWalletId: wallet.providerWalletId,
      failureReason: wallet.failureReason,
      provisionedAt: wallet.provisionedAt,
    };
  }

  private toTransactionResponse(
    userId: string,
    entry: LedgerEntry & {
      debitAccount: {
        userId: string | null;
        accountType: LedgerAccountType;
        currency: string;
        user: {
          id: string;
          username: string | null;
          displayName: string | null;
        } | null;
        wallet: {
          address: string | null;
        } | null;
      };
      creditAccount: {
        userId: string | null;
        accountType: LedgerAccountType;
        currency: string;
        user: {
          id: string;
          username: string | null;
          displayName: string | null;
        } | null;
        wallet: {
          address: string | null;
        } | null;
      };
    },
  ) {
    const isDebit = entry.debitAccount.userId === userId;
    const isCredit = entry.creditAccount.userId === userId;
    const reason = entry.reason;

    let direction: 'outgoing' | 'incoming' | 'internal';
    if (
      reason === LedgerReason.withdrawal_hold ||
      reason === LedgerReason.withdrawal_finalize ||
      reason === LedgerReason.withdrawal_fee
    ) {
      direction = 'outgoing';
    } else if (reason === LedgerReason.withdrawal_reject_release) {
      direction = 'incoming';
    } else {
      direction =
        isDebit && !isCredit
          ? 'outgoing'
          : !isDebit && isCredit
            ? 'incoming'
            : 'internal';
    }

    const metadata = this.normalizeLedgerMetadata(entry.metadata);

    const asset =
      normalizeWalletAsset(entry.debitAccount.currency) ??
      normalizeWalletAsset(entry.creditAccount.currency) ??
      WalletAsset.BNT;

    const sourceAccount =
      direction === 'incoming'
        ? entry.debitAccount
        : direction === 'outgoing'
          ? entry.creditAccount
          : null;
    const counterparty =
      sourceAccount && sourceAccount.userId && sourceAccount.userId !== userId
        ? {
            userId: sourceAccount.userId,
            username: sourceAccount.user?.username ?? null,
            displayName: sourceAccount.user?.displayName ?? null,
            walletAddress: sourceAccount.wallet?.address ?? null,
          }
        : null;

    return {
      id: entry.id,
      asset,
      direction,
      reason,
      amount: toDecimalString(entry.amount),
      feeAmount: toDecimalString(entry.feeAmount),
      debit: {
        userId: entry.debitAccount.userId,
        accountType: entry.debitAccount.accountType,
      },
      credit: {
        userId: entry.creditAccount.userId,
        accountType: entry.creditAccount.accountType,
      },
      referenceId: entry.referenceId,
      metadata,
      counterparty,
      createdAt: entry.createdAt,
    };
  }

  private normalizeLedgerMetadata(
    input: Prisma.JsonValue | null,
  ): Prisma.JsonObject | null {
    if (!input || typeof input !== 'object' || Array.isArray(input)) {
      return null;
    }
    return input;
  }

  private toWithdrawalResponse(withdrawal: {
    id: string;
    asset: WalletAsset;
    toAddress: string;
    amount: Prisma.Decimal;
    feeAmount: Prisma.Decimal;
    netAmount: Prisma.Decimal;
    status: WithdrawalStatus;
    reason: string;
    rejectReason: string | null;
    broadcastTxHash: string | null;
    requestedAt: Date;
    reviewedAt: Date | null;
    confirmedAt: Date | null;
    failureReason: string | null;
    createdAt: Date;
    updatedAt: Date;
  }) {
    return {
      id: withdrawal.id,
      asset: withdrawal.asset,
      toAddress: withdrawal.toAddress,
      amount: toDecimalString(withdrawal.amount),
      feeAmount: toDecimalString(withdrawal.feeAmount),
      netAmount: toDecimalString(withdrawal.netAmount),
      status: withdrawal.status,
      reason: withdrawal.reason,
      rejectReason: withdrawal.rejectReason,
      broadcastTxHash: withdrawal.broadcastTxHash,
      failureReason: withdrawal.failureReason,
      requestedAt: withdrawal.requestedAt,
      reviewedAt: withdrawal.reviewedAt,
      confirmedAt: withdrawal.confirmedAt,
      createdAt: withdrawal.createdAt,
      updatedAt: withdrawal.updatedAt,
    };
  }

  private getAssetLabel(asset: WalletAsset) {
    switch (asset) {
      case WalletAsset.BNB:
        return 'Binance Coin';
      case WalletAsset.USDT:
        return 'Tether';
      case WalletAsset.BNT:
      default:
        return 'Blocnet';
    }
  }

  private resolveRequestedAsset(rawAsset: WalletAsset | undefined) {
    if (!rawAsset) {
      return WalletAsset.BNT;
    }
    const parsed = normalizeWalletAsset(String(rawAsset));
    if (!parsed || !WALLET_ASSETS.includes(parsed)) {
      throw new BadRequestException('Unsupported wallet asset');
    }
    if (!this.walletConfigService.isAssetEnabled(parsed)) {
      throw new BadRequestException(`${parsed} is not enabled`);
    }
    return parsed;
  }
}
