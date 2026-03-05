-- This migration reconciles the database state with the schema
-- All changes have already been applied manually via SQL scripts

-- Add replyToId to Comment table (if not exists)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'Comment' AND column_name = 'replyToId') THEN
    ALTER TABLE "Comment" ADD COLUMN "replyToId" UUID;
    CREATE INDEX "Comment_replyToId_idx" ON "Comment"("replyToId");
    ALTER TABLE "Comment" ADD CONSTRAINT "Comment_replyToId_fkey"
      FOREIGN KEY ("replyToId") REFERENCES "Comment"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

-- Add replyToId to CommunityPostComment table (if not exists)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'CommunityPostComment' AND column_name = 'replyToId') THEN
    ALTER TABLE "CommunityPostComment" ADD COLUMN "replyToId" UUID;
    CREATE INDEX "CommunityPostComment_replyToId_idx" ON "CommunityPostComment"("replyToId");
    ALTER TABLE "CommunityPostComment" ADD CONSTRAINT "CommunityPostComment_replyToId_fkey"
      FOREIGN KEY ("replyToId") REFERENCES "CommunityPostComment"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

-- Create CommentReaction table (if not exists)
CREATE TABLE IF NOT EXISTS "CommentReaction" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "commentId" UUID NOT NULL,
  "userId" UUID NOT NULL,
  "kind" TEXT NOT NULL DEFAULT 'like',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "CommentReaction_commentId_fkey" FOREIGN KEY ("commentId") REFERENCES "Comment"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "CommentReaction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "CommentReaction_commentId_userId_kind_key" ON "CommentReaction"("commentId", "userId", "kind");
CREATE INDEX IF NOT EXISTS "CommentReaction_userId_createdAt_idx" ON "CommentReaction"("userId", "createdAt");
CREATE INDEX IF NOT EXISTS "CommentReaction_commentId_kind_idx" ON "CommentReaction"("commentId", "kind");

-- Create CommunityPostCommentReaction table (if not exists)
CREATE TABLE IF NOT EXISTS "CommunityPostCommentReaction" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "commentId" UUID NOT NULL,
  "userId" UUID NOT NULL,
  "kind" TEXT NOT NULL DEFAULT 'like',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "CommunityPostCommentReaction_commentId_fkey" FOREIGN KEY ("commentId") REFERENCES "CommunityPostComment"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "CommunityPostCommentReaction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "CommunityPostCommentReaction_commentId_userId_kind_key" ON "CommunityPostCommentReaction"("commentId", "userId", "kind");
CREATE INDEX IF NOT EXISTS "CommunityPostCommentReaction_userId_createdAt_idx" ON "CommunityPostCommentReaction"("userId", "createdAt");
CREATE INDEX IF NOT EXISTS "CommunityPostCommentReaction_commentId_kind_idx" ON "CommunityPostCommentReaction"("commentId", "kind");

-- Fix EdgeEngagement id column default (set to gen_random_uuid if not already set)
DO $$
BEGIN
  -- Check if the column exists and update its default
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name = 'EdgeEngagement' AND column_name = 'id') THEN
    ALTER TABLE "EdgeEngagement" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();
  END IF;
END $$;
