export const FinancialAuditActions = {
  WalletProvisionQueued: 'wallet.provision.queued',
  WalletProvisionReady: 'wallet.provision.ready',
  WalletProvisionFailed: 'wallet.provision.failed',

  LedgerCredit: 'ledger.credit',
  LedgerDebit: 'ledger.debit',
  LedgerTransferInternal: 'ledger.transfer.internal',

  DepositDetected: 'wallet.deposit.detected',
  DepositCredited: 'wallet.deposit.credited',
  DepositSweepQueued: 'wallet.deposit.sweep.queued',
  DepositSwept: 'wallet.deposit.swept',

  WithdrawalRequested: 'wallet.withdrawal.requested',
  WithdrawalApproved: 'wallet.withdrawal.approved',
  WithdrawalRejected: 'wallet.withdrawal.rejected',
  WithdrawalBroadcasted: 'wallet.withdrawal.broadcasted',
  WithdrawalConfirmed: 'wallet.withdrawal.confirmed',
  WithdrawalReverted: 'wallet.withdrawal.reverted',

  KycSubmitted: 'wallet.kyc.submitted',
  KycReviewed: 'wallet.kyc.reviewed',

  RiskLimitUpdated: 'wallet.risk_limit.updated',
  FeeConfigUpdated: 'wallet.fee_config.updated',
  AssetPriceConfigUpdated: 'wallet.asset_price_config.updated',
} as const;

export type FinancialAuditAction =
  (typeof FinancialAuditActions)[keyof typeof FinancialAuditActions];
