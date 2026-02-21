CREATE TABLE IF NOT EXISTS "MiningHourlyCheckpoint" (
  "id" UUID NOT NULL,
  "userId" UUID NOT NULL,
  "sessionId" UUID NOT NULL,
  "hourIndex" INTEGER NOT NULL,
  "hourStartAt" TIMESTAMP(3) NOT NULL,
  "hourEndAt" TIMESTAMP(3) NOT NULL,
  "activeReferralsSnapshot" INTEGER NOT NULL,
  "boostBpsSnapshot" INTEGER NOT NULL,
  "points" INTEGER NOT NULL,
  "claimedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "MiningHourlyCheckpoint_pkey" PRIMARY KEY ("id")
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'MiningHourlyCheckpoint_userId_fkey'
  ) THEN
    ALTER TABLE "MiningHourlyCheckpoint"
      ADD CONSTRAINT "MiningHourlyCheckpoint_userId_fkey"
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
    WHERE conname = 'MiningHourlyCheckpoint_sessionId_fkey'
  ) THEN
    ALTER TABLE "MiningHourlyCheckpoint"
      ADD CONSTRAINT "MiningHourlyCheckpoint_sessionId_fkey"
      FOREIGN KEY ("sessionId")
      REFERENCES "MiningSession"("id")
      ON DELETE CASCADE
      ON UPDATE CASCADE;
  END IF;
END
$$;

CREATE UNIQUE INDEX IF NOT EXISTS "MiningHourlyCheckpoint_sessionId_hourIndex_key"
ON "MiningHourlyCheckpoint"("sessionId", "hourIndex");

CREATE INDEX IF NOT EXISTS "MiningHourlyCheckpoint_userId_hourEndAt_idx"
ON "MiningHourlyCheckpoint"("userId", "hourEndAt");

CREATE INDEX IF NOT EXISTS "MiningHourlyCheckpoint_sessionId_claimedAt_idx"
ON "MiningHourlyCheckpoint"("sessionId", "claimedAt");

CREATE INDEX IF NOT EXISTS "MiningSession_userId_startsAt_idx"
ON "MiningSession"("userId", "startsAt");
