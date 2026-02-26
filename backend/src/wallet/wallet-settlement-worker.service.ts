import {
  Inject,
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import {
  ChainEnvironment,
  LedgerReason,
  OnchainDepositStatus,
  Prisma,
  SweepJobStatus,
  WalletStatus,
  WithdrawalStatus,
} from '@prisma/client';
import { createPublicClient, http, parseUnits, type PublicClient } from 'viem';
import { AuditLogService } from '../audit-log/audit-log.service';
import { FinancialAuditActions } from '../common/constants/financial-audit-actions';
import {
  createDeterministicIdempotencyKey,
  normalizeIdempotencyKey,
} from '../common/utils/idempotency.util';
import { PrismaService } from '../prisma/prisma.service';
import {
  CUSTODY_ADAPTER,
  type CustodyAdapter,
} from './custody/custody.adapter';
import {
  WalletConfigService,
  type WalletDepositNetworkConfig,
} from './wallet-config.service';
import { DECIMAL_ZERO, toDecimalString } from './types/decimal';

@Injectable()
export class WalletSettlementWorkerService
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(WalletSettlementWorkerService.name);
  private readonly clients = new Map<ChainEnvironment, PublicClient>();

  private intervalHandle: NodeJS.Timeout | null = null;
  private isTickRunning = false;

  constructor(
    private readonly prisma: PrismaService,
    private readonly walletConfigService: WalletConfigService,
    private readonly auditLogService: AuditLogService,
    @Inject(CUSTODY_ADAPTER) private readonly custodyAdapter: CustodyAdapter,
  ) {}

  onModuleInit(): void {
    const intervalMs = Math.min(
      this.walletConfigService.depositPollIntervalMs,
      this.walletConfigService.withdrawalPollIntervalMs,
    );

    this.intervalHandle = setInterval(() => {
      void this.tick();
    }, intervalMs);

    void this.tick();
    this.logger.log(
      `Wallet settlement worker started (interval=${intervalMs}ms)`,
    );
  }

  onModuleDestroy(): void {
    if (this.intervalHandle) {
      clearInterval(this.intervalHandle);
      this.intervalHandle = null;
    }
  }

  private async tick(): Promise<void> {
    if (this.isTickRunning) {
      return;
    }

    this.isTickRunning = true;
    try {
      if (!this.walletConfigService.walletEnabled) {
        return;
      }

      if (this.walletConfigService.depositsEnabled) {
        await this.queueDepositSweeps();
        await this.processSweepJobs();
      }

      if (this.walletConfigService.withdrawalsEnabled) {
        await this.processApprovedWithdrawals();
        await this.processBroadcastingWithdrawals();
      }
    } catch (error) {
      this.logger.error(
        `Wallet settlement tick failed: ${this.errorMessage(error)}`,
      );
    } finally {
      this.isTickRunning = false;
    }
  }

  private async queueDepositSweeps(): Promise<void> {
    const candidates = await this.prisma.onchainDeposit.findMany({
      where: {
        status: OnchainDepositStatus.credited,
        sweepJobId: null,
        wallet: {
          status: {
            not: WalletStatus.disabled,
          },
        },
      },
      include: {
        wallet: {
          select: {
            id: true,
            userId: true,
            address: true,
            chainEnvironment: true,
            providerWalletId: true,
          },
        },
      },
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
      take: 100,
    });

    for (const candidate of candidates) {
      const sweepAddress =
        this.walletConfigService.getTreasurySweepAddressForEnvironment(
          candidate.wallet.chainEnvironment,
        );
      if (!sweepAddress) {
        continue;
      }

      if (!candidate.wallet.address || !candidate.wallet.providerWalletId) {
        continue;
      }

      if (
        candidate.wallet.address.toLowerCase() === sweepAddress.toLowerCase()
      ) {
        const updated = await this.prisma.onchainDeposit.updateMany({
          where: {
            id: candidate.id,
            status: OnchainDepositStatus.credited,
            sweepJobId: null,
          },
          data: {
            status: OnchainDepositStatus.swept,
            sweptAt: new Date(),
          },
        });
        if (updated.count > 0) {
          await this.auditLogService.create({
            actorId: candidate.wallet.userId,
            action: FinancialAuditActions.DepositSwept,
            resourceType: 'onchain_deposit',
            resourceId: candidate.id,
            metadata: {
              txHash: candidate.txHash,
              mode: 'already_in_treasury',
            },
          });
        }
        continue;
      }

      await this.queueSweepForDeposit(candidate.id, sweepAddress);
    }
  }

  private async queueSweepForDeposit(
    depositId: string,
    sweepAddress: `0x${string}`,
  ): Promise<void> {
    const result = await this.prisma.$transaction(
      async (tx) => {
        const deposit = await tx.onchainDeposit.findUnique({
          where: { id: depositId },
          include: {
            wallet: {
              select: {
                id: true,
                userId: true,
                address: true,
                providerWalletId: true,
              },
            },
          },
        });

        if (!deposit) {
          return null;
        }

        if (
          deposit.status !== OnchainDepositStatus.credited ||
          deposit.sweepJobId
        ) {
          return null;
        }

        if (!deposit.wallet.address || !deposit.wallet.providerWalletId) {
          return null;
        }

        const idempotencyKey = createDeterministicIdempotencyKey(
          'deposit-sweep',
          deposit.id,
          deposit.txHash,
          deposit.logIndex,
        );

        let job = await tx.sweepJob.findUnique({
          where: { idempotencyKey },
        });

        if (!job) {
          job = await tx.sweepJob.create({
            data: {
              walletId: deposit.wallet.id,
              asset: deposit.asset,
              assetKind: deposit.assetKind,
              tokenAddress: deposit.tokenAddress,
              fromAddress: deposit.wallet.address,
              toAddress: sweepAddress,
              amount: deposit.amount,
              status: SweepJobStatus.queued,
              idempotencyKey,
            },
          });
        }

        await tx.onchainDeposit.update({
          where: { id: deposit.id },
          data: {
            sweepJobId: job.id,
          },
        });

        return {
          jobId: job.id,
          userId: deposit.wallet.userId,
          amount: deposit.amount.toString(),
        };
      },
      {
        isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
      },
    );

    if (!result) {
      return;
    }

    await this.auditLogService.create({
      actorId: result.userId,
      action: FinancialAuditActions.DepositSweepQueued,
      resourceType: 'sweep_job',
      resourceId: result.jobId,
      metadata: {
        amount: result.amount,
      },
    });
  }

  private async processSweepJobs(): Promise<void> {
    const jobs = await this.prisma.sweepJob.findMany({
      where: {
        status: {
          in: [SweepJobStatus.queued, SweepJobStatus.failed],
        },
      },
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
      take: 20,
    });

    for (const job of jobs) {
      await this.processSweepJob(job.id);
    }
  }

  private async processSweepJob(jobId: string): Promise<void> {
    const claimed = await this.prisma.sweepJob.updateMany({
      where: {
        id: jobId,
        status: {
          in: [SweepJobStatus.queued, SweepJobStatus.failed],
        },
      },
      data: {
        status: SweepJobStatus.processing,
        attemptCount: {
          increment: 1,
        },
        startedAt: new Date(),
        failureReason: null,
      },
    });

    if (claimed.count === 0) {
      return;
    }

    const job = await this.prisma.sweepJob.findUnique({
      where: { id: jobId },
      include: {
        wallet: {
          select: {
            id: true,
            userId: true,
            chainEnvironment: true,
            providerWalletId: true,
          },
        },
        deposit: {
          select: {
            id: true,
            txHash: true,
            logIndex: true,
          },
        },
      },
    });

    if (!job) {
      return;
    }

    const network = this.walletConfigService.getDepositNetworkConfig(
      job.wallet.chainEnvironment,
      job.asset,
    );
    if (!network) {
      await this.failSweepJob(
        job.id,
        `Missing network config for ${job.wallet.chainEnvironment}`,
      );
      return;
    }

    if (!job.wallet.providerWalletId) {
      await this.failSweepJob(job.id, 'Wallet has no provider wallet ID');
      return;
    }

    try {
      const amountWei = parseUnits(
        toDecimalString(job.amount),
        network.decimals,
      ).toString();
      const transfer =
        network.assetKind === 'native'
          ? await this.custodyAdapter.transferNative({
              idempotencyKey: createDeterministicIdempotencyKey(
                'deposit-sweep-transfer',
                job.id,
                job.idempotencyKey,
              ),
              chainId: network.chainId,
              fromProviderWalletId: job.wallet.providerWalletId,
              toAddress: job.toAddress as `0x${string}`,
              amountWei,
              metadata: {
                sweepJobId: job.id,
                depositId: job.deposit?.id ?? null,
                asset: job.asset,
              },
            })
          : await this.custodyAdapter.transferToken({
              idempotencyKey: createDeterministicIdempotencyKey(
                'deposit-sweep-transfer',
                job.id,
                job.idempotencyKey,
              ),
              chainId: network.chainId,
              tokenAddress: network.tokenAddress as `0x${string}`,
              fromProviderWalletId: job.wallet.providerWalletId,
              toAddress: job.toAddress as `0x${string}`,
              amountWei,
              metadata: {
                sweepJobId: job.id,
                depositId: job.deposit?.id ?? null,
                asset: job.asset,
              },
            });

      const updated = await this.prisma.$transaction(async (tx) => {
        const fresh = await tx.sweepJob.findUnique({
          where: { id: job.id },
          include: {
            wallet: {
              select: {
                userId: true,
              },
            },
            deposit: {
              select: {
                id: true,
              },
            },
          },
        });

        if (!fresh || fresh.status !== SweepJobStatus.processing) {
          return null;
        }

        const completed = await tx.sweepJob.update({
          where: { id: fresh.id },
          data: {
            status: SweepJobStatus.completed,
            txHash: transfer.txHash,
            finishedAt: new Date(),
            failureReason: null,
          },
        });

        if (fresh.deposit?.id) {
          await tx.onchainDeposit.update({
            where: { id: fresh.deposit.id },
            data: {
              status: OnchainDepositStatus.swept,
              sweptAt: new Date(),
            },
          });
        }

        return {
          userId: fresh.wallet.userId,
          sweepJobId: completed.id,
          txHash: transfer.txHash,
          depositId: fresh.deposit?.id ?? null,
          simulated: transfer.simulated,
        };
      });

      if (updated) {
        await this.auditLogService.create({
          actorId: updated.userId,
          action: FinancialAuditActions.DepositSwept,
          resourceType: 'sweep_job',
          resourceId: updated.sweepJobId,
          metadata: {
            txHash: updated.txHash,
            depositId: updated.depositId,
            simulated: updated.simulated,
          },
        });
      }
    } catch (error) {
      await this.failSweepJob(job.id, this.errorMessage(error));
    }
  }

  private async failSweepJob(jobId: string, reason: string): Promise<void> {
    await this.prisma.sweepJob.updateMany({
      where: {
        id: jobId,
        status: SweepJobStatus.processing,
      },
      data: {
        status: SweepJobStatus.failed,
        failureReason: reason.slice(0, 500),
        finishedAt: new Date(),
      },
    });
  }

  private async processApprovedWithdrawals(): Promise<void> {
    const withdrawals = await this.prisma.withdrawalRequest.findMany({
      where: {
        status: WithdrawalStatus.approved,
        wallet: {
          status: {
            not: WalletStatus.disabled,
          },
        },
      },
      orderBy: [{ reviewedAt: 'asc' }, { createdAt: 'asc' }, { id: 'asc' }],
      take: 20,
    });

    for (const withdrawal of withdrawals) {
      await this.broadcastApprovedWithdrawal(withdrawal.id);
    }
  }

  private async broadcastApprovedWithdrawal(
    withdrawalId: string,
  ): Promise<void> {
    const claim = await this.prisma.withdrawalRequest.updateMany({
      where: {
        id: withdrawalId,
        status: WithdrawalStatus.approved,
      },
      data: {
        status: WithdrawalStatus.broadcasting,
        broadcastAt: new Date(),
        failureReason: null,
      },
    });

    if (claim.count === 0) {
      return;
    }

    const withdrawal = await this.prisma.withdrawalRequest.findUnique({
      where: { id: withdrawalId },
      include: {
        wallet: {
          select: {
            chainEnvironment: true,
            status: true,
          },
        },
      },
    });
    if (!withdrawal) {
      return;
    }

    if (withdrawal.wallet.status === WalletStatus.disabled) {
      await this.revertWithdrawal(
        withdrawalId,
        'Wallet is disabled for this account',
      );
      return;
    }

    const network = this.walletConfigService.getDepositNetworkConfig(
      withdrawal.wallet.chainEnvironment,
      withdrawal.asset,
    );
    if (!network) {
      await this.revertWithdrawal(
        withdrawalId,
        `Missing network config for ${withdrawal.wallet.chainEnvironment}`,
      );
      return;
    }

    const treasuryWalletId =
      this.walletConfigService.getTreasuryWalletIdForEnvironment(
        withdrawal.wallet.chainEnvironment,
      );
    if (!treasuryWalletId) {
      await this.revertWithdrawal(
        withdrawalId,
        `Missing treasury wallet ID for ${withdrawal.wallet.chainEnvironment}`,
      );
      return;
    }

    try {
      const amountWei = parseUnits(
        toDecimalString(withdrawal.netAmount),
        network.decimals,
      ).toString();
      const transfer =
        network.assetKind === 'native'
          ? await this.custodyAdapter.transferNative({
              idempotencyKey: createDeterministicIdempotencyKey(
                'withdrawal-broadcast',
                withdrawal.id,
                withdrawal.idempotencyKey,
              ),
              chainId: network.chainId,
              fromProviderWalletId: treasuryWalletId,
              toAddress: withdrawal.toAddress as `0x${string}`,
              amountWei,
              metadata: {
                withdrawalId: withdrawal.id,
                userId: withdrawal.userId,
                asset: withdrawal.asset,
                netAmount: toDecimalString(withdrawal.netAmount),
                feeAmount: toDecimalString(withdrawal.feeAmount),
              },
            })
          : await this.custodyAdapter.transferToken({
              idempotencyKey: createDeterministicIdempotencyKey(
                'withdrawal-broadcast',
                withdrawal.id,
                withdrawal.idempotencyKey,
              ),
              chainId: network.chainId,
              tokenAddress: network.tokenAddress as `0x${string}`,
              fromProviderWalletId: treasuryWalletId,
              toAddress: withdrawal.toAddress as `0x${string}`,
              amountWei,
              metadata: {
                withdrawalId: withdrawal.id,
                userId: withdrawal.userId,
                asset: withdrawal.asset,
                netAmount: toDecimalString(withdrawal.netAmount),
                feeAmount: toDecimalString(withdrawal.feeAmount),
              },
            });

      await this.prisma.withdrawalRequest.update({
        where: { id: withdrawal.id },
        data: {
          status: WithdrawalStatus.broadcasting,
          broadcastTxHash: transfer.txHash,
          failureReason: null,
        },
      });

      await this.auditLogService.create({
        actorId: withdrawal.reviewedBy ?? undefined,
        action: FinancialAuditActions.WithdrawalBroadcasted,
        resourceType: 'withdrawal_request',
        resourceId: withdrawal.id,
        metadata: {
          txHash: transfer.txHash,
          simulated: transfer.simulated,
        },
      });

      if (transfer.simulated) {
        const required =
          this.walletConfigService.getWithdrawalConfirmationsForEnvironment(
            withdrawal.wallet.chainEnvironment,
          );
        await this.finalizeConfirmedWithdrawal(
          withdrawal.id,
          transfer.txHash,
          required,
        );
      }
    } catch (error) {
      await this.revertWithdrawal(
        withdrawalId,
        `Broadcast failed: ${this.errorMessage(error)}`,
      );
    }
  }

  private async processBroadcastingWithdrawals(): Promise<void> {
    const withdrawals = await this.prisma.withdrawalRequest.findMany({
      where: {
        status: WithdrawalStatus.broadcasting,
        broadcastTxHash: {
          not: null,
        },
        wallet: {
          status: {
            not: WalletStatus.disabled,
          },
        },
      },
      include: {
        wallet: {
          select: {
            chainEnvironment: true,
            status: true,
          },
        },
      },
      orderBy: [{ broadcastAt: 'asc' }, { id: 'asc' }],
      take: 30,
    });

    for (const withdrawal of withdrawals) {
      await this.processBroadcastingWithdrawal(withdrawal.id);
    }
  }

  private async processBroadcastingWithdrawal(
    withdrawalId: string,
  ): Promise<void> {
    const withdrawal = await this.prisma.withdrawalRequest.findUnique({
      where: { id: withdrawalId },
      include: {
        wallet: {
          select: {
            chainEnvironment: true,
            status: true,
          },
        },
      },
    });

    if (
      !withdrawal ||
      withdrawal.status !== WithdrawalStatus.broadcasting ||
      !withdrawal.broadcastTxHash
    ) {
      return;
    }

    if (withdrawal.wallet.status === WalletStatus.disabled) {
      await this.revertWithdrawal(
        withdrawal.id,
        'Wallet is disabled for this account',
      );
      return;
    }

    const network = this.walletConfigService.getDepositNetworkConfig(
      withdrawal.wallet.chainEnvironment,
      withdrawal.asset,
    );
    if (!network) {
      return;
    }

    const txHash = this.normalizeHash(withdrawal.broadcastTxHash);
    if (!txHash) {
      await this.revertWithdrawal(
        withdrawal.id,
        `Invalid broadcast hash: ${withdrawal.broadcastTxHash}`,
      );
      return;
    }

    const client = this.getClient(network);

    let receipt: Awaited<ReturnType<PublicClient['getTransactionReceipt']>>;
    try {
      receipt = await client.getTransactionReceipt({ hash: txHash });
    } catch {
      return;
    }

    const currentBlock = await client.getBlockNumber();
    const confirmations = this.computeConfirmations(
      currentBlock,
      receipt.blockNumber,
    );
    const required =
      this.walletConfigService.getWithdrawalConfirmationsForEnvironment(
        withdrawal.wallet.chainEnvironment,
      );

    if (receipt.status !== 'success') {
      await this.revertWithdrawal(
        withdrawal.id,
        `On-chain withdrawal failed: ${withdrawal.broadcastTxHash}`,
        confirmations,
      );
      return;
    }

    if (confirmations < required) {
      await this.prisma.withdrawalRequest.update({
        where: { id: withdrawal.id },
        data: {
          confirmations,
        },
      });
      return;
    }

    await this.finalizeConfirmedWithdrawal(
      withdrawal.id,
      withdrawal.broadcastTxHash,
      confirmations,
    );
  }

  private async finalizeConfirmedWithdrawal(
    withdrawalId: string,
    txHash: string,
    confirmations: number,
  ): Promise<void> {
    const result = await this.prisma.$transaction(
      async (tx) => {
        const withdrawal = await tx.withdrawalRequest.findUnique({
          where: { id: withdrawalId },
        });
        if (!withdrawal) {
          return null;
        }

        if (withdrawal.status === WithdrawalStatus.confirmed) {
          return {
            id: withdrawal.id,
            userId: withdrawal.userId,
            txHash: withdrawal.broadcastTxHash ?? txHash,
            confirmations: withdrawal.confirmations,
          };
        }

        if (withdrawal.status !== WithdrawalStatus.broadcasting) {
          return null;
        }

        const [userAccount, holdAccount] = await Promise.all([
          tx.ledgerAccount.findUnique({
            where: {
              userId_accountType_currency: {
                userId: withdrawal.userId,
                accountType: 'user',
                currency: withdrawal.asset,
              },
            },
          }),
          tx.ledgerAccount.findUnique({
            where: {
              userId_accountType_currency: {
                userId: withdrawal.userId,
                accountType: 'hold',
                currency: withdrawal.asset,
              },
            },
          }),
        ]);

        if (!userAccount || !holdAccount) {
          throw new Error(
            'User ledger accounts are missing for withdrawal finalize',
          );
        }

        const finalizeKey =
          normalizeIdempotencyKey(`${withdrawal.idempotencyKey}:finalize`) ??
          `${withdrawal.idempotencyKey}:finalize`;

        let finalizeEntry = await tx.ledgerEntry.findUnique({
          where: {
            idempotencyKey: finalizeKey,
          },
        });

        if (!finalizeEntry) {
          if (holdAccount.available.lt(withdrawal.amount)) {
            throw new Error('Hold balance is lower than withdrawal amount');
          }
          if (userAccount.locked.lt(withdrawal.amount)) {
            throw new Error('Locked balance is lower than withdrawal amount');
          }

          let treasuryAccount = await tx.ledgerAccount.findFirst({
            where: {
              userId: null,
              accountType: 'treasury',
              currency: withdrawal.asset,
            },
          });
          if (!treasuryAccount) {
            treasuryAccount = await tx.ledgerAccount.create({
              data: {
                userId: null,
                accountType: 'treasury',
                currency: withdrawal.asset,
              },
            });
          }

          await tx.ledgerAccount.update({
            where: { id: holdAccount.id },
            data: {
              available: holdAccount.available.sub(withdrawal.amount),
            },
          });

          await tx.ledgerAccount.update({
            where: { id: userAccount.id },
            data: {
              locked: userAccount.locked.sub(withdrawal.amount),
            },
          });

          await tx.ledgerAccount.update({
            where: { id: treasuryAccount.id },
            data: {
              available: treasuryAccount.available.add(withdrawal.amount),
            },
          });

          finalizeEntry = await tx.ledgerEntry.create({
            data: {
              debitAccountId: holdAccount.id,
              creditAccountId: treasuryAccount.id,
              amount: withdrawal.amount,
              reason: LedgerReason.withdrawal_finalize,
              idempotencyKey: finalizeKey,
              metadata: {
                withdrawalId: withdrawal.id,
                txHash,
                asset: withdrawal.asset,
                netAmount: toDecimalString(withdrawal.netAmount),
                feeAmount: toDecimalString(withdrawal.feeAmount),
              },
            },
          });

          if (withdrawal.feeAmount.gt(DECIMAL_ZERO)) {
            let feeAccount = await tx.ledgerAccount.findFirst({
              where: {
                userId: null,
                accountType: 'fee',
                currency: withdrawal.asset,
              },
            });
            if (!feeAccount) {
              feeAccount = await tx.ledgerAccount.create({
                data: {
                  userId: null,
                  accountType: 'fee',
                  currency: withdrawal.asset,
                },
              });
            }

            const feeKey =
              normalizeIdempotencyKey(`${withdrawal.idempotencyKey}:fee`) ??
              `${withdrawal.idempotencyKey}:fee`;

            await tx.ledgerAccount.update({
              where: { id: treasuryAccount.id },
              data: {
                available: treasuryAccount.available
                  .add(withdrawal.amount)
                  .sub(withdrawal.feeAmount),
              },
            });

            await tx.ledgerAccount.update({
              where: { id: feeAccount.id },
              data: {
                available: feeAccount.available.add(withdrawal.feeAmount),
              },
            });

            await tx.ledgerEntry.upsert({
              where: {
                idempotencyKey: feeKey,
              },
              update: {},
              create: {
                debitAccountId: treasuryAccount.id,
                creditAccountId: feeAccount.id,
                amount: withdrawal.feeAmount,
                reason: LedgerReason.withdrawal_fee,
                idempotencyKey: feeKey,
                metadata: {
                  withdrawalId: withdrawal.id,
                  asset: withdrawal.asset,
                },
              },
            });
          }
        }

        const confirmed = await tx.withdrawalRequest.update({
          where: { id: withdrawal.id },
          data: {
            status: WithdrawalStatus.confirmed,
            broadcastTxHash: txHash,
            confirmations,
            confirmedAt: withdrawal.confirmedAt ?? new Date(),
            failureReason: null,
            finalizeLedgerEntryId: finalizeEntry.id,
          },
        });

        return {
          id: confirmed.id,
          userId: confirmed.userId,
          txHash: confirmed.broadcastTxHash ?? txHash,
          confirmations: confirmed.confirmations,
        };
      },
      {
        isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
      },
    );

    if (!result) {
      return;
    }

    await this.auditLogService.create({
      actorId: result.userId,
      action: FinancialAuditActions.WithdrawalConfirmed,
      resourceType: 'withdrawal_request',
      resourceId: result.id,
      metadata: {
        txHash: result.txHash,
        confirmations: result.confirmations,
      },
    });
  }

  private async revertWithdrawal(
    withdrawalId: string,
    reason: string,
    confirmations?: number,
  ): Promise<void> {
    const result = await this.prisma.$transaction(
      async (tx) => {
        const withdrawal = await tx.withdrawalRequest.findUnique({
          where: { id: withdrawalId },
        });

        if (!withdrawal) {
          return null;
        }

        if (
          withdrawal.status === WithdrawalStatus.confirmed ||
          withdrawal.status === WithdrawalStatus.rejected ||
          withdrawal.status === WithdrawalStatus.reverted
        ) {
          return null;
        }

        const [userAccount, holdAccount] = await Promise.all([
          tx.ledgerAccount.findUnique({
            where: {
              userId_accountType_currency: {
                userId: withdrawal.userId,
                accountType: 'user',
                currency: withdrawal.asset,
              },
            },
          }),
          tx.ledgerAccount.findUnique({
            where: {
              userId_accountType_currency: {
                userId: withdrawal.userId,
                accountType: 'hold',
                currency: withdrawal.asset,
              },
            },
          }),
        ]);

        if (!userAccount || !holdAccount) {
          throw new Error(
            'User ledger accounts are missing for withdrawal revert',
          );
        }

        const revertKey =
          normalizeIdempotencyKey(`${withdrawal.idempotencyKey}:revert`) ??
          `${withdrawal.idempotencyKey}:revert`;

        let revertEntry = await tx.ledgerEntry.findUnique({
          where: {
            idempotencyKey: revertKey,
          },
        });

        if (!revertEntry) {
          if (holdAccount.available.lt(withdrawal.amount)) {
            throw new Error('Hold balance is lower than withdrawal amount');
          }
          if (userAccount.locked.lt(withdrawal.amount)) {
            throw new Error('Locked balance is lower than withdrawal amount');
          }

          await tx.ledgerAccount.update({
            where: { id: userAccount.id },
            data: {
              available: userAccount.available.add(withdrawal.amount),
              locked: userAccount.locked.sub(withdrawal.amount),
            },
          });

          await tx.ledgerAccount.update({
            where: { id: holdAccount.id },
            data: {
              available: holdAccount.available.sub(withdrawal.amount),
            },
          });

          revertEntry = await tx.ledgerEntry.create({
            data: {
              debitAccountId: holdAccount.id,
              creditAccountId: userAccount.id,
              amount: withdrawal.amount,
              reason: LedgerReason.withdrawal_reject_release,
              idempotencyKey: revertKey,
              metadata: {
                withdrawalId: withdrawal.id,
                asset: withdrawal.asset,
                reason,
              },
            },
          });
        }

        const reverted = await tx.withdrawalRequest.update({
          where: { id: withdrawal.id },
          data: {
            status: WithdrawalStatus.reverted,
            failureReason: reason.slice(0, 500),
            rejectReason: reason.slice(0, 500),
            failedAt: new Date(),
            confirmations: confirmations ?? withdrawal.confirmations,
            finalizeLedgerEntryId:
              withdrawal.finalizeLedgerEntryId ?? revertEntry.id,
          },
        });

        return {
          id: reverted.id,
          userId: reverted.userId,
          reason,
        };
      },
      {
        isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
      },
    );

    if (!result) {
      return;
    }

    await this.auditLogService.create({
      actorId: result.userId,
      action: FinancialAuditActions.WithdrawalReverted,
      resourceType: 'withdrawal_request',
      resourceId: result.id,
      metadata: {
        reason: result.reason,
      },
    });
  }

  private getClient(network: WalletDepositNetworkConfig): PublicClient {
    const existing = this.clients.get(network.chainEnvironment);
    if (existing) {
      return existing;
    }

    const client = createPublicClient({
      transport: http(network.rpcUrl),
    });
    this.clients.set(network.chainEnvironment, client);
    return client;
  }

  private normalizeHash(value: string): `0x${string}` | null {
    if (!/^0x[a-fA-F0-9]{64}$/.test(value)) {
      return null;
    }
    return value as `0x${string}`;
  }

  private computeConfirmations(headBlock: bigint, txBlock: bigint): number {
    if (headBlock < txBlock) {
      return 0;
    }

    const raw = headBlock - txBlock + 1n;
    if (raw > BigInt(Number.MAX_SAFE_INTEGER)) {
      return Number.MAX_SAFE_INTEGER;
    }
    return Number(raw);
  }

  private errorMessage(error: unknown): string {
    if (error instanceof Error) {
      return error.message;
    }
    return String(error);
  }
}
