import { BadRequestException, Injectable } from '@nestjs/common';
import {
  KycStatus,
  LedgerAccountType,
  Prisma,
  WalletAsset,
  WalletStatus,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { normalizePagination } from '../common/utils/pagination.util';
import { ListWalletTransactionsQuery } from './dto/list-wallet-transactions.query';
import { ListWithdrawalsQuery } from './dto/list-withdrawals.query';
import { DECIMAL_ZERO, toDecimalString } from './types/decimal';
import { normalizeWalletAsset, WALLET_ASSETS } from './wallet-asset.util';
import { WalletAssetPricingService } from './wallet-asset-pricing.service';
import { WalletConfigService } from './wallet-config.service';
import { WalletPointsService, POINTS_ASSET } from './wallet-points.service';
import { WalletProvisioningService } from './wallet-provisioning.service';
import {
  getAssetLabel,
  toTransactionResponse,
  toWalletSummary,
  toWithdrawalResponse,
} from './wallet-query.mappers';

@Injectable()
export class WalletQueryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly walletConfigService: WalletConfigService,
    private readonly walletProvisioningService: WalletProvisioningService,
    private readonly walletAssetPricingService: WalletAssetPricingService,
    private readonly walletPointsService: WalletPointsService,
  ) {}

  async getWalletSummary(userId: string) {
    const wallet =
      await this.walletProvisioningService.ensureWalletForUser(userId);

    const supportedAssets = this.walletConfigService.supportedAssets;
    const [kycProfile, prices, pointsAsset] = await Promise.all([
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
      // Off-chain BNP: present whatever the on-chain wallet status is.
      this.walletPointsService.getPointsAsset(userId),
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
    const hideUsdPricing = wallet.chainEnvironment === 'testnet';

    const onchainAssets = supportedAssets.map((asset) => {
      const account = accountByAsset.get(asset);
      const available = account ? toDecimalString(account.available) : '0';
      const pending = account ? toDecimalString(account.pending) : '0';
      const locked = account ? toDecimalString(account.locked) : '0';
      const price = prices[asset];
      const effectiveUsdPrice = hideUsdPricing ? '0' : price.usdPrice;
      const effectivePriceSource = hideUsdPricing ? 'fallback' : price.source;
      const usdValue = new Prisma.Decimal(available)
        .mul(new Prisma.Decimal(effectiveUsdPrice))
        .toString();

      return {
        asset,
        symbol: asset,
        name: getAssetLabel(asset),
        network: 'BSC',
        assetKind: this.walletConfigService.getAssetKind(asset),
        available,
        pending,
        locked,
        usdPrice: effectiveUsdPrice,
        usdValue,
        priceSource: effectivePriceSource,
      };
    });

    // BNP leads: it is the balance every member holds today. It has no USD
    // price, so it adds nothing to the total.
    const assets = [pointsAsset, ...onchainAssets];

    const totalUsdValue = onchainAssets.reduce((total, item) => {
      return total.add(new Prisma.Decimal(item.usdValue));
    }, DECIMAL_ZERO);

    return {
      wallet: toWalletSummary(wallet),
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

  /**
   * User-facing wallet health.
   *
   * Deliberately narrow: this route is reachable by any signed-in user, so it
   * reports only what a wallet screen needs — whether the feature and its
   * deposit/withdrawal legs are on, the caller's own wallet and balances, and
   * the public chain coordinates. Operational posture (Turnkey mode, RPC
   * reachability, treasury provisioning, custody provider ids and failure
   * strings) stays on the admin-only `/admin/wallet/health`.
   */
  async getWalletHealth(userId: string) {
    const wallet =
      await this.walletProvisioningService.ensureWalletForUser(userId);
    const account =
      await this.walletProvisioningService.ensureUserLedgerAccount(
        userId,
        wallet.id,
      );

    const isMainnet = wallet.chainEnvironment === 'mainnet';
    // Public on-chain contract address — safe to expose so a client can show
    // or add the token; everything else derived from config is not.
    const tokenAddress = isMainnet
      ? this.walletConfigService.bntTokenAddressMainnet
      : this.walletConfigService.bntTokenAddressTestnet;

    return {
      timestamp: new Date().toISOString(),
      flags: {
        walletEnabled: this.walletConfigService.walletEnabled,
        userWalletEnabled: wallet.status !== WalletStatus.disabled,
        depositsEnabled: this.walletConfigService.depositsEnabled,
        withdrawalsEnabled: this.walletConfigService.withdrawalsEnabled,
      },
      wallet: {
        id: wallet.id,
        status: wallet.status,
        address: wallet.address,
        chainId: wallet.chainId,
        chainEnvironment: wallet.chainEnvironment,
        provisionedAt: wallet.provisionedAt,
      },
      balances: {
        available: toDecimalString(account.available),
        pending: toDecimalString(account.pending),
        locked: toDecimalString(account.locked),
      },
      network: {
        chainEnvironment: wallet.chainEnvironment,
        chainId: wallet.chainId,
        tokenAddress: tokenAddress ?? null,
      },
    };
  }

  async listWalletTransactions(
    userId: string,
    query: ListWalletTransactionsQuery,
  ) {
    await this.walletProvisioningService.ensureWalletForUser(userId);
    const { limit, offset } = normalizePagination(query.offset, query.limit);

    if (query.asset === POINTS_ASSET) {
      return this.walletPointsService.listPointsTransactions(userId, {
        skip: offset,
        take: limit,
      });
    }

    const selectedAsset = query.asset
      ? this.resolveRequestedAsset(query.asset)
      : null;

    if (selectedAsset) {
      return this.listLedgerTransactions(userId, selectedAsset, {
        skip: offset,
        take: limit,
      });
    }

    // All assets: page through the merged on-chain + BNP timeline. Both
    // sources are read in parallel up to the end of the requested page, then
    // merged newest-first and sliced.
    const window = { skip: 0, take: offset + limit };
    const [ledgerRows, pointsRows] = await Promise.all([
      this.listLedgerTransactions(userId, null, window),
      this.walletPointsService.listPointsTransactions(userId, window),
    ]);
    return [...ledgerRows, ...pointsRows]
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
      .slice(offset, offset + limit);
  }

  private async listLedgerTransactions(
    userId: string,
    selectedAsset: WalletAsset | null,
    page: { skip: number; take: number },
  ) {
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
      skip: page.skip,
      take: page.take,
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

    return entries.map((entry) => toTransactionResponse(userId, entry));
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

    return rows.map((row) => toWithdrawalResponse(row));
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
