-- CreateEnum
CREATE TYPE "ChainEnvironment" AS ENUM ('testnet', 'mainnet');

-- CreateEnum
CREATE TYPE "WalletProvider" AS ENUM ('turnkey');

-- CreateEnum
CREATE TYPE "WalletStatus" AS ENUM ('provisioning', 'ready', 'error', 'disabled');

-- CreateEnum
CREATE TYPE "LedgerAccountType" AS ENUM ('user', 'treasury', 'fee', 'hold');

-- CreateEnum
CREATE TYPE "LedgerReason" AS ENUM ('deposit_credit', 'deposit_sweep', 'internal_transfer', 'withdrawal_hold', 'withdrawal_finalize', 'withdrawal_reject_release', 'withdrawal_fee', 'manual_adjustment');

-- CreateEnum
CREATE TYPE "OnchainDepositStatus" AS ENUM ('detected', 'credited', 'swept', 'ignored', 'failed');

-- CreateEnum
CREATE TYPE "SweepJobStatus" AS ENUM ('queued', 'processing', 'completed', 'failed');

-- CreateEnum
CREATE TYPE "WithdrawalStatus" AS ENUM ('requested', 'pending_review', 'approved', 'rejected', 'broadcasting', 'confirmed', 'failed', 'reverted');

-- CreateEnum
CREATE TYPE "KycStatus" AS ENUM ('not_submitted', 'pending', 'approved', 'rejected');

-- CreateTable
CREATE TABLE "UserWallet" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "provider" "WalletProvider" NOT NULL DEFAULT 'turnkey',
    "providerWalletId" TEXT,
    "chainEnvironment" "ChainEnvironment" NOT NULL DEFAULT 'testnet',
    "chainId" INTEGER NOT NULL,
    "address" TEXT,
    "status" "WalletStatus" NOT NULL DEFAULT 'provisioning',
    "lastProvisionAttemptAt" TIMESTAMP(3),
    "provisionedAt" TIMESTAMP(3),
    "failureReason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "UserWallet_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LedgerAccount" (
    "id" UUID NOT NULL,
    "userId" UUID,
    "walletId" UUID,
    "accountType" "LedgerAccountType" NOT NULL DEFAULT 'user',
    "currency" TEXT NOT NULL DEFAULT 'BNT',
    "available" DECIMAL(38,18) NOT NULL DEFAULT 0,
    "pending" DECIMAL(38,18) NOT NULL DEFAULT 0,
    "locked" DECIMAL(38,18) NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "LedgerAccount_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LedgerEntry" (
    "id" UUID NOT NULL,
    "debitAccountId" UUID NOT NULL,
    "creditAccountId" UUID NOT NULL,
    "amount" DECIMAL(38,18) NOT NULL,
    "feeAmount" DECIMAL(38,18) NOT NULL DEFAULT 0,
    "reason" "LedgerReason" NOT NULL,
    "idempotencyKey" TEXT NOT NULL,
    "referenceId" TEXT,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "LedgerEntry_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OnchainDeposit" (
    "id" UUID NOT NULL,
    "walletId" UUID NOT NULL,
    "fromAddress" TEXT NOT NULL,
    "toAddress" TEXT NOT NULL,
    "amount" DECIMAL(38,18) NOT NULL,
    "txHash" TEXT NOT NULL,
    "logIndex" INTEGER NOT NULL,
    "blockNumber" BIGINT NOT NULL,
    "confirmations" INTEGER NOT NULL DEFAULT 0,
    "status" "OnchainDepositStatus" NOT NULL DEFAULT 'detected',
    "creditedLedgerEntryId" UUID,
    "sweepJobId" UUID,
    "idempotencyKey" TEXT NOT NULL,
    "detectedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "creditedAt" TIMESTAMP(3),
    "sweptAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "OnchainDeposit_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SweepJob" (
    "id" UUID NOT NULL,
    "walletId" UUID NOT NULL,
    "fromAddress" TEXT NOT NULL,
    "toAddress" TEXT NOT NULL,
    "amount" DECIMAL(38,18) NOT NULL,
    "status" "SweepJobStatus" NOT NULL DEFAULT 'queued',
    "attemptCount" INTEGER NOT NULL DEFAULT 0,
    "txHash" TEXT,
    "idempotencyKey" TEXT NOT NULL,
    "failureReason" TEXT,
    "scheduledAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "startedAt" TIMESTAMP(3),
    "finishedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SweepJob_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WithdrawalRequest" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "walletId" UUID NOT NULL,
    "toAddress" TEXT NOT NULL,
    "amount" DECIMAL(38,18) NOT NULL,
    "feeAmount" DECIMAL(38,18) NOT NULL DEFAULT 0,
    "netAmount" DECIMAL(38,18) NOT NULL,
    "status" "WithdrawalStatus" NOT NULL DEFAULT 'requested',
    "reason" TEXT NOT NULL,
    "rejectReason" TEXT,
    "idempotencyKey" TEXT NOT NULL,
    "broadcastTxHash" TEXT,
    "confirmations" INTEGER NOT NULL DEFAULT 0,
    "requestedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reviewedBy" UUID,
    "reviewedAt" TIMESTAMP(3),
    "broadcastAt" TIMESTAMP(3),
    "confirmedAt" TIMESTAMP(3),
    "failedAt" TIMESTAMP(3),
    "failureReason" TEXT,
    "holdLedgerEntryId" UUID,
    "finalizeLedgerEntryId" UUID,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "WithdrawalRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "KycProfile" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "status" "KycStatus" NOT NULL DEFAULT 'not_submitted',
    "tier" TEXT NOT NULL DEFAULT 'basic',
    "country" TEXT,
    "fullName" TEXT,
    "documentType" TEXT,
    "documentNumberLast4" TEXT,
    "documentUrl" TEXT,
    "submittedAt" TIMESTAMP(3),
    "reviewedBy" UUID,
    "reviewedAt" TIMESTAMP(3),
    "reviewNote" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "KycProfile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RiskLimit" (
    "id" UUID NOT NULL,
    "tier" TEXT NOT NULL,
    "description" TEXT,
    "requiresKyc" BOOLEAN NOT NULL DEFAULT false,
    "maxWithdrawalPerTx" DECIMAL(38,18) NOT NULL,
    "maxWithdrawalPerDay" DECIMAL(38,18) NOT NULL,
    "maxInternalTransferPerDay" DECIMAL(38,18) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "RiskLimit_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WalletFeeConfig" (
    "id" UUID NOT NULL,
    "key" TEXT NOT NULL,
    "flatFee" DECIMAL(38,18) NOT NULL DEFAULT 0,
    "percentFee" DECIMAL(10,6) NOT NULL DEFAULT 0,
    "minFee" DECIMAL(38,18) NOT NULL DEFAULT 0,
    "maxFee" DECIMAL(38,18),
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "WalletFeeConfig_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "UserWallet_userId_key" ON "UserWallet"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "UserWallet_providerWalletId_key" ON "UserWallet"("providerWalletId");

-- CreateIndex
CREATE UNIQUE INDEX "UserWallet_address_key" ON "UserWallet"("address");

-- CreateIndex
CREATE INDEX "UserWallet_status_createdAt_idx" ON "UserWallet"("status", "createdAt");

-- CreateIndex
CREATE INDEX "UserWallet_chainEnvironment_status_createdAt_idx" ON "UserWallet"("chainEnvironment", "status", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "LedgerAccount_walletId_key" ON "LedgerAccount"("walletId");

-- CreateIndex
CREATE INDEX "LedgerAccount_accountType_currency_idx" ON "LedgerAccount"("accountType", "currency");

-- CreateIndex
CREATE INDEX "LedgerAccount_userId_currency_idx" ON "LedgerAccount"("userId", "currency");

-- CreateIndex
CREATE UNIQUE INDEX "LedgerAccount_userId_accountType_currency_key" ON "LedgerAccount"("userId", "accountType", "currency");

-- CreateIndex
CREATE UNIQUE INDEX "LedgerEntry_idempotencyKey_key" ON "LedgerEntry"("idempotencyKey");

-- CreateIndex
CREATE INDEX "LedgerEntry_reason_createdAt_idx" ON "LedgerEntry"("reason", "createdAt");

-- CreateIndex
CREATE INDEX "LedgerEntry_debitAccountId_createdAt_idx" ON "LedgerEntry"("debitAccountId", "createdAt");

-- CreateIndex
CREATE INDEX "LedgerEntry_creditAccountId_createdAt_idx" ON "LedgerEntry"("creditAccountId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "OnchainDeposit_creditedLedgerEntryId_key" ON "OnchainDeposit"("creditedLedgerEntryId");

-- CreateIndex
CREATE UNIQUE INDEX "OnchainDeposit_sweepJobId_key" ON "OnchainDeposit"("sweepJobId");

-- CreateIndex
CREATE UNIQUE INDEX "OnchainDeposit_idempotencyKey_key" ON "OnchainDeposit"("idempotencyKey");

-- CreateIndex
CREATE INDEX "OnchainDeposit_status_createdAt_idx" ON "OnchainDeposit"("status", "createdAt");

-- CreateIndex
CREATE INDEX "OnchainDeposit_walletId_status_createdAt_idx" ON "OnchainDeposit"("walletId", "status", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "OnchainDeposit_txHash_logIndex_key" ON "OnchainDeposit"("txHash", "logIndex");

-- CreateIndex
CREATE UNIQUE INDEX "SweepJob_txHash_key" ON "SweepJob"("txHash");

-- CreateIndex
CREATE UNIQUE INDEX "SweepJob_idempotencyKey_key" ON "SweepJob"("idempotencyKey");

-- CreateIndex
CREATE INDEX "SweepJob_status_createdAt_idx" ON "SweepJob"("status", "createdAt");

-- CreateIndex
CREATE INDEX "SweepJob_walletId_status_createdAt_idx" ON "SweepJob"("walletId", "status", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "WithdrawalRequest_idempotencyKey_key" ON "WithdrawalRequest"("idempotencyKey");

-- CreateIndex
CREATE UNIQUE INDEX "WithdrawalRequest_holdLedgerEntryId_key" ON "WithdrawalRequest"("holdLedgerEntryId");

-- CreateIndex
CREATE UNIQUE INDEX "WithdrawalRequest_finalizeLedgerEntryId_key" ON "WithdrawalRequest"("finalizeLedgerEntryId");

-- CreateIndex
CREATE INDEX "WithdrawalRequest_status_createdAt_idx" ON "WithdrawalRequest"("status", "createdAt");

-- CreateIndex
CREATE INDEX "WithdrawalRequest_userId_createdAt_idx" ON "WithdrawalRequest"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "WithdrawalRequest_walletId_status_createdAt_idx" ON "WithdrawalRequest"("walletId", "status", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "KycProfile_userId_key" ON "KycProfile"("userId");

-- CreateIndex
CREATE INDEX "KycProfile_status_createdAt_idx" ON "KycProfile"("status", "createdAt");

-- CreateIndex
CREATE INDEX "KycProfile_tier_idx" ON "KycProfile"("tier");

-- CreateIndex
CREATE UNIQUE INDEX "RiskLimit_tier_key" ON "RiskLimit"("tier");

-- CreateIndex
CREATE UNIQUE INDEX "WalletFeeConfig_key_key" ON "WalletFeeConfig"("key");

-- AddForeignKey
ALTER TABLE "UserWallet" ADD CONSTRAINT "UserWallet_userId_fkey" FOREIGN KEY ("userId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LedgerAccount" ADD CONSTRAINT "LedgerAccount_userId_fkey" FOREIGN KEY ("userId") REFERENCES "Profile"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LedgerAccount" ADD CONSTRAINT "LedgerAccount_walletId_fkey" FOREIGN KEY ("walletId") REFERENCES "UserWallet"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LedgerEntry" ADD CONSTRAINT "LedgerEntry_debitAccountId_fkey" FOREIGN KEY ("debitAccountId") REFERENCES "LedgerAccount"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LedgerEntry" ADD CONSTRAINT "LedgerEntry_creditAccountId_fkey" FOREIGN KEY ("creditAccountId") REFERENCES "LedgerAccount"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OnchainDeposit" ADD CONSTRAINT "OnchainDeposit_walletId_fkey" FOREIGN KEY ("walletId") REFERENCES "UserWallet"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OnchainDeposit" ADD CONSTRAINT "OnchainDeposit_creditedLedgerEntryId_fkey" FOREIGN KEY ("creditedLedgerEntryId") REFERENCES "LedgerEntry"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OnchainDeposit" ADD CONSTRAINT "OnchainDeposit_sweepJobId_fkey" FOREIGN KEY ("sweepJobId") REFERENCES "SweepJob"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SweepJob" ADD CONSTRAINT "SweepJob_walletId_fkey" FOREIGN KEY ("walletId") REFERENCES "UserWallet"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WithdrawalRequest" ADD CONSTRAINT "WithdrawalRequest_userId_fkey" FOREIGN KEY ("userId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WithdrawalRequest" ADD CONSTRAINT "WithdrawalRequest_reviewedBy_fkey" FOREIGN KEY ("reviewedBy") REFERENCES "Profile"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WithdrawalRequest" ADD CONSTRAINT "WithdrawalRequest_walletId_fkey" FOREIGN KEY ("walletId") REFERENCES "UserWallet"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WithdrawalRequest" ADD CONSTRAINT "WithdrawalRequest_holdLedgerEntryId_fkey" FOREIGN KEY ("holdLedgerEntryId") REFERENCES "LedgerEntry"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WithdrawalRequest" ADD CONSTRAINT "WithdrawalRequest_finalizeLedgerEntryId_fkey" FOREIGN KEY ("finalizeLedgerEntryId") REFERENCES "LedgerEntry"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "KycProfile" ADD CONSTRAINT "KycProfile_userId_fkey" FOREIGN KEY ("userId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "KycProfile" ADD CONSTRAINT "KycProfile_reviewedBy_fkey" FOREIGN KEY ("reviewedBy") REFERENCES "Profile"("id") ON DELETE SET NULL ON UPDATE CASCADE;

