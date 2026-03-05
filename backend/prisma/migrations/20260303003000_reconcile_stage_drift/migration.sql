-- Reconcile stage drift without destructive reset.
-- This migration is idempotent and safe on databases where parts already exist.

DO $$
BEGIN
  IF to_regclass('"AdminTotpRecoveryCode"') IS NOT NULL THEN
    ALTER TABLE "AdminTotpRecoveryCode"
      ALTER COLUMN "id" SET DEFAULT gen_random_uuid();
  END IF;

  IF to_regclass('"AdminTwoFactorSession"') IS NOT NULL THEN
    ALTER TABLE "AdminTwoFactorSession"
      ALTER COLUMN "id" SET DEFAULT gen_random_uuid();
  END IF;

  IF to_regclass('"SocialCredential"') IS NOT NULL THEN
    ALTER TABLE "SocialCredential"
      ALTER COLUMN "id" SET DEFAULT gen_random_uuid();
  END IF;
END
$$;

ALTER TABLE "EdgeDecision"
  ADD COLUMN IF NOT EXISTS "mlQuality" DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS "mlSentiment" TEXT,
  ADD COLUMN IF NOT EXISTS "mlTopics" JSONB,
  ADD COLUMN IF NOT EXISTS "mlActionability" DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS "mlInsights" JSONB,
  ADD COLUMN IF NOT EXISTS "mlProvider" TEXT;

CREATE TABLE IF NOT EXISTS "EdgeEngagement" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "userId" UUID NOT NULL,
  "decisionRecordId" UUID,
  "decisionId" TEXT NOT NULL,
  "updateId" UUID NOT NULL,
  "action" "EdgeAction",
  "clicked" BOOLEAN NOT NULL DEFAULT false,
  "viewDurationMs" INTEGER,
  "scrollDepth" DOUBLE PRECISION,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "EdgeEngagement_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "EdgeEngagement_userId_createdAt_idx"
  ON "EdgeEngagement"("userId", "createdAt");
CREATE INDEX IF NOT EXISTS "EdgeEngagement_updateId_createdAt_idx"
  ON "EdgeEngagement"("updateId", "createdAt");
CREATE INDEX IF NOT EXISTS "EdgeEngagement_decisionRecordId_createdAt_idx"
  ON "EdgeEngagement"("decisionRecordId", "createdAt");
CREATE INDEX IF NOT EXISTS "EdgeEngagement_decisionId_createdAt_idx"
  ON "EdgeEngagement"("decisionId", "createdAt");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'EdgeEngagement_userId_fkey'
  ) THEN
    ALTER TABLE "EdgeEngagement"
      ADD CONSTRAINT "EdgeEngagement_userId_fkey"
      FOREIGN KEY ("userId") REFERENCES "Profile"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'EdgeEngagement_updateId_fkey'
  ) THEN
    ALTER TABLE "EdgeEngagement"
      ADD CONSTRAINT "EdgeEngagement_updateId_fkey"
      FOREIGN KEY ("updateId") REFERENCES "Update"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'EdgeEngagement_decisionRecordId_fkey'
  ) THEN
    ALTER TABLE "EdgeEngagement"
      ADD CONSTRAINT "EdgeEngagement_decisionRecordId_fkey"
      FOREIGN KEY ("decisionRecordId") REFERENCES "EdgeDecision"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END
$$;
