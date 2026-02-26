-- AlterEnum
ALTER TYPE "NotificationType" ADD VALUE 'mention_received';

-- AlterTable
ALTER TABLE "UserNotificationCategoryPreference" ALTER COLUMN "id" DROP DEFAULT,
ALTER COLUMN "updatedAt" DROP DEFAULT;

-- AlterTable
ALTER TABLE "UserNotificationSettings" ALTER COLUMN "updatedAt" DROP DEFAULT;

-- AlterTable
ALTER TABLE "UserNotificationTypeOverride" ALTER COLUMN "id" DROP DEFAULT,
ALTER COLUMN "updatedAt" DROP DEFAULT;

-- CreateTable
CREATE TABLE "Mention" (
    "id" UUID NOT NULL,
    "mentionedUserId" UUID NOT NULL,
    "commentId" UUID,
    "communityPostId" UUID,
    "communityPostCommentId" UUID,
    "mentionText" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Mention_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Mention_mentionedUserId_createdAt_idx" ON "Mention"("mentionedUserId", "createdAt");

-- CreateIndex
CREATE INDEX "Mention_commentId_idx" ON "Mention"("commentId");

-- CreateIndex
CREATE INDEX "Mention_communityPostId_idx" ON "Mention"("communityPostId");

-- CreateIndex
CREATE INDEX "Mention_communityPostCommentId_idx" ON "Mention"("communityPostCommentId");

-- AddForeignKey
ALTER TABLE "Mention" ADD CONSTRAINT "Mention_mentionedUserId_fkey" FOREIGN KEY ("mentionedUserId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Mention" ADD CONSTRAINT "Mention_commentId_fkey" FOREIGN KEY ("commentId") REFERENCES "Comment"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Mention" ADD CONSTRAINT "Mention_communityPostId_fkey" FOREIGN KEY ("communityPostId") REFERENCES "CommunityPost"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Mention" ADD CONSTRAINT "Mention_communityPostCommentId_fkey" FOREIGN KEY ("communityPostCommentId") REFERENCES "CommunityPostComment"("id") ON DELETE CASCADE ON UPDATE CASCADE;
