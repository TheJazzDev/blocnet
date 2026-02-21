DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'MiningPointSource') THEN
    CREATE TYPE "MiningPointSource" AS ENUM ('cycle_claim', 'admin_adjustment');
  END IF;
END
$$;

ALTER TABLE "Profile"
  ADD COLUMN IF NOT EXISTS "referralCode" TEXT,
  ADD COLUMN IF NOT EXISTS "referredById" UUID,
  ADD COLUMN IF NOT EXISTS "referredAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "miningClaimedPoints" BIGINT NOT NULL DEFAULT 0;

CREATE UNIQUE INDEX IF NOT EXISTS "Profile_referralCode_key"
ON "Profile"("referralCode");

CREATE INDEX IF NOT EXISTS "Profile_referredById_idx"
ON "Profile"("referredById");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'Profile_referredById_fkey'
  ) THEN
    ALTER TABLE "Profile"
      ADD CONSTRAINT "Profile_referredById_fkey"
      FOREIGN KEY ("referredById")
      REFERENCES "Profile"("id")
      ON DELETE SET NULL
      ON UPDATE CASCADE;
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS "MiningSession" (
  "id" UUID NOT NULL,
  "userId" UUID NOT NULL,
  "startsAt" TIMESTAMP(3) NOT NULL,
  "endsAt" TIMESTAMP(3) NOT NULL,
  "claimedAt" TIMESTAMP(3),
  "basePointsPerCycle" INTEGER NOT NULL,
  "activeReferralsSnapshot" INTEGER NOT NULL,
  "boostBpsSnapshot" INTEGER NOT NULL,
  "effectivePointsPerCycle" INTEGER NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "MiningSession_pkey" PRIMARY KEY ("id")
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'MiningSession_userId_fkey'
  ) THEN
    ALTER TABLE "MiningSession"
      ADD CONSTRAINT "MiningSession_userId_fkey"
      FOREIGN KEY ("userId")
      REFERENCES "Profile"("id")
      ON DELETE CASCADE
      ON UPDATE CASCADE;
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS "MiningSession_userId_createdAt_idx"
ON "MiningSession"("userId", "createdAt");

CREATE INDEX IF NOT EXISTS "MiningSession_userId_claimedAt_idx"
ON "MiningSession"("userId", "claimedAt");

CREATE TABLE IF NOT EXISTS "MiningPointLedger" (
  "id" UUID NOT NULL,
  "userId" UUID NOT NULL,
  "sessionId" UUID,
  "source" "MiningPointSource" NOT NULL,
  "points" INTEGER NOT NULL,
  "metadata" JSONB,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "MiningPointLedger_pkey" PRIMARY KEY ("id")
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'MiningPointLedger_userId_fkey'
  ) THEN
    ALTER TABLE "MiningPointLedger"
      ADD CONSTRAINT "MiningPointLedger_userId_fkey"
      FOREIGN KEY ("userId")
      REFERENCES "Profile"("id")
      ON DELETE CASCADE
      ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'MiningPointLedger_sessionId_fkey'
  ) THEN
    ALTER TABLE "MiningPointLedger"
      ADD CONSTRAINT "MiningPointLedger_sessionId_fkey"
      FOREIGN KEY ("sessionId")
      REFERENCES "MiningSession"("id")
      ON DELETE SET NULL
      ON UPDATE CASCADE;
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS "MiningPointLedger_userId_createdAt_idx"
ON "MiningPointLedger"("userId", "createdAt");

CREATE TABLE IF NOT EXISTS "MiningConfig" (
  "id" TEXT NOT NULL,
  "enabled" BOOLEAN NOT NULL DEFAULT true,
  "referralsEnabled" BOOLEAN NOT NULL DEFAULT true,
  "cycleHours" INTEGER NOT NULL DEFAULT 24,
  "basePointsPerCycle" INTEGER NOT NULL DEFAULT 120,
  "perActiveReferralBoostBps" INTEGER NOT NULL DEFAULT 500,
  "maxBoostBps" INTEGER NOT NULL DEFAULT 10000,
  "activeReferralWindowHours" INTEGER NOT NULL DEFAULT 168,
  "referralBindWindowHours" INTEGER NOT NULL DEFAULT 24,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "MiningConfig_pkey" PRIMARY KEY ("id")
);

INSERT INTO "MiningConfig" (
  "id",
  "enabled",
  "referralsEnabled",
  "cycleHours",
  "basePointsPerCycle",
  "perActiveReferralBoostBps",
  "maxBoostBps",
  "activeReferralWindowHours",
  "referralBindWindowHours",
  "updatedAt"
)
VALUES ('default', true, true, 24, 120, 500, 10000, 168, 24, NOW())
ON CONFLICT ("id") DO NOTHING;
