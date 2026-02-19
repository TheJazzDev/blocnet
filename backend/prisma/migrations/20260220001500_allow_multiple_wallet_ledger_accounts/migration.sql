-- Allow multiple ledger accounts (user, hold, etc.) to point to the same wallet.
DROP INDEX IF EXISTS "LedgerAccount_walletId_key";

CREATE INDEX IF NOT EXISTS "LedgerAccount_walletId_accountType_currency_idx"
ON "LedgerAccount"("walletId", "accountType", "currency");
