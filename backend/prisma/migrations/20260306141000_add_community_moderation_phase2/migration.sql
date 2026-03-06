DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'CommunityModerationReportTargetType') THEN
    CREATE TYPE "CommunityModerationReportTargetType" AS ENUM ('community_post', 'community_comment', 'user_profile');
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'CommunityModerationReportStatus') THEN
    CREATE TYPE "CommunityModerationReportStatus" AS ENUM ('open', 'resolved', 'dismissed');
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'CommunityModerationActionType') THEN
    CREATE TYPE "CommunityModerationActionType" AS ENUM (
      'warning',
      'mute',
      'suspend',
      'restrict_posting',
      'restrict_commenting',
      'clear_restrictions'
    );
  END IF;
END
$$;

ALTER TABLE "Profile"
  ADD COLUMN IF NOT EXISTS "communityWarnCount" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "communityLastWarnedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "communityMutedUntil" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "communitySuspendedUntil" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "communityPostingRestrictedUntil" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "communityCommentingRestrictedUntil" TIMESTAMP(3);

CREATE TABLE IF NOT EXISTS "CommunityModerationReport" (
  "id" UUID NOT NULL,
  "reporterId" UUID NOT NULL,
  "targetType" "CommunityModerationReportTargetType" NOT NULL,
  "targetId" UUID NOT NULL,
  "targetUserId" UUID,
  "reason" TEXT NOT NULL,
  "details" TEXT,
  "status" "CommunityModerationReportStatus" NOT NULL DEFAULT 'open',
  "reviewedById" UUID,
  "reviewedAt" TIMESTAMP(3),
  "resolutionNote" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "CommunityModerationReport_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "CommunityModerationAction" (
  "id" UUID NOT NULL,
  "actionType" "CommunityModerationActionType" NOT NULL,
  "actorId" UUID NOT NULL,
  "targetUserId" UUID NOT NULL,
  "reportId" UUID,
  "reason" TEXT,
  "previousValue" TIMESTAMP(3),
  "nextValue" TIMESTAMP(3),
  "metadata" JSONB,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "CommunityModerationAction_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "CommunityModerationReport_status_createdAt_idx"
  ON "CommunityModerationReport"("status", "createdAt");

CREATE INDEX IF NOT EXISTS "CommunityModerationReport_targetType_targetId_status_idx"
  ON "CommunityModerationReport"("targetType", "targetId", "status");

CREATE INDEX IF NOT EXISTS "CommunityModerationReport_reporterId_createdAt_idx"
  ON "CommunityModerationReport"("reporterId", "createdAt");

CREATE INDEX IF NOT EXISTS "CommunityModerationReport_targetUserId_createdAt_idx"
  ON "CommunityModerationReport"("targetUserId", "createdAt");

CREATE INDEX IF NOT EXISTS "CommunityModerationAction_targetUserId_createdAt_idx"
  ON "CommunityModerationAction"("targetUserId", "createdAt");

CREATE INDEX IF NOT EXISTS "CommunityModerationAction_actorId_createdAt_idx"
  ON "CommunityModerationAction"("actorId", "createdAt");

CREATE INDEX IF NOT EXISTS "CommunityModerationAction_actionType_createdAt_idx"
  ON "CommunityModerationAction"("actionType", "createdAt");

CREATE INDEX IF NOT EXISTS "CommunityModerationAction_reportId_idx"
  ON "CommunityModerationAction"("reportId");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'CommunityModerationReport_reporterId_fkey'
  ) THEN
    ALTER TABLE "CommunityModerationReport"
      ADD CONSTRAINT "CommunityModerationReport_reporterId_fkey"
      FOREIGN KEY ("reporterId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'CommunityModerationReport_targetUserId_fkey'
  ) THEN
    ALTER TABLE "CommunityModerationReport"
      ADD CONSTRAINT "CommunityModerationReport_targetUserId_fkey"
      FOREIGN KEY ("targetUserId") REFERENCES "Profile"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'CommunityModerationReport_reviewedById_fkey'
  ) THEN
    ALTER TABLE "CommunityModerationReport"
      ADD CONSTRAINT "CommunityModerationReport_reviewedById_fkey"
      FOREIGN KEY ("reviewedById") REFERENCES "Profile"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'CommunityModerationAction_actorId_fkey'
  ) THEN
    ALTER TABLE "CommunityModerationAction"
      ADD CONSTRAINT "CommunityModerationAction_actorId_fkey"
      FOREIGN KEY ("actorId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'CommunityModerationAction_targetUserId_fkey'
  ) THEN
    ALTER TABLE "CommunityModerationAction"
      ADD CONSTRAINT "CommunityModerationAction_targetUserId_fkey"
      FOREIGN KEY ("targetUserId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'CommunityModerationAction_reportId_fkey'
  ) THEN
    ALTER TABLE "CommunityModerationAction"
      ADD CONSTRAINT "CommunityModerationAction_reportId_fkey"
      FOREIGN KEY ("reportId") REFERENCES "CommunityModerationReport"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END
$$;
