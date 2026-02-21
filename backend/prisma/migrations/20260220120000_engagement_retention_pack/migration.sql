-- AlterTable
ALTER TABLE "Profile"
ADD COLUMN "homeFeedLastSeenAt" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "ProjectFollow"
ADD COLUMN "alertMinUrgency" "UpdateUrgency" NOT NULL DEFAULT 'low',
ADD COLUMN "mutedUntil" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX "ProjectFollow_projectId_alertMinUrgency_idx"
ON "ProjectFollow"("projectId", "alertMinUrgency");

-- CreateIndex
CREATE INDEX "ProjectFollow_projectId_mutedUntil_idx"
ON "ProjectFollow"("projectId", "mutedUntil");
