import type {
  AdminWalletDepositReprocessResponse,
  WalletAssetPriceConfig,
  WalletFeeConfig,
  WalletRiskLimit,
  WalletRuntimeConfig,
} from '@/lib/api-client';

export type RiskDraft = {
  description: string;
  requiresKyc: boolean;
  maxWithdrawalPerTx: string;
  maxWithdrawalPerDay: string;
  maxInternalTransferPerDay: string;
};

export type FeeDraft = {
  flatFee: string;
  percentFee: string;
  minFee: string;
  maxFee: string;
  isActive: boolean;
};

export type AssetPriceDraft = {
  providerId: string;
  fallbackUsdPrice: string;
  isActive: boolean;
};

export function buildRiskDrafts(
  riskLimits: WalletRiskLimit[],
): Record<string, RiskDraft> {
  const drafts: Record<string, RiskDraft> = {};
  for (const row of riskLimits) {
    drafts[row.tier] = {
      description: row.description ?? '',
      requiresKyc: row.requiresKyc,
      maxWithdrawalPerTx: row.maxWithdrawalPerTx,
      maxWithdrawalPerDay: row.maxWithdrawalPerDay,
      maxInternalTransferPerDay: row.maxInternalTransferPerDay,
    };
  }
  return drafts;
}

export function buildFeeDrafts(
  feeConfigs: WalletFeeConfig[],
): Record<string, FeeDraft> {
  const drafts: Record<string, FeeDraft> = {};
  for (const row of feeConfigs) {
    drafts[row.key] = {
      flatFee: row.flatFee,
      percentFee: row.percentFee,
      minFee: row.minFee,
      maxFee: row.maxFee ?? '',
      isActive: row.isActive,
    };
  }
  return drafts;
}

export function buildAssetPriceDrafts(
  priceConfigs: WalletAssetPriceConfig[],
): Record<string, AssetPriceDraft> {
  const drafts: Record<string, AssetPriceDraft> = {};
  for (const row of priceConfigs) {
    drafts[row.asset] = {
      providerId: row.providerId ?? '',
      fallbackUsdPrice: row.fallbackUsdPrice,
      isActive: row.isActive,
    };
  }
  return drafts;
}

export function toRuntimeConfigPayload(runtimeConfig: WalletRuntimeConfig) {
  return {
    walletEnabled: runtimeConfig.walletEnabled,
    depositsEnabled: runtimeConfig.depositsEnabled,
    withdrawalsEnabled: runtimeConfig.withdrawalsEnabled,
    depositRealtimeEnabled: runtimeConfig.depositRealtimeEnabled,
    bscRpcUrl: runtimeConfig.bscRpcUrl?.trim() ? runtimeConfig.bscRpcUrl.trim() : null,
    bscRpcWsUrl: runtimeConfig.bscRpcWsUrl?.trim()
      ? runtimeConfig.bscRpcWsUrl.trim()
      : null,
    depositConfirmations: runtimeConfig.depositConfirmations,
    withdrawalConfirmations: runtimeConfig.withdrawalConfirmations,
    walletAssetBntEnabled: runtimeConfig.walletAssetBntEnabled,
    walletAssetBnbEnabled: runtimeConfig.walletAssetBnbEnabled,
    walletAssetUsdtEnabled: runtimeConfig.walletAssetUsdtEnabled,
    withdrawalEnabledAssets: runtimeConfig.withdrawalEnabledAssets,
  };
}

export function formatManualReprocessStatus(
  result: AdminWalletDepositReprocessResponse,
) {
  return `Reprocess complete. Matched assets: ${result.summary.matchedAssets}. Credited deposits: ${result.summary.creditedDeposits}.`;
}
