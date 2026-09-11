-- WS-H F-07: retire the legacy "Mine Credits" (MCR) tip currency.
--
-- BNP (Blocnet Point) is what users mine today; BNT (Blocnet Token) launches on
-- BSC and BNP converts to BNT at launch. MCR was never created by
-- prisma/seed.ts or prisma/seed.dev.ts, it only exists as a hand-created row in
-- some environments. Every statement below is guarded so the migration is a
-- safe no-op when MCR is absent or still referenced by ledger history.

-- 1. Drop MCR tip accounts that no TipTransaction references
--    (TipTransaction -> TipAccount FKs are ON DELETE RESTRICT / SET NULL).
DELETE FROM "TipAccount" a
WHERE a."currencyCode" = 'MCR'
  AND NOT EXISTS (
    SELECT 1
    FROM "TipTransaction" t
    WHERE t."senderAccountId" = a.id
       OR t."recipientAccountId" = a.id
       OR t."feeAccountId" = a.id
  );

-- 2. Drop the MCR fee policy once no account remains. TipFeeConfig cascades
--    from TipCurrency anyway; this is explicit so the intent is readable.
DELETE FROM "TipFeeConfig" f
WHERE f."currencyCode" = 'MCR'
  AND NOT EXISTS (
    SELECT 1 FROM "TipAccount" a WHERE a."currencyCode" = 'MCR'
  );

-- 3. Drop the currency only when nothing references it any more
--    (accounts, transactions, conversions).
DELETE FROM "TipCurrency" cur
WHERE cur.code = 'MCR'
  AND NOT EXISTS (
    SELECT 1 FROM "TipAccount" a WHERE a."currencyCode" = cur.code
  )
  AND NOT EXISTS (
    SELECT 1 FROM "TipTransaction" t WHERE t."currencyCode" = cur.code
  )
  AND NOT EXISTS (
    SELECT 1
    FROM "TipConversion" c
    WHERE c."fromCurrencyCode" = cur.code
       OR c."toCurrencyCode" = cur.code
  );
