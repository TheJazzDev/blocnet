CREATE TABLE IF NOT EXISTS "WalletRuntimeConfig" (
  "id" TEXT NOT NULL,
  "walletEnabled" BOOLEAN NOT NULL DEFAULT false,
  "depositsEnabled" BOOLEAN NOT NULL DEFAULT false,
  "withdrawalsEnabled" BOOLEAN NOT NULL DEFAULT false,
  "depositRealtimeEnabled" BOOLEAN NOT NULL DEFAULT true,
  "walletAssetBntEnabled" BOOLEAN NOT NULL DEFAULT true,
  "walletAssetBnbEnabled" BOOLEAN NOT NULL DEFAULT true,
  "walletAssetUsdtEnabled" BOOLEAN NOT NULL DEFAULT true,
  "withdrawalAssetsCsv" TEXT NOT NULL DEFAULT 'BNT',
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "WalletRuntimeConfig_pkey" PRIMARY KEY ("id")
);
