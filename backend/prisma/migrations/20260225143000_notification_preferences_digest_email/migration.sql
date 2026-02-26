DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'NotificationCategory') THEN
    CREATE TYPE "NotificationCategory" AS ENUM (
      'updates',
      'social',
      'governance',
      'wallet',
      'mining_referrals',
      'rewards',
      'system'
    );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'DigestCadence') THEN
    CREATE TYPE "DigestCadence" AS ENUM ('daily', 'weekly');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS "UserNotificationSettings" (
  "userId" UUID NOT NULL,
  "masterEnabled" BOOLEAN NOT NULL DEFAULT true,
  "digestEmailEnabled" BOOLEAN NOT NULL DEFAULT true,
  "digestCadence" "DigestCadence" NOT NULL DEFAULT 'daily',
  "digestHourLocal" INTEGER NOT NULL DEFAULT 8,
  "digestMinuteLocal" INTEGER NOT NULL DEFAULT 0,
  "timezone" TEXT NOT NULL DEFAULT 'UTC',
  "lastDigestSentAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "UserNotificationSettings_pkey" PRIMARY KEY ("userId")
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'UserNotificationSettings_userId_fkey'
  ) THEN
    ALTER TABLE "UserNotificationSettings"
    ADD CONSTRAINT "UserNotificationSettings_userId_fkey"
    FOREIGN KEY ("userId")
    REFERENCES "Profile"("id")
    ON DELETE CASCADE
    ON UPDATE CASCADE;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS "UserNotificationCategoryPreference" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "userId" UUID NOT NULL,
  "category" "NotificationCategory" NOT NULL,
  "enabled" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "UserNotificationCategoryPreference_pkey" PRIMARY KEY ("id")
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'UserNotificationCategoryPreference_userId_fkey'
  ) THEN
    ALTER TABLE "UserNotificationCategoryPreference"
    ADD CONSTRAINT "UserNotificationCategoryPreference_userId_fkey"
    FOREIGN KEY ("userId")
    REFERENCES "Profile"("id")
    ON DELETE CASCADE
    ON UPDATE CASCADE;
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS "UserNotificationCategoryPreference_userId_category_key"
ON "UserNotificationCategoryPreference"("userId", "category");

CREATE INDEX IF NOT EXISTS "UserNotificationCategoryPreference_userId_category_idx"
ON "UserNotificationCategoryPreference"("userId", "category");

CREATE TABLE IF NOT EXISTS "UserNotificationTypeOverride" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "userId" UUID NOT NULL,
  "type" "NotificationType" NOT NULL,
  "enabled" BOOLEAN NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "UserNotificationTypeOverride_pkey" PRIMARY KEY ("id")
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'UserNotificationTypeOverride_userId_fkey'
  ) THEN
    ALTER TABLE "UserNotificationTypeOverride"
    ADD CONSTRAINT "UserNotificationTypeOverride_userId_fkey"
    FOREIGN KEY ("userId")
    REFERENCES "Profile"("id")
    ON DELETE CASCADE
    ON UPDATE CASCADE;
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS "UserNotificationTypeOverride_userId_type_key"
ON "UserNotificationTypeOverride"("userId", "type");

CREATE INDEX IF NOT EXISTS "UserNotificationTypeOverride_userId_type_idx"
ON "UserNotificationTypeOverride"("userId", "type");

ALTER TABLE "UserNotificationSettings"
  ALTER COLUMN "updatedAt" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE "UserNotificationCategoryPreference"
  ALTER COLUMN "id" SET DEFAULT gen_random_uuid(),
  ALTER COLUMN "updatedAt" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE "UserNotificationTypeOverride"
  ALTER COLUMN "id" SET DEFAULT gen_random_uuid(),
  ALTER COLUMN "updatedAt" SET DEFAULT CURRENT_TIMESTAMP;
