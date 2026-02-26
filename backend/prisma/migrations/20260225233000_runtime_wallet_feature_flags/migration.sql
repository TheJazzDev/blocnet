ALTER TABLE "WalletRuntimeConfig"
  ADD COLUMN IF NOT EXISTS "depositConfirmations" INTEGER,
  ADD COLUMN IF NOT EXISTS "withdrawalConfirmations" INTEGER;

CREATE TABLE IF NOT EXISTS "RuntimeFeatureConfig" (
  "id" TEXT NOT NULL,
  "alphaRadarEnabled" BOOLEAN NOT NULL DEFAULT true,
  "followPrefsEnabled" BOOLEAN NOT NULL DEFAULT true,
  "weeklyDigestEnabled" BOOLEAN NOT NULL DEFAULT true,
  "miningEnabled" BOOLEAN NOT NULL DEFAULT true,
  "referralsEnabled" BOOLEAN NOT NULL DEFAULT true,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "RuntimeFeatureConfig_pkey" PRIMARY KEY ("id")
);
