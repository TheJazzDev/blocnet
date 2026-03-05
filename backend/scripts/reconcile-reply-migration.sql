-- Migration: Add reply functionality to comments
-- This adds replyToId field to Comment and CommunityPostComment tables

-- Add replyToId column to Comment table
ALTER TABLE "Comment" ADD COLUMN IF NOT EXISTS "replyToId" UUID;

-- Create index on replyToId for Comment
CREATE INDEX IF NOT EXISTS "Comment_replyToId_idx" ON "Comment"("replyToId");

-- Add foreign key constraint for Comment.replyToId
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'Comment_replyToId_fkey'
    ) THEN
        ALTER TABLE "Comment"
        ADD CONSTRAINT "Comment_replyToId_fkey"
        FOREIGN KEY ("replyToId")
        REFERENCES "Comment"("id")
        ON DELETE SET NULL
        ON UPDATE CASCADE;
    END IF;
END $$;

-- Add replyToId column to CommunityPostComment table
ALTER TABLE "CommunityPostComment" ADD COLUMN IF NOT EXISTS "replyToId" UUID;

-- Create index on replyToId for CommunityPostComment
CREATE INDEX IF NOT EXISTS "CommunityPostComment_replyToId_idx" ON "CommunityPostComment"("replyToId");

-- Add foreign key constraint for CommunityPostComment.replyToId
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'CommunityPostComment_replyToId_fkey'
    ) THEN
        ALTER TABLE "CommunityPostComment"
        ADD CONSTRAINT "CommunityPostComment_replyToId_fkey"
        FOREIGN KEY ("replyToId")
        REFERENCES "CommunityPostComment"("id")
        ON DELETE SET NULL
        ON UPDATE CASCADE;
    END IF;
END $$;
