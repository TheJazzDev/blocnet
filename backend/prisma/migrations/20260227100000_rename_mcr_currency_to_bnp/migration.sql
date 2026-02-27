-- Rename the tipping points currency code from MCR to BNP.
-- All dependent foreign keys were created with ON UPDATE CASCADE.
UPDATE "TipCurrency"
SET
  "code" = 'BNP',
  "name" = 'Blocnet Points',
  "symbol" = 'BNP',
  "updatedAt" = CURRENT_TIMESTAMP
WHERE "code" = 'MCR'
  AND NOT EXISTS (
    SELECT 1 FROM "TipCurrency" WHERE "code" = 'BNP'
  );

-- Keep canonical metadata even when BNP already exists.
UPDATE "TipCurrency"
SET
  "name" = 'Blocnet Points',
  "symbol" = 'BNP',
  "updatedAt" = CURRENT_TIMESTAMP
WHERE "code" = 'BNP';
