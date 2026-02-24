-- CreateEnum
CREATE TYPE "BadgeCategory" AS ENUM ('engagement', 'mining', 'social', 'trust', 'special');

-- CreateEnum
CREATE TYPE "BadgeRarity" AS ENUM ('common', 'rare', 'epic', 'legendary');

-- CreateEnum
CREATE TYPE "QuestType" AS ENUM ('external_link', 'internal_action', 'social_media');

-- CreateEnum
CREATE TYPE "QuestStatus" AS ENUM ('not_started', 'in_progress', 'pending_verification', 'completed');

-- CreateEnum
CREATE TYPE "QuestVerificationStatus" AS ENUM ('pending', 'approved', 'rejected');

-- AlterEnum
ALTER TYPE "MiningPointSource" ADD VALUE 'quest_reward';

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "NotificationType" ADD VALUE 'badge_earned';
ALTER TYPE "NotificationType" ADD VALUE 'quest_completed';
ALTER TYPE "NotificationType" ADD VALUE 'quest_verified';
ALTER TYPE "NotificationType" ADD VALUE 'quest_rejected';

-- AlterTable
ALTER TABLE "Profile" ADD COLUMN     "primaryBadgeId" UUID;

-- CreateTable
CREATE TABLE "Badge" (
    "id" UUID NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "imageUrl" TEXT NOT NULL,
    "category" "BadgeCategory" NOT NULL,
    "rarity" "BadgeRarity" NOT NULL,
    "pointsRequirement" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Badge_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserBadge" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "badgeId" UUID NOT NULL,
    "earnedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "grantedBy" UUID,
    "metadata" JSONB,

    CONSTRAINT "UserBadge_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Quest" (
    "id" UUID NOT NULL,
    "slug" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "type" "QuestType" NOT NULL,
    "category" "BadgeCategory" NOT NULL,
    "rewardPoints" INTEGER NOT NULL DEFAULT 0,
    "rewardBadgeId" UUID,
    "targetUrl" TEXT,
    "targetAction" TEXT,
    "verificationMethod" TEXT NOT NULL DEFAULT 'manual',
    "requiredProof" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "expiresAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Quest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserQuest" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "questId" UUID NOT NULL,
    "status" "QuestStatus" NOT NULL DEFAULT 'not_started',
    "progress" INTEGER NOT NULL DEFAULT 0,
    "startedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "UserQuest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "QuestSubmission" (
    "id" UUID NOT NULL,
    "userQuestId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "proofUrl" TEXT,
    "proofText" TEXT,
    "screenshot" TEXT,
    "verificationStatus" "QuestVerificationStatus" NOT NULL DEFAULT 'pending',
    "verifiedBy" UUID,
    "verifiedAt" TIMESTAMP(3),
    "rejectionReason" TEXT,
    "submittedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "QuestSubmission_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Badge_slug_key" ON "Badge"("slug");

-- CreateIndex
CREATE INDEX "Badge_category_sortOrder_idx" ON "Badge"("category", "sortOrder");

-- CreateIndex
CREATE INDEX "Badge_rarity_isActive_idx" ON "Badge"("rarity", "isActive");

-- CreateIndex
CREATE INDEX "UserBadge_userId_earnedAt_idx" ON "UserBadge"("userId", "earnedAt");

-- CreateIndex
CREATE INDEX "UserBadge_badgeId_earnedAt_idx" ON "UserBadge"("badgeId", "earnedAt");

-- CreateIndex
CREATE UNIQUE INDEX "UserBadge_userId_badgeId_key" ON "UserBadge"("userId", "badgeId");

-- CreateIndex
CREATE UNIQUE INDEX "Quest_slug_key" ON "Quest"("slug");

-- CreateIndex
CREATE INDEX "Quest_isActive_sortOrder_idx" ON "Quest"("isActive", "sortOrder");

-- CreateIndex
CREATE INDEX "Quest_category_isActive_idx" ON "Quest"("category", "isActive");

-- CreateIndex
CREATE INDEX "Quest_expiresAt_idx" ON "Quest"("expiresAt");

-- CreateIndex
CREATE INDEX "UserQuest_userId_status_idx" ON "UserQuest"("userId", "status");

-- CreateIndex
CREATE INDEX "UserQuest_questId_status_idx" ON "UserQuest"("questId", "status");

-- CreateIndex
CREATE INDEX "UserQuest_status_completedAt_idx" ON "UserQuest"("status", "completedAt");

-- CreateIndex
CREATE UNIQUE INDEX "UserQuest_userId_questId_key" ON "UserQuest"("userId", "questId");

-- CreateIndex
CREATE INDEX "QuestSubmission_userId_verificationStatus_idx" ON "QuestSubmission"("userId", "verificationStatus");

-- CreateIndex
CREATE INDEX "QuestSubmission_userQuestId_submittedAt_idx" ON "QuestSubmission"("userQuestId", "submittedAt");

-- CreateIndex
CREATE INDEX "QuestSubmission_verificationStatus_submittedAt_idx" ON "QuestSubmission"("verificationStatus", "submittedAt");

-- CreateIndex
CREATE INDEX "Profile_primaryBadgeId_idx" ON "Profile"("primaryBadgeId");

-- AddForeignKey
ALTER TABLE "Profile" ADD CONSTRAINT "Profile_primaryBadgeId_fkey" FOREIGN KEY ("primaryBadgeId") REFERENCES "Badge"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserBadge" ADD CONSTRAINT "UserBadge_userId_fkey" FOREIGN KEY ("userId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserBadge" ADD CONSTRAINT "UserBadge_badgeId_fkey" FOREIGN KEY ("badgeId") REFERENCES "Badge"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserBadge" ADD CONSTRAINT "UserBadge_grantedBy_fkey" FOREIGN KEY ("grantedBy") REFERENCES "Profile"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserQuest" ADD CONSTRAINT "UserQuest_userId_fkey" FOREIGN KEY ("userId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserQuest" ADD CONSTRAINT "UserQuest_questId_fkey" FOREIGN KEY ("questId") REFERENCES "Quest"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "QuestSubmission" ADD CONSTRAINT "QuestSubmission_userQuestId_fkey" FOREIGN KEY ("userQuestId") REFERENCES "UserQuest"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "QuestSubmission" ADD CONSTRAINT "QuestSubmission_userId_fkey" FOREIGN KEY ("userId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
