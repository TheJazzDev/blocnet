-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "NotificationType" ADD VALUE 'mining_cycle_ready';
ALTER TYPE "NotificationType" ADD VALUE 'mining_claim_expiring';

-- CreateIndex
CREATE INDEX "MiningSession_endsAt_idx" ON "MiningSession"("endsAt");

-- CreateIndex
CREATE INDEX "Profile_miningClaimedPoints_idx" ON "Profile"("miningClaimedPoints");
