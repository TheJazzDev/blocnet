import { Injectable, Logger } from '@nestjs/common';
import {
  ChainEnvironment,
  LedgerAccountType,
  LedgerReason,
  OnchainDepositStatus,
  Prisma,
  WalletAsset,
  WalletAssetKind,
} from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { FinancialAuditActions } from '../common/constants/financial-audit-actions';
import { createDeterministicIdempotencyKey } from '../common/utils/idempotency.util';
import { PrismaService } from '../prisma/prisma.service';

export type DetectedDepositParams = {
  walletId: string;
  userId: string;
  toAddress: string;
  fromAddress: string;
  txHash: string;
  logIndex: number;
  blockNumber: bigint;
  amount: string;
  confirmations: number;
  chainEnvironment: ChainEnvironment;
  asset: WalletAsset;
  assetKind: WalletAssetKind;
  tokenAddress: string | null;
};

@Injectable()
export class WalletDepositProcessorService {
  private readonly logger = new Logger(WalletDepositProcessorService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async recordDetectedDeposit(params: DetectedDepositParams) {
    const idempotencyKey = createDeterministicIdempotencyKey(
      'deposit',
      params.chainEnvironment,
      params.txHash,
      params.logIndex.toString(),
    );

    const existing = await this.prisma.onchainDeposit.findUnique({
      where: { idempotencyKey },
    });

    if (existing) {
      if (existing.confirmations < params.confirmations) {
        return this.prisma.onchainDeposit.update({
          where: { id: existing.id },
          data: {
            confirmations: params.confirmations,
          },
        });
      }
      return existing;
    }

    const deposit = await this.prisma.onchainDeposit.create({
      data: {
        walletId: params.walletId,
        asset: params.asset,
        assetKind: params.assetKind,
        txHash: params.txHash,
        logIndex: params.logIndex,
        blockNumber: params.blockNumber,
        confirmations: params.confirmations,
        fromAddress: params.fromAddress,
        toAddress: params.toAddress,
        tokenAddress: params.tokenAddress,
        amount: params.amount,
        status: OnchainDepositStatus.detected,
        idempotencyKey,
      },
    });

    this.logger.log(
      `Detected new ${params.asset} deposit: ${params.amount} (tx=${params.txHash})`,
    );

    await this.auditLogService.create({
      actorId: params.userId,
      action: FinancialAuditActions.DepositDetected,
      resourceType: 'onchain_deposit',
      resourceId: deposit.id,
      metadata: {
        asset: params.asset,
        amount: params.amount,
        txHash: params.txHash,
        chainEnvironment: params.chainEnvironment,
      },
    });

    return deposit;
  }

  async creditDetectedDeposit(
    depositId: string,
    confirmationsRequired: number,
    currentBlock: bigint,
  ) {
    // We use a transaction to ensure we don't double-credit
    return this.prisma
      .$transaction(
        async (tx) => {
          const deposit = await tx.onchainDeposit.findUnique({
            where: { id: depositId },
            include: { wallet: true },
          });

          if (!deposit) {
            return null;
          }

          // Update confirmations first
          const confirmations =
            Number(currentBlock) - Number(deposit.blockNumber) + 1;
          if (confirmations > deposit.confirmations) {
            await tx.onchainDeposit.update({
              where: { id: depositId },
              data: { confirmations: confirmations },
            });
          }

          if (deposit.status !== OnchainDepositStatus.detected) {
            return deposit;
          }

          if (confirmations < confirmationsRequired) {
            return deposit;
          }

          // Find user's ledger account
          const ledgerAccount = await tx.ledgerAccount.findUnique({
            where: {
              userId_accountType_currency: {
                userId: deposit.wallet.userId,
                accountType: LedgerAccountType.user,
                currency: deposit.asset,
              },
            },
          });

          if (!ledgerAccount) {
            this.logger.error(
              `Cannot credit deposit ${depositId}: Ledger account not found for user ${deposit.wallet.userId} asset ${deposit.asset}`,
            );
            return deposit;
          }

          // Find system fee/treasury account to debit from (placeholder)
          // In a real system, we'd have a specific "Minting" or "External" account.
          // For now, we will use a Fee Vault account as the source if it exists, or fail.
          const systemAccount = await tx.ledgerAccount.findFirst({
            where: {
              accountType: LedgerAccountType.fee,
              currency: deposit.asset,
            },
          });

          if (!systemAccount) {
            this.logger.error(
              `Cannot credit deposit ${depositId}: System fee account not found for asset ${deposit.asset}`,
            );
            return deposit;
          }

          // Credit the account
          const amountDecimal = new Prisma.Decimal(deposit.amount);
          await tx.ledgerAccount.update({
            where: { id: ledgerAccount.id },
            data: {
              available: { increment: amountDecimal },
            },
          });

          // Create ledger entry
          const ledgerEntry = await tx.ledgerEntry.create({
            data: {
              debitAccountId: systemAccount.id,
              creditAccountId: ledgerAccount.id,
              amount: amountDecimal,
              reason: LedgerReason.deposit_credit,
              idempotencyKey: `deposit:${deposit.id}`,
              metadata: {
                depositId: deposit.id,
                txHash: deposit.txHash,
                fromAddress: deposit.fromAddress,
              },
            },
          });

          // Update deposit status
          const updatedDeposit = await tx.onchainDeposit.update({
            where: { id: depositId },
            data: {
              status: OnchainDepositStatus.credited,
              creditedLedgerEntryId: ledgerEntry.id,
              creditedAt: new Date(),
            },
            include: { wallet: true },
          });

          return updatedDeposit;
        },
        {
          isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
        },
      )
      .then(async (result) => {
        if (result && result.status === OnchainDepositStatus.credited) {
          await this.auditLogService.create({
            actorId: result.wallet.userId,
            action: FinancialAuditActions.DepositCredited,
            resourceType: 'onchain_deposit',
            resourceId: result.id,
            metadata: {
              asset: result.asset,
              amount: result.amount.toString(),
              txHash: result.txHash,
            },
          });

          this.logger.log(
            `Credited ${result.asset} deposit ${result.id} for user ${result.wallet.userId}`,
          );
        }
        return result;
      });
  }
}
