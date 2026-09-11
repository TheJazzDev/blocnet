-- AlterTable
ALTER TABLE "MiningHourlyCheckpoint" ADD COLUMN     "expiredAt" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "MiningSession" ADD COLUMN     "expiredAt" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX "MiningHourlyCheckpoint_sessionId_expiredAt_idx" ON "MiningHourlyCheckpoint"("sessionId", "expiredAt");

-- CreateIndex
CREATE INDEX "MiningSession_userId_expiredAt_idx" ON "MiningSession"("userId", "expiredAt");
