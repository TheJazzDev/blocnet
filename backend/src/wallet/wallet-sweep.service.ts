import { Inject, Injectable, Logger } from '@nestjs/common';
import {
  OnchainDepositStatus,
  Prisma,
  SweepJobStatus,
  WalletStatus,
} from '@prisma/client';
import { parseUnits } from 'viem';
import { AuditLogService } from '../audit-log/audit-log.service';
import { FinancialAuditActions } from '../common/constants/financial-audit-actions';
import { createDeterministicIdempotencyKey } from '../common/utils/idempotency.util';
import { PrismaService } from '../prisma/prisma.service';
import {
  CUSTODY_ADAPTER,
  type CustodyAdapter,
} from './custody/custody.adapter';
import { toDecimalString } from './types/decimal';
import { WalletConfigService } from './wallet-config.service';

@Injectable()
export class WalletSweepService {
  private readonly logger = new Logger(WalletSweepService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly walletConfigService: WalletConfigService,
    private readonly auditLogService: AuditLogService,
    @Inject(CUSTODY_ADAPTER) private readonly custodyAdapter: CustodyAdapter,
  ) {}

  async queueDepositSweeps(): Promise<void> {
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

  async processSweepJobs(): Promise<void> {
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

  private errorMessage(error: unknown): string {
    if (error instanceof Error) {
      return error.message;
    }
    return String(error);
  }
}
