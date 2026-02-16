-- Rename Post domain artifacts to Update.
ALTER TYPE "PostStatus" RENAME TO "UpdateStatus";
ALTER TYPE "PostUrgency" RENAME TO "UpdateUrgency";

ALTER TABLE "Post" RENAME TO "Update";
ALTER TABLE "Comment" RENAME COLUMN "postId" TO "updateId";
ALTER TABLE "Notification" RENAME COLUMN "postId" TO "updateId";

ALTER INDEX "Post_projectId_urgency_idx" RENAME TO "Update_projectId_urgency_idx";
ALTER INDEX "Post_authorId_idx" RENAME TO "Update_authorId_idx";
ALTER INDEX "Comment_postId_createdAt_idx" RENAME TO "Comment_updateId_createdAt_idx";

ALTER TABLE "Update" RENAME CONSTRAINT "Post_projectId_fkey" TO "Update_projectId_fkey";
ALTER TABLE "Update" RENAME CONSTRAINT "Post_authorId_fkey" TO "Update_authorId_fkey";
ALTER TABLE "Notification" RENAME CONSTRAINT "Notification_postId_fkey" TO "Notification_updateId_fkey";
ALTER TABLE "Comment" RENAME CONSTRAINT "Comment_postId_fkey" TO "Comment_updateId_fkey";
