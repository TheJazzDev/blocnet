-- Create CommentReaction table
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

-- Create CommunityPostCommentReaction table
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
