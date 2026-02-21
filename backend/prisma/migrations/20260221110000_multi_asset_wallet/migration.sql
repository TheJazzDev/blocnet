DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'WalletAsset') THEN
    CREATE TYPE "WalletAsset" AS ENUM ('BNT', 'BNB', 'USDT');
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'WalletAssetKind') THEN
    CREATE TYPE "WalletAssetKind" AS ENUM ('erc20', 'native');
  END IF;
END
$$;

ALTER TABLE "OnchainDeposit"
  ADD COLUMN IF NOT EXISTS "asset" "WalletAsset" NOT NULL DEFAULT 'BNT',
  ADD COLUMN IF NOT EXISTS "assetKind" "WalletAssetKind" NOT NULL DEFAULT 'erc20',
  ADD COLUMN IF NOT EXISTS "tokenAddress" TEXT;

ALTER TABLE "SweepJob"
  ADD COLUMN IF NOT EXISTS "asset" "WalletAsset" NOT NULL DEFAULT 'BNT',
  ADD COLUMN IF NOT EXISTS "assetKind" "WalletAssetKind" NOT NULL DEFAULT 'erc20',
  ADD COLUMN IF NOT EXISTS "tokenAddress" TEXT;

ALTER TABLE "WithdrawalRequest"
  ADD COLUMN IF NOT EXISTS "asset" "WalletAsset" NOT NULL DEFAULT 'BNT';

CREATE TABLE IF NOT EXISTS "WalletAssetPriceConfig" (
  "id" UUID NOT NULL,
  "asset" "WalletAsset" NOT NULL,
  "providerId" TEXT,
  "fallbackUsdPrice" DECIMAL(28,12) NOT NULL DEFAULT 0,
  "isActive" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "WalletAssetPriceConfig_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "WalletAssetPriceConfig_asset_key"
ON "WalletAssetPriceConfig"("asset");

DROP INDEX IF EXISTS "OnchainDeposit_txHash_logIndex_key";
CREATE UNIQUE INDEX IF NOT EXISTS "OnchainDeposit_txHash_logIndex_asset_key"
ON "OnchainDeposit"("txHash", "logIndex", "asset");

CREATE INDEX IF NOT EXISTS "OnchainDeposit_asset_status_createdAt_idx"
ON "OnchainDeposit"("asset", "status", "createdAt");

CREATE INDEX IF NOT EXISTS "OnchainDeposit_walletId_asset_status_createdAt_idx"
ON "OnchainDeposit"("walletId", "asset", "status", "createdAt");

CREATE INDEX IF NOT EXISTS "SweepJob_asset_status_createdAt_idx"
ON "SweepJob"("asset", "status", "createdAt");

CREATE INDEX IF NOT EXISTS "SweepJob_walletId_asset_status_createdAt_idx"
ON "SweepJob"("walletId", "asset", "status", "createdAt");

CREATE INDEX IF NOT EXISTS "WithdrawalRequest_asset_status_createdAt_idx"
ON "WithdrawalRequest"("asset", "status", "createdAt");

CREATE INDEX IF NOT EXISTS "WithdrawalRequest_userId_asset_createdAt_idx"
ON "WithdrawalRequest"("userId", "asset", "createdAt");

CREATE INDEX IF NOT EXISTS "WithdrawalRequest_walletId_asset_status_createdAt_idx"
ON "WithdrawalRequest"("walletId", "asset", "status", "createdAt");
