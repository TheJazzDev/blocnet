-- Add enum values
ALTER TYPE "RoleName" ADD VALUE IF NOT EXISTS 'moderator';
ALTER TYPE "ProjectStatus" ADD VALUE IF NOT EXISTS 'hidden';
ALTER TYPE "UpdateStatus" ADD VALUE IF NOT EXISTS 'hidden';

-- Create moderation status enum
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type WHERE typname = 'ContentModerationStatus'
  ) THEN
    CREATE TYPE "ContentModerationStatus" AS ENUM ('active', 'hidden', 'archived');
  END IF;
END$$;

-- Project moderation columns
ALTER TABLE "Project"
  ADD COLUMN "moderatedBy" UUID,
  ADD COLUMN "moderatedAt" TIMESTAMP(3),
  ADD COLUMN "moderationReason" TEXT;

-- Update moderation columns
ALTER TABLE "Update"
  ADD COLUMN "moderatedBy" UUID,
  ADD COLUMN "moderatedAt" TIMESTAMP(3),
  ADD COLUMN "moderationReason" TEXT;

-- Comment moderation columns
ALTER TABLE "Comment"
  ADD COLUMN "status" "ContentModerationStatus" NOT NULL DEFAULT 'active',
  ADD COLUMN "moderatedBy" UUID,
  ADD COLUMN "moderatedAt" TIMESTAMP(3),
  ADD COLUMN "moderationReason" TEXT;

-- CommunityPost moderation columns
ALTER TABLE "CommunityPost"
  ADD COLUMN "status" "ContentModerationStatus" NOT NULL DEFAULT 'active',
  ADD COLUMN "moderatedBy" UUID,
  ADD COLUMN "moderatedAt" TIMESTAMP(3),
  ADD COLUMN "moderationReason" TEXT;

-- CommunityPostComment moderation columns
ALTER TABLE "CommunityPostComment"
  ADD COLUMN "status" "ContentModerationStatus" NOT NULL DEFAULT 'active',
  ADD COLUMN "moderatedBy" UUID,
  ADD COLUMN "moderatedAt" TIMESTAMP(3),
  ADD COLUMN "moderationReason" TEXT;

-- Foreign keys for moderation actor references
ALTER TABLE "Project"
  ADD CONSTRAINT "Project_moderatedBy_fkey"
  FOREIGN KEY ("moderatedBy") REFERENCES "Profile"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "Update"
  ADD CONSTRAINT "Update_moderatedBy_fkey"
  FOREIGN KEY ("moderatedBy") REFERENCES "Profile"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "Comment"
  ADD CONSTRAINT "Comment_moderatedBy_fkey"
  FOREIGN KEY ("moderatedBy") REFERENCES "Profile"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "CommunityPost"
  ADD CONSTRAINT "CommunityPost_moderatedBy_fkey"
  FOREIGN KEY ("moderatedBy") REFERENCES "Profile"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "CommunityPostComment"
  ADD CONSTRAINT "CommunityPostComment_moderatedBy_fkey"
  FOREIGN KEY ("moderatedBy") REFERENCES "Profile"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Indexes for moderation filtering/listing
CREATE INDEX "Project_status_createdAt_idx" ON "Project"("status", "createdAt");
CREATE INDEX "Update_status_createdAt_idx" ON "Update"("status", "createdAt");
CREATE INDEX "Comment_updateId_status_createdAt_idx" ON "Comment"("updateId", "status", "createdAt");
CREATE INDEX "Comment_status_createdAt_idx" ON "Comment"("status", "createdAt");
CREATE INDEX "CommunityPost_topic_status_createdAt_idx" ON "CommunityPost"("topic", "status", "createdAt");
CREATE INDEX "CommunityPost_status_createdAt_idx" ON "CommunityPost"("status", "createdAt");
CREATE INDEX "CommunityPostComment_postId_status_createdAt_idx" ON "CommunityPostComment"("postId", "status", "createdAt");
CREATE INDEX "CommunityPostComment_status_createdAt_idx" ON "CommunityPostComment"("status", "createdAt");
