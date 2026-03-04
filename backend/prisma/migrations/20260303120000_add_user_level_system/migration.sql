-- AlterEnum
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'level_up';

-- CreateTable
CREATE TABLE "UserLevel" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "iconUrl" TEXT NOT NULL,
    "level" INTEGER NOT NULL,
    "requiredBnp" BIGINT NOT NULL DEFAULT 0,
    "requiredComments" INTEGER NOT NULL DEFAULT 0,
    "requiredDaysActive" INTEGER NOT NULL DEFAULT 0,
    "requiredQuests" INTEGER NOT NULL DEFAULT 0,
    "requiredUpdates" INTEGER NOT NULL DEFAULT 0,
    "requiredProjects" INTEGER NOT NULL DEFAULT 0,
    "color" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "UserLevel_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserLevelProgress" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "userId" UUID NOT NULL,
    "currentLevelId" UUID NOT NULL,
    "achievedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "totalBnpEarned" BIGINT NOT NULL DEFAULT 0,
    "totalComments" INTEGER NOT NULL DEFAULT 0,
    "totalDaysActive" INTEGER NOT NULL DEFAULT 0,
    "totalQuestsCompleted" INTEGER NOT NULL DEFAULT 0,
    "totalUpdates" INTEGER NOT NULL DEFAULT 0,
    "totalProjects" INTEGER NOT NULL DEFAULT 0,
    "lastRecalculatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "UserLevelProgress_pkey" PRIMARY KEY ("id")
);

-- AlterTable
ALTER TABLE "Profile" ADD COLUMN IF NOT EXISTS "currentLevelId" UUID;

-- CreateIndex
CREATE UNIQUE INDEX "UserLevel_slug_key" ON "UserLevel"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "UserLevel_level_key" ON "UserLevel"("level");

-- CreateIndex
CREATE INDEX "UserLevel_level_isActive_idx" ON "UserLevel"("level", "isActive");

-- CreateIndex
CREATE INDEX "UserLevel_requiredBnp_idx" ON "UserLevel"("requiredBnp");

-- CreateIndex
CREATE INDEX "UserLevel_sortOrder_idx" ON "UserLevel"("sortOrder");

-- CreateIndex
CREATE UNIQUE INDEX "UserLevelProgress_userId_key" ON "UserLevelProgress"("userId");

-- CreateIndex
CREATE INDEX "UserLevelProgress_currentLevelId_achievedAt_idx" ON "UserLevelProgress"("currentLevelId", "achievedAt");

-- CreateIndex
CREATE INDEX "UserLevelProgress_totalBnpEarned_idx" ON "UserLevelProgress"("totalBnpEarned");

-- CreateIndex
CREATE INDEX "UserLevelProgress_userId_lastRecalculatedAt_idx" ON "UserLevelProgress"("userId", "lastRecalculatedAt");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "Profile_currentLevelId_idx" ON "Profile"("currentLevelId");

-- AddForeignKey
ALTER TABLE "Profile" ADD CONSTRAINT "Profile_currentLevelId_fkey" FOREIGN KEY ("currentLevelId") REFERENCES "UserLevel"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserLevelProgress" ADD CONSTRAINT "UserLevelProgress_userId_fkey" FOREIGN KEY ("userId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserLevelProgress" ADD CONSTRAINT "UserLevelProgress_currentLevelId_fkey" FOREIGN KEY ("currentLevelId") REFERENCES "UserLevel"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
