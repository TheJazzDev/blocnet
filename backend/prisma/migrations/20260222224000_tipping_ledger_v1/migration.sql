DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'TipCurrencyKind') THEN
    CREATE TYPE "TipCurrencyKind" AS ENUM ('points', 'token');
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'TipAccountType') THEN
    CREATE TYPE "TipAccountType" AS ENUM ('user', 'fee_vault');
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'TipTransactionType') THEN
    CREATE TYPE "TipTransactionType" AS ENUM ('tip', 'conversion', 'adjustment');
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS "TipCurrency" (
  "code" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "symbol" TEXT NOT NULL,
  "decimals" INTEGER NOT NULL,
  "kind" "TipCurrencyKind" NOT NULL DEFAULT 'points',
  "isEnabled" BOOLEAN NOT NULL DEFAULT true,
  "isActiveTippingCurrency" BOOLEAN NOT NULL DEFAULT false,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "TipCurrency_pkey" PRIMARY KEY ("code")
);

CREATE TABLE IF NOT EXISTS "TipFeeConfig" (
  "id" UUID NOT NULL,
  "currencyCode" TEXT NOT NULL,
  "feeBps" INTEGER NOT NULL DEFAULT 0,
  "minTipAtomic" BIGINT NOT NULL DEFAULT 1,
  "maxTipAtomic" BIGINT,
  "minFeeAtomic" BIGINT NOT NULL DEFAULT 0,
  "maxFeeAtomic" BIGINT,
  "senderPaysFee" BOOLEAN NOT NULL DEFAULT true,
  "isActive" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "TipFeeConfig_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "TipAccount" (
  "id" UUID NOT NULL,
  "accountType" "TipAccountType" NOT NULL,
  "ownerRef" TEXT NOT NULL,
  "userId" UUID,
  "currencyCode" TEXT NOT NULL,
  "balanceAtomic" BIGINT NOT NULL DEFAULT 0,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "TipAccount_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "TipTransaction" (
  "id" UUID NOT NULL,
  "type" "TipTransactionType" NOT NULL DEFAULT 'tip',
  "senderAccountId" UUID NOT NULL,
  "recipientAccountId" UUID NOT NULL,
  "feeAccountId" UUID,
  "senderUserId" UUID NOT NULL,
  "recipientUserId" UUID NOT NULL,
  "currencyCode" TEXT NOT NULL,
  "amountAtomic" BIGINT NOT NULL,
  "feeAtomic" BIGINT NOT NULL DEFAULT 0,
  "totalDebitAtomic" BIGINT NOT NULL,
  "note" TEXT,
  "contextType" TEXT,
  "contextId" TEXT,
  "idempotencyKey" TEXT NOT NULL,
  "metadata" JSONB,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "TipTransaction_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "TipConversion" (
  "id" UUID NOT NULL,
  "userId" UUID NOT NULL,
  "fromCurrencyCode" TEXT NOT NULL,
  "toCurrencyCode" TEXT NOT NULL,
  "amountInAtomic" BIGINT NOT NULL,
  "amountOutAtomic" BIGINT NOT NULL,
  "rateNumerator" BIGINT NOT NULL,
  "rateDenominator" BIGINT NOT NULL,
  "idempotencyKey" TEXT NOT NULL,
  "metadata" JSONB,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "TipConversion_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "TipFeeConfig_currencyCode_key"
ON "TipFeeConfig"("currencyCode");

CREATE UNIQUE INDEX IF NOT EXISTS "TipAccount_accountType_ownerRef_currencyCode_key"
ON "TipAccount"("accountType", "ownerRef", "currencyCode");

CREATE UNIQUE INDEX IF NOT EXISTS "TipTransaction_idempotencyKey_key"
ON "TipTransaction"("idempotencyKey");

CREATE UNIQUE INDEX IF NOT EXISTS "TipConversion_idempotencyKey_key"
ON "TipConversion"("idempotencyKey");

CREATE INDEX IF NOT EXISTS "TipCurrency_isActiveTippingCurrency_isEnabled_idx"
ON "TipCurrency"("isActiveTippingCurrency", "isEnabled");

CREATE INDEX IF NOT EXISTS "TipAccount_userId_currencyCode_idx"
ON "TipAccount"("userId", "currencyCode");

CREATE INDEX IF NOT EXISTS "TipAccount_currencyCode_accountType_idx"
ON "TipAccount"("currencyCode", "accountType");

CREATE INDEX IF NOT EXISTS "TipTransaction_senderUserId_createdAt_idx"
ON "TipTransaction"("senderUserId", "createdAt");

CREATE INDEX IF NOT EXISTS "TipTransaction_recipientUserId_createdAt_idx"
ON "TipTransaction"("recipientUserId", "createdAt");

CREATE INDEX IF NOT EXISTS "TipTransaction_currencyCode_createdAt_idx"
ON "TipTransaction"("currencyCode", "createdAt");

CREATE INDEX IF NOT EXISTS "TipConversion_userId_createdAt_idx"
ON "TipConversion"("userId", "createdAt");

CREATE INDEX IF NOT EXISTS "TipConversion_fromCurrencyCode_toCurrencyCode_createdAt_idx"
ON "TipConversion"("fromCurrencyCode", "toCurrencyCode", "createdAt");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'TipFeeConfig_currencyCode_fkey'
  ) THEN
    ALTER TABLE "TipFeeConfig"
      ADD CONSTRAINT "TipFeeConfig_currencyCode_fkey"
      FOREIGN KEY ("currencyCode") REFERENCES "TipCurrency"("code")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'TipAccount_userId_fkey'
  ) THEN
    ALTER TABLE "TipAccount"
      ADD CONSTRAINT "TipAccount_userId_fkey"
      FOREIGN KEY ("userId") REFERENCES "Profile"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'TipAccount_currencyCode_fkey'
  ) THEN
    ALTER TABLE "TipAccount"
      ADD CONSTRAINT "TipAccount_currencyCode_fkey"
      FOREIGN KEY ("currencyCode") REFERENCES "TipCurrency"("code")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'TipTransaction_senderAccountId_fkey'
  ) THEN
    ALTER TABLE "TipTransaction"
      ADD CONSTRAINT "TipTransaction_senderAccountId_fkey"
      FOREIGN KEY ("senderAccountId") REFERENCES "TipAccount"("id")
      ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'TipTransaction_recipientAccountId_fkey'
  ) THEN
    ALTER TABLE "TipTransaction"
      ADD CONSTRAINT "TipTransaction_recipientAccountId_fkey"
      FOREIGN KEY ("recipientAccountId") REFERENCES "TipAccount"("id")
      ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'TipTransaction_feeAccountId_fkey'
  ) THEN
    ALTER TABLE "TipTransaction"
      ADD CONSTRAINT "TipTransaction_feeAccountId_fkey"
      FOREIGN KEY ("feeAccountId") REFERENCES "TipAccount"("id")
      ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'TipTransaction_senderUserId_fkey'
  ) THEN
    ALTER TABLE "TipTransaction"
      ADD CONSTRAINT "TipTransaction_senderUserId_fkey"
      FOREIGN KEY ("senderUserId") REFERENCES "Profile"("id")
      ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'TipTransaction_recipientUserId_fkey'
  ) THEN
    ALTER TABLE "TipTransaction"
      ADD CONSTRAINT "TipTransaction_recipientUserId_fkey"
      FOREIGN KEY ("recipientUserId") REFERENCES "Profile"("id")
      ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'TipTransaction_currencyCode_fkey'
  ) THEN
    ALTER TABLE "TipTransaction"
      ADD CONSTRAINT "TipTransaction_currencyCode_fkey"
      FOREIGN KEY ("currencyCode") REFERENCES "TipCurrency"("code")
      ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'TipConversion_userId_fkey'
  ) THEN
    ALTER TABLE "TipConversion"
      ADD CONSTRAINT "TipConversion_userId_fkey"
      FOREIGN KEY ("userId") REFERENCES "Profile"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'TipConversion_fromCurrencyCode_fkey'
  ) THEN
    ALTER TABLE "TipConversion"
      ADD CONSTRAINT "TipConversion_fromCurrencyCode_fkey"
      FOREIGN KEY ("fromCurrencyCode") REFERENCES "TipCurrency"("code")
      ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'TipConversion_toCurrencyCode_fkey'
  ) THEN
    ALTER TABLE "TipConversion"
      ADD CONSTRAINT "TipConversion_toCurrencyCode_fkey"
      FOREIGN KEY ("toCurrencyCode") REFERENCES "TipCurrency"("code")
      ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END
$$;

INSERT INTO "TipCurrency" (
  "code", "name", "symbol", "decimals", "kind",
  "isEnabled", "isActiveTippingCurrency", "createdAt", "updatedAt"
)
VALUES
  ('MCR', 'Mine Credits', 'MCR', 3, 'points', true, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('BNT', 'BlocNet Token', 'BNT', 18, 'token', true, false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("code") DO UPDATE
SET
  "name" = EXCLUDED."name",
  "symbol" = EXCLUDED."symbol",
  "decimals" = EXCLUDED."decimals",
  "kind" = EXCLUDED."kind",
  "isEnabled" = EXCLUDED."isEnabled",
  "updatedAt" = CURRENT_TIMESTAMP;

UPDATE "TipCurrency"
SET "isActiveTippingCurrency" = CASE WHEN "code" = 'MCR' THEN true ELSE false END
WHERE "code" IN ('MCR', 'BNT');

INSERT INTO "TipFeeConfig" (
  "id", "currencyCode", "feeBps", "minTipAtomic", "maxTipAtomic",
  "minFeeAtomic", "maxFeeAtomic", "senderPaysFee", "isActive", "createdAt", "updatedAt"
)
VALUES
  ('6fd44f57-48b3-4d1f-a881-22700c6f6f06', 'MCR', 500, 1, NULL, 0, NULL, true, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('65f11f6b-5a39-482d-ab65-11712ba25a8d', 'BNT', 500, 1000000000000000, NULL, 0, NULL, true, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("currencyCode") DO UPDATE
SET
  "feeBps" = EXCLUDED."feeBps",
  "minTipAtomic" = EXCLUDED."minTipAtomic",
  "maxTipAtomic" = EXCLUDED."maxTipAtomic",
  "minFeeAtomic" = EXCLUDED."minFeeAtomic",
  "maxFeeAtomic" = EXCLUDED."maxFeeAtomic",
  "senderPaysFee" = EXCLUDED."senderPaysFee",
  "isActive" = EXCLUDED."isActive",
  "updatedAt" = CURRENT_TIMESTAMP;

INSERT INTO "TipAccount" (
  "id", "accountType", "ownerRef", "userId", "currencyCode", "balanceAtomic", "createdAt", "updatedAt"
)
VALUES
  ('4b80fbe7-4bb8-4d58-a80e-737bb5187179', 'fee_vault', 'FEE_VAULT', NULL, 'MCR', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('0f45e5f2-da7b-4fef-9baf-e0f22c539403', 'fee_vault', 'FEE_VAULT', NULL, 'BNT', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("accountType", "ownerRef", "currencyCode") DO NOTHING;

INSERT INTO "TipAccount" (
  "id", "accountType", "ownerRef", "userId", "currencyCode", "balanceAtomic", "createdAt", "updatedAt"
)
SELECT
  (
    regexp_replace(
      md5('tip-user-mcr-' || p."id"),
      '(.{8})(.{4})(.{4})(.{4})(.{12})',
      '\1-\2-\3-\4-\5'
    )
  )::uuid AS "id",
  'user'::"TipAccountType" AS "accountType",
  p."id" AS "ownerRef",
  p."id" AS "userId",
  'MCR' AS "currencyCode",
  (p."miningClaimedPoints" * 1000)::bigint AS "balanceAtomic",
  CURRENT_TIMESTAMP AS "createdAt",
  CURRENT_TIMESTAMP AS "updatedAt"
FROM "Profile" p
ON CONFLICT ("accountType", "ownerRef", "currencyCode") DO UPDATE
SET
  "balanceAtomic" = GREATEST("TipAccount"."balanceAtomic", EXCLUDED."balanceAtomic"),
  "updatedAt" = CURRENT_TIMESTAMP;
