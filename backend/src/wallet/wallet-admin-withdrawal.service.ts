import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { LedgerReason, WithdrawalStatus } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { FinancialAuditActions } from '../common/constants/financial-audit-actions';
import { normalizeIdempotencyKey } from '../common/utils/idempotency.util';
import { normalizePagination } from '../common/utils/pagination.util';
import { PrismaService } from '../prisma/prisma.service';
import { ListWalletAdminWithdrawalsQuery } from './dto/list-wallet-admin-withdrawals.query';
import {
  ReviewWithdrawalDto,
  WithdrawalReviewDecision,
} from './dto/review-withdrawal.dto';
import { toDecimalString } from './types/decimal';

@Injectable()
export class WalletAdminWithdrawalService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async listWithdrawals(query: ListWalletAdminWithdrawalsQuery) {
    const { limit, offset } = normalizePagination(query.offset, query.limit);
    const q = query.q?.trim();
    const uuidRegex =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const isUuid = q ? uuidRegex.test(q) : false;

    const where = {
      ...(query.status ? { status: query.status } : {}),
      ...(q
        ? {
            OR: [
              { toAddress: { contains: q, mode: 'insensitive' as const } },
              {
                broadcastTxHash: { contains: q, mode: 'insensitive' as const },
              },
              ...(isUuid
                ? [{ id: { equals: q } }, { userId: { equals: q } }]
                : []),
              {
                requester: {
                  email: { contains: q, mode: 'insensitive' as const },
                },
              },
              {
                requester: {
                  displayName: { contains: q, mode: 'insensitive' as const },
                },
              },
            ],
          }
        : {}),
    };

    const [rows, total] = await Promise.all([
      this.prisma.withdrawalRequest.findMany({
        where,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip: offset,
        take: limit,
        include: {
          requester: {
            select: {
              id: true,
              email: true,
              displayName: true,
            },
          },
          reviewer: {
            select: {
              id: true,
              email: true,
              displayName: true,
            },
          },
        },
      }),
      this.prisma.withdrawalRequest.count({ where }),
    ]);

    return {
      data: rows.map((row) => ({
        id: row.id,
        status: row.status,
        toAddress: row.toAddress,
        amount: toDecimalString(row.amount),
        feeAmount: toDecimalString(row.feeAmount),
        netAmount: toDecimalString(row.netAmount),
        reason: row.reason,
        rejectReason: row.rejectReason,
        failureReason: row.failureReason,
        broadcastTxHash: row.broadcastTxHash,
        confirmations: row.confirmations,
        requester: row.requester,
        reviewer: row.reviewer,
        requestedAt: row.requestedAt,
        reviewedAt: row.reviewedAt,
        confirmedAt: row.confirmedAt,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      })),
      total,
      limit,
      offset,
    };
  }

  async reviewWithdrawal(
    actorId: string,
    withdrawalId: string,
    dto: ReviewWithdrawalDto,
  ) {
    const withdrawal = await this.prisma.withdrawalRequest.findUnique({
      where: { id: withdrawalId },
      include: {
        requester: true,
      },
    });

    if (!withdrawal) {
      throw new NotFoundException('Withdrawal request not found');
    }

    if (
      withdrawal.status !== WithdrawalStatus.requested &&
      withdrawal.status !== WithdrawalStatus.pending_review
    ) {
      throw new BadRequestException('Withdrawal request is not pending review');
    }

    if (dto.status === WithdrawalReviewDecision.approved) {
      const updated = await this.prisma.withdrawalRequest.update({
        where: { id: withdrawalId },
        data: {
          status: WithdrawalStatus.approved,
          reviewedBy: actorId,
          reviewedAt: new Date(),
          rejectReason: null,
        },
      });

      await this.auditLogService.create({
        actorId,
        action: FinancialAuditActions.WithdrawalApproved,
        resourceType: 'withdrawal_request',
        resourceId: withdrawalId,
        metadata: {
          reason: dto.reason,
        },
      });

      return updated;
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const fresh = await tx.withdrawalRequest.findUnique({
        where: { id: withdrawalId },
      });

      if (!fresh) {
        throw new NotFoundException('Withdrawal request not found');
      }

      const [freshUserAccount, freshHoldAccount] = await Promise.all([
        tx.ledgerAccount.findUnique({
          where: {
            userId_accountType_currency: {
              userId: fresh.userId,
              accountType: 'user',
              currency: 'BNT',
            },
          },
        }),
        tx.ledgerAccount.findUnique({
          where: {
            userId_accountType_currency: {
              userId: fresh.userId,
              accountType: 'hold',
              currency: 'BNT',
            },
          },
        }),
      ]);

      if (!freshUserAccount || !freshHoldAccount) {
        throw new NotFoundException('Ledger accounts not found');
      }

      if (freshHoldAccount.available.lt(fresh.amount)) {
        throw new BadRequestException('Hold balance is lower than withdrawal');
      }

      await tx.ledgerAccount.update({
        where: { id: freshUserAccount.id },
        data: {
          available: freshUserAccount.available.add(fresh.amount),
          locked: freshUserAccount.locked.sub(fresh.amount),
        },
      });

      await tx.ledgerAccount.update({
        where: { id: freshHoldAccount.id },
        data: {
          available: freshHoldAccount.available.sub(fresh.amount),
        },
      });

      const releaseEntry = await tx.ledgerEntry.create({
        data: {
          debitAccountId: freshHoldAccount.id,
          creditAccountId: freshUserAccount.id,
          amount: fresh.amount,
          reason: LedgerReason.withdrawal_reject_release,
          idempotencyKey:
            normalizeIdempotencyKey(`${fresh.idempotencyKey}:reject`) ??
            `${fresh.idempotencyKey}:reject`,
          metadata: {
            withdrawalId: fresh.id,
            reason: dto.reason,
          },
        },
      });

      return tx.withdrawalRequest.update({
        where: { id: withdrawalId },
        data: {
          status: WithdrawalStatus.rejected,
          reviewedBy: actorId,
          reviewedAt: new Date(),
          rejectReason: dto.reason,
          finalizeLedgerEntryId: releaseEntry.id,
        },
      });
    });

    await this.auditLogService.create({
      actorId,
      action: FinancialAuditActions.WithdrawalRejected,
      resourceType: 'withdrawal_request',
      resourceId: withdrawalId,
      metadata: {
        reason: dto.reason,
      },
    });

    return updated;
  }
}
