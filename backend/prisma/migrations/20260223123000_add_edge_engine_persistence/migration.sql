DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'EdgeAction') THEN
    CREATE TYPE "EdgeAction" AS ENUM ('act', 'watch', 'ignore');
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS "EdgeDecision" (
  "id" UUID NOT NULL,
  "userId" UUID NOT NULL,
  "decisionId" TEXT NOT NULL,
  "updateId" UUID NOT NULL,
  "projectId" UUID NOT NULL,
  "edgeScore" DOUBLE PRECISION NOT NULL,
  "recommendedAction" "EdgeAction" NOT NULL,
  "reasonCodes" JSONB,
  "explanationPreview" TEXT,
  "urgencyScore" DOUBLE PRECISION NOT NULL,
  "recencyScore" DOUBLE PRECISION NOT NULL,
  "relevanceScore" DOUBLE PRECISION NOT NULL,
  "noveltyScore" DOUBLE PRECISION NOT NULL,
  "penaltyScore" DOUBLE PRECISION NOT NULL,
  "generatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "EdgeDecision_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "EdgeFeedback" (
  "id" UUID NOT NULL,
  "userId" UUID NOT NULL,
  "decisionRecordId" UUID NOT NULL,
  "decisionId" TEXT NOT NULL,
  "action" "EdgeAction" NOT NULL,
  "context" JSONB,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "EdgeFeedback_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "EdgeDecision_userId_decisionId_key"
ON "EdgeDecision"("userId", "decisionId");

CREATE INDEX IF NOT EXISTS "EdgeDecision_userId_generatedAt_idx"
ON "EdgeDecision"("userId", "generatedAt");

CREATE INDEX IF NOT EXISTS "EdgeDecision_projectId_generatedAt_idx"
ON "EdgeDecision"("projectId", "generatedAt");

CREATE INDEX IF NOT EXISTS "EdgeDecision_updateId_generatedAt_idx"
ON "EdgeDecision"("updateId", "generatedAt");

CREATE INDEX IF NOT EXISTS "EdgeDecision_recommendedAction_generatedAt_idx"
ON "EdgeDecision"("recommendedAction", "generatedAt");

CREATE INDEX IF NOT EXISTS "EdgeFeedback_userId_createdAt_idx"
ON "EdgeFeedback"("userId", "createdAt");

CREATE INDEX IF NOT EXISTS "EdgeFeedback_decisionRecordId_createdAt_idx"
ON "EdgeFeedback"("decisionRecordId", "createdAt");

CREATE INDEX IF NOT EXISTS "EdgeFeedback_decisionId_createdAt_idx"
ON "EdgeFeedback"("decisionId", "createdAt");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'EdgeDecision_userId_fkey'
  ) THEN
    ALTER TABLE "EdgeDecision"
      ADD CONSTRAINT "EdgeDecision_userId_fkey"
      FOREIGN KEY ("userId") REFERENCES "Profile"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'EdgeDecision_updateId_fkey'
  ) THEN
    ALTER TABLE "EdgeDecision"
      ADD CONSTRAINT "EdgeDecision_updateId_fkey"
      FOREIGN KEY ("updateId") REFERENCES "Update"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'EdgeDecision_projectId_fkey'
  ) THEN
    ALTER TABLE "EdgeDecision"
      ADD CONSTRAINT "EdgeDecision_projectId_fkey"
      FOREIGN KEY ("projectId") REFERENCES "Project"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'EdgeFeedback_userId_fkey'
  ) THEN
    ALTER TABLE "EdgeFeedback"
      ADD CONSTRAINT "EdgeFeedback_userId_fkey"
      FOREIGN KEY ("userId") REFERENCES "Profile"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'EdgeFeedback_decisionRecordId_fkey'
  ) THEN
    ALTER TABLE "EdgeFeedback"
      ADD CONSTRAINT "EdgeFeedback_decisionRecordId_fkey"
      FOREIGN KEY ("decisionRecordId") REFERENCES "EdgeDecision"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END
$$;
