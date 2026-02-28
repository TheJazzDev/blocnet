CREATE TABLE IF NOT EXISTS "SocialCredential" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "provider" TEXT NOT NULL,
  "accountLabel" TEXT,
  "username" TEXT,
  "passwordCipher" TEXT NOT NULL,
  "passwordIv" TEXT NOT NULL,
  "passwordAuthTag" TEXT NOT NULL,
  "notes" TEXT,
  "createdById" UUID NOT NULL,
  "updatedById" UUID,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "SocialCredential_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "SocialCredential_provider_updatedAt_idx"
  ON "SocialCredential"("provider", "updatedAt");

CREATE INDEX IF NOT EXISTS "SocialCredential_createdAt_idx"
  ON "SocialCredential"("createdAt");
