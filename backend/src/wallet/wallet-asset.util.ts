import { WalletAsset } from '@prisma/client';

export const WALLET_ASSETS: WalletAsset[] = [
  WalletAsset.BNT,
  WalletAsset.BNB,
  WalletAsset.USDT,
];

export function normalizeWalletAsset(
  value: string | null | undefined,
): WalletAsset | null {
  if (!value) return null;
  const normalized = value.trim().toUpperCase();
  if (normalized === WalletAsset.BNT) return WalletAsset.BNT;
  if (normalized === WalletAsset.BNB) return WalletAsset.BNB;
  if (normalized === WalletAsset.USDT) return WalletAsset.USDT;
  return null;
}

export function getWithdrawalFeeKeyForAsset(asset: WalletAsset): string {
  switch (asset) {
    case WalletAsset.BNB:
      return 'withdrawal_bnb_v1';
    case WalletAsset.USDT:
      return 'withdrawal_usdt_v1';
    case WalletAsset.BNT:
    default:
      return 'withdrawal_bnt_v1';
  }
}

export function getDefaultPriceProviderId(asset: WalletAsset): string {
  switch (asset) {
    case WalletAsset.BNB:
      return 'binancecoin';
    case WalletAsset.USDT:
      return 'tether';
    case WalletAsset.BNT:
    default:
      return 'blocnet';
  }
}
