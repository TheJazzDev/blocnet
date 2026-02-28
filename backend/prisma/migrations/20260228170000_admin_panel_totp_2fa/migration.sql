CREATE TABLE IF NOT EXISTS "AdminSecurityPolicy" (
  "id" TEXT NOT NULL,
  "require2faForAdminPanel" BOOLEAN NOT NULL DEFAULT false,
  "updatedById" UUID,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "AdminSecurityPolicy_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "AdminTotpCredential" (
  "userId" UUID NOT NULL,
  "secretCipher" TEXT NOT NULL,
  "secretIv" TEXT NOT NULL,
  "secretAuthTag" TEXT NOT NULL,
  "enabledAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "lastUsedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "AdminTotpCredential_pkey" PRIMARY KEY ("userId")
);

CREATE TABLE IF NOT EXISTS "AdminTotpEnrollmentChallenge" (
  "userId" UUID NOT NULL,
  "secretCipher" TEXT NOT NULL,
  "secretIv" TEXT NOT NULL,
  "secretAuthTag" TEXT NOT NULL,
  "expiresAt" TIMESTAMP(3) NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "AdminTotpEnrollmentChallenge_pkey" PRIMARY KEY ("userId")
);

CREATE TABLE IF NOT EXISTS "AdminTotpRecoveryCode" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "userId" UUID NOT NULL,
  "codeHash" TEXT NOT NULL,
  "consumedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "AdminTotpRecoveryCode_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "AdminTwoFactorSession" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "userId" UUID NOT NULL,
  "tokenHash" TEXT NOT NULL,
  "expiresAt" TIMESTAMP(3) NOT NULL,
  "revokedAt" TIMESTAMP(3),
  "lastUsedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "AdminTwoFactorSession_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "AdminTotpRecoveryCode_userId_codeHash_key"
  ON "AdminTotpRecoveryCode"("userId", "codeHash");

CREATE UNIQUE INDEX IF NOT EXISTS "AdminTwoFactorSession_tokenHash_key"
  ON "AdminTwoFactorSession"("tokenHash");

CREATE INDEX IF NOT EXISTS "AdminTotpCredential_enabledAt_idx"
  ON "AdminTotpCredential"("enabledAt");

CREATE INDEX IF NOT EXISTS "AdminTotpEnrollmentChallenge_expiresAt_idx"
  ON "AdminTotpEnrollmentChallenge"("expiresAt");

CREATE INDEX IF NOT EXISTS "AdminTotpRecoveryCode_userId_consumedAt_idx"
  ON "AdminTotpRecoveryCode"("userId", "consumedAt");

CREATE INDEX IF NOT EXISTS "AdminTwoFactorSession_userId_expiresAt_revokedAt_idx"
  ON "AdminTwoFactorSession"("userId", "expiresAt", "revokedAt");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'AdminTotpCredential_userId_fkey'
  ) THEN
    ALTER TABLE "AdminTotpCredential"
      ADD CONSTRAINT "AdminTotpCredential_userId_fkey"
      FOREIGN KEY ("userId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'AdminTotpEnrollmentChallenge_userId_fkey'
  ) THEN
    ALTER TABLE "AdminTotpEnrollmentChallenge"
      ADD CONSTRAINT "AdminTotpEnrollmentChallenge_userId_fkey"
      FOREIGN KEY ("userId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'AdminTotpRecoveryCode_userId_fkey'
  ) THEN
    ALTER TABLE "AdminTotpRecoveryCode"
      ADD CONSTRAINT "AdminTotpRecoveryCode_userId_fkey"
      FOREIGN KEY ("userId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'AdminTwoFactorSession_userId_fkey'
  ) THEN
    ALTER TABLE "AdminTwoFactorSession"
      ADD CONSTRAINT "AdminTwoFactorSession_userId_fkey"
      FOREIGN KEY ("userId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END
$$;

INSERT INTO "AdminSecurityPolicy" ("id", "require2faForAdminPanel", "updatedById", "updatedAt")
VALUES ('default', false, NULL, NOW())
ON CONFLICT ("id") DO NOTHING;
