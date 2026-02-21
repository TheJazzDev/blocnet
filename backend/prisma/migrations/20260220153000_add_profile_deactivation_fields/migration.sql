ALTER TABLE "Profile"
  ADD COLUMN "isDeactivated" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "deactivatedAt" TIMESTAMP(3),
  ADD COLUMN "deactivatedBy" UUID,
  ADD COLUMN "deactivationReason" TEXT;

CREATE INDEX "Profile_isDeactivated_createdAt_idx"
  ON "Profile"("isDeactivated", "createdAt");
