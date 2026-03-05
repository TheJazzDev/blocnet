ALTER TABLE "RuntimeFeatureConfig"
  ADD COLUMN IF NOT EXISTS "closedAlphaEnabled" BOOLEAN NOT NULL DEFAULT false;

CREATE TABLE IF NOT EXISTS "ClosedAlphaAccessEmail" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "email" TEXT NOT NULL,
  "emailNormalized" TEXT NOT NULL,
  "isActive" BOOLEAN NOT NULL DEFAULT true,
  "source" TEXT NOT NULL DEFAULT 'landing',
  "note" TEXT,
  "createdById" UUID,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "ClosedAlphaAccessEmail_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "ClosedAlphaAccessEmail_emailNormalized_key"
  ON "ClosedAlphaAccessEmail"("emailNormalized");

CREATE INDEX IF NOT EXISTS "ClosedAlphaAccessEmail_isActive_createdAt_idx"
  ON "ClosedAlphaAccessEmail"("isActive", "createdAt");

CREATE INDEX IF NOT EXISTS "ClosedAlphaAccessEmail_email_idx"
  ON "ClosedAlphaAccessEmail"("email");
