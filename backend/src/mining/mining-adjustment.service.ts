import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import {
  MiningPointSource,
  Prisma,
  type MiningPointLedger,
} from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { LevelsService } from '../levels/levels.service';
import { PrismaService } from '../prisma/prisma.service';
import { ensureUserTipAccount } from '../tips/tip-ledger.util';
import { BNP_CURRENCY_CODE } from '../tips/tip.constants';
import {
  BNP_ATOMIC_MULTIPLIER,
  InsufficientBnpBalanceError,
  adjustBnpTipAccount,
  adminAdjustmentContext,
  adminAdjustmentIdempotencyKey,
  ensureBnpCurrency,
} from './bnp-tip-account';
import type {
  BnpAdjustmentActor,
  BnpAdjustmentListResponse,
  BnpAdjustmentResponse,
} from './dto/bnp-adjustment-response.dto';
import type { CreateBnpAdjustmentDto } from './dto/create-bnp-adjustment.dto';
import type { ListBnpAdjustmentsQuery } from './dto/list-bnp-adjustments.query';
import {
  type AdjustmentLedgerMetadata,
  readAdjustmentMetadata,
  toAdjustmentResponse,
  toBalances,
} from './mining-adjustment.mapper';

export const ADMIN_ADJUSTMENT_AUDIT_ACTION = 'admin.mining.adjustment';

const ACTOR_SELECT = { id: true, displayName: true, username: true } as const;

type AdjustmentInput = {
  actorId: string;
  userId: string;
  dto: CreateBnpAdjustmentDto;
};

function insufficientBalance(
  claimedPoints: bigint,
  walletAtomic: bigint,
  requested: number,
): ConflictException {
  const current = toBalances(claimedPoints, walletAtomic);
  return new ConflictException({
    code: 'insufficient_balance',
    message:
      `Cannot remove ${Math.abs(requested)} BNP: the member has ` +
      `${current.walletBalance} BNP in their wallet and ` +
      `${current.claimedPoints} claimed BNP.`,
    currentBalance: current,
  });
}

function isUniqueViolation(error: unknown): boolean {
  return (
    error instanceof Prisma.PrismaClientKnownRequestError &&
    error.code === 'P2002'
  );
}

/**
 * F-66: owner/admin manual BNP adjustments. One transaction moves
 * `Profile.miningClaimedPoints` and the BNP wallet together, writes the
 * `MiningPointLedger` row, its `adjustment` TipTransaction and the audit row.
 * The TipTransaction's unique idempotency key makes a double-submit harmless.
 */
@Injectable()
export class MiningAdjustmentService {
  private readonly logger = new Logger(MiningAdjustmentService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly levelsService: LevelsService,
  ) {}

  async createAdjustment(
    actorId: string,
    userId: string,
    dto: CreateBnpAdjustmentDto,
  ): Promise<BnpAdjustmentResponse> {
    const replay = await this.findReplay(userId, dto);
    if (replay) return replay;

    const target = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: { id: true, isDeactivated: true },
    });
    if (!target) {
      throw new NotFoundException('User not found');
    }
    // Same rule as admin profile edits (users-admin.service).
    if (target.isDeactivated) {
      throw new BadRequestException(
        'Cannot adjust BNP for a deactivated user account',
      );
    }

    let ledger: MiningPointLedger;
    try {
      ledger = await this.prisma.$transaction((tx) =>
        this.applyAdjustment(tx, { actorId, userId, dto }),
      );
    } catch (error) {
      // A concurrent submit with the same key won the insert race.
      if (isUniqueViolation(error)) {
        const again = await this.findReplay(userId, dto);
        if (again) return again;
      }
      throw error;
    }

    await this.recalculateLevel(userId);

    const actor = await this.prisma.profile.findUnique({
      where: { id: actorId },
      select: ACTOR_SELECT,
    });
    return toAdjustmentResponse(ledger, actor, false);
  }

  async listAdjustments(
    userId: string,
    query: ListBnpAdjustmentsQuery,
  ): Promise<BnpAdjustmentListResponse> {
    const limit = query.limit ?? 20;
    const offset = query.offset ?? 0;

    const target = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: { id: true },
    });
    if (!target) {
      throw new NotFoundException('User not found');
    }

    const where: Prisma.MiningPointLedgerWhereInput = {
      userId,
      source: MiningPointSource.admin_adjustment,
    };
    const [total, rows] = await Promise.all([
      this.prisma.miningPointLedger.count({ where }),
      this.prisma.miningPointLedger.findMany({
        where,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip: offset,
        take: limit,
      }),
    ]);

    const actors = await this.loadActors(
      rows.map((row) => readAdjustmentMetadata(row).actorId),
    );
    return {
      total,
      limit,
      offset,
      data: rows.map((row) => {
        const { actorId } = readAdjustmentMetadata(row);
        return toAdjustmentResponse(
          row,
          (actorId && actors.get(actorId)) || null,
          false,
        );
      }),
    };
  }

  private async applyAdjustment(
    tx: Prisma.TransactionClient,
    { actorId, userId, dto }: AdjustmentInput,
  ): Promise<MiningPointLedger> {
    const delta = BigInt(dto.amount);

    await ensureBnpCurrency(tx);
    // Seeds a first-time account from miningClaimedPoints, like tips do.
    const account = await ensureUserTipAccount(tx, userId, BNP_CURRENCY_CODE);
    const current = await tx.profile.findUniqueOrThrow({
      where: { id: userId },
      select: { miningClaimedPoints: true },
    });

    if (delta < 0n) {
      const need = -delta;
      if (
        current.miningClaimedPoints < need ||
        account.balanceAtomic < need * BNP_ATOMIC_MULTIPLIER
      ) {
        throw insufficientBalance(
          current.miningClaimedPoints,
          account.balanceAtomic,
          dto.amount,
        );
      }
      // Guarded so a concurrent change can never take it below zero.
      const moved = await tx.profile.updateMany({
        where: { id: userId, miningClaimedPoints: { gte: need } },
        data: { miningClaimedPoints: { decrement: need } },
      });
      if (moved.count === 0) {
        throw insufficientBalance(
          current.miningClaimedPoints,
          account.balanceAtomic,
          dto.amount,
        );
      }
    } else {
      await tx.profile.update({
        where: { id: userId },
        data: { miningClaimedPoints: { increment: delta } },
      });
    }

    const ledgerId = randomUUID();
    let walletAfter: bigint;
    try {
      walletAfter = await adjustBnpTipAccount(
        tx,
        userId,
        dto.amount,
        adminAdjustmentContext({
          ledgerId,
          idempotencyKey: dto.idempotencyKey,
          reason: dto.reason,
          metadata: {
            direction: delta < 0n ? 'debit' : 'credit',
            actorId,
          },
        }),
      );
    } catch (error) {
      if (error instanceof InsufficientBnpBalanceError) {
        throw insufficientBalance(
          current.miningClaimedPoints,
          error.balanceAtomic,
          dto.amount,
        );
      }
      throw error;
    }

    // Our updates hold both row locks, so after - delta is the exact before.
    const { miningClaimedPoints: claimedAfter } =
      await tx.profile.findUniqueOrThrow({
        where: { id: userId },
        select: { miningClaimedPoints: true },
      });
    const balanceAfter = toBalances(claimedAfter, walletAfter);
    const balanceBefore = toBalances(
      claimedAfter - delta,
      walletAfter - delta * BNP_ATOMIC_MULTIPLIER,
    );

    const metadata: AdjustmentLedgerMetadata = {
      kind: 'admin_adjustment',
      reason: dto.reason,
      actorId,
      idempotencyKey: dto.idempotencyKey,
      balanceBefore,
      balanceAfter,
    };
    const ledger = await tx.miningPointLedger.create({
      data: {
        id: ledgerId,
        userId,
        source: MiningPointSource.admin_adjustment,
        points: dto.amount,
        metadata,
      },
    });

    // Written in the same transaction: a BNP move never exists unaudited.
    await tx.auditLog.create({
      data: {
        actorId,
        action: ADMIN_ADJUSTMENT_AUDIT_ACTION,
        resourceType: 'profile',
        resourceId: userId,
        metadata: {
          targetUserId: userId,
          ledgerId,
          amount: dto.amount,
          reason: dto.reason,
          idempotencyKey: dto.idempotencyKey,
          balanceBefore,
          balanceAfter,
        },
      },
    });

    return ledger;
  }

  /**
   * The original result for an already-applied key, or null. The same key
   * reused for a different member or amount is a client bug: reject it.
   */
  private async findReplay(
    userId: string,
    dto: CreateBnpAdjustmentDto,
  ): Promise<BnpAdjustmentResponse | null> {
    const tipTx = await this.prisma.tipTransaction.findUnique({
      where: {
        idempotencyKey: adminAdjustmentIdempotencyKey(dto.idempotencyKey),
      },
      select: { contextId: true },
    });
    if (!tipTx) return null;

    const ledger = tipTx.contextId
      ? await this.prisma.miningPointLedger.findUnique({
          where: { id: tipTx.contextId },
        })
      : null;
    if (!ledger || ledger.userId !== userId || ledger.points !== dto.amount) {
      throw new ConflictException({
        code: 'idempotency_key_conflict',
        message:
          'This idempotency key was already used for a different adjustment',
      });
    }

    const { actorId } = readAdjustmentMetadata(ledger);
    const actors = await this.loadActors([actorId]);
    return toAdjustmentResponse(
      ledger,
      (actorId && actors.get(actorId)) || null,
      true,
    );
  }

  private async loadActors(
    ids: Array<string | null>,
  ): Promise<Map<string, BnpAdjustmentActor>> {
    const unique = [...new Set(ids.filter((id): id is string => !!id))];
    if (unique.length === 0) return new Map();
    const rows = await this.prisma.profile.findMany({
      where: { id: { in: unique } },
      select: ACTOR_SELECT,
    });
    return new Map(rows.map((row) => [row.id, row]));
  }

  /** Levels read the mining ledger sum, so an adjustment can move a level. */
  private async recalculateLevel(userId: string): Promise<void> {
    try {
      await this.levelsService.updateUserLevel(userId);
    } catch (error) {
      this.logger.warn(
        `Failed to update user level after BNP adjustment: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }
}
