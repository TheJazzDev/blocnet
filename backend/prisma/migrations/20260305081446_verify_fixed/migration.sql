/*
  Warnings:

  - The `kind` column on the `CommentReaction` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The `kind` column on the `CommunityPostCommentReaction` table would be dropped and recreated. This will lead to data loss if there is data in the column.

*/
-- AlterTable (guarded because the table is created in a later migration)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'ClosedAlphaAccessEmail'
  ) THEN
    ALTER TABLE "ClosedAlphaAccessEmail" ALTER COLUMN "id" DROP DEFAULT;
  END IF;
END $$;

-- AlterTable
ALTER TABLE "CommentReaction" ALTER COLUMN "id" DROP DEFAULT,
DROP COLUMN "kind",
ADD COLUMN     "kind" "CommunityReactionKind" NOT NULL DEFAULT 'like';

-- AlterTable
ALTER TABLE "CommunityPostCommentReaction" ALTER COLUMN "id" DROP DEFAULT,
DROP COLUMN "kind",
ADD COLUMN     "kind" "CommunityReactionKind" NOT NULL DEFAULT 'like';

-- AlterTable
ALTER TABLE "EdgeEngagement" ALTER COLUMN "id" DROP DEFAULT;

-- CreateIndex
CREATE INDEX "CommentReaction_commentId_kind_idx" ON "CommentReaction"("commentId", "kind");

-- CreateIndex
CREATE UNIQUE INDEX "CommentReaction_commentId_userId_kind_key" ON "CommentReaction"("commentId", "userId", "kind");

-- CreateIndex
CREATE INDEX "CommunityPostCommentReaction_commentId_kind_idx" ON "CommunityPostCommentReaction"("commentId", "kind");

-- CreateIndex
CREATE UNIQUE INDEX "CommunityPostCommentReaction_commentId_userId_kind_key" ON "CommunityPostCommentReaction"("commentId", "userId", "kind");
