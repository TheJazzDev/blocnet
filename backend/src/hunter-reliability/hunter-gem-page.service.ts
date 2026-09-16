import { Injectable, NotFoundException } from '@nestjs/common';
import {
  InviteStatus,
  ProjectInviteKind,
  TipTransactionType,
  UpdateStatus,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  GEM_PAGE_UPDATES_DEFAULT_LIMIT,
  type HunterGemPageDto,
  type HunterGemPageQuery,
  type HunterGemUpdateDto,
  type PendingHandoverDto,
} from './dto/hunter-gem-page.dto';
import {
  assembleBoardGem,
  gemsOwnedBy,
  waitingByGem,
} from './reliability.assemble';
import { daysSince } from './reliability.calc';
import { ReliabilityLoader, type TipTotals } from './reliability.loader';

/** Tip contexts are free strings on `TipTransaction`; this one is an update. */
export const UPDATE_TIP_CONTEXT = 'update';

/**
 * `updatedAt` moves on any write. An edit is a write more than this long after
 * creation that is not a moderation change.
 */
const EDIT_GRACE_MS = 1000;

export function editedAtOf(row: {
  createdAt: Date;
  updatedAt: Date;
  moderatedAt: Date | null;
}): Date | null {
  const updated = row.updatedAt.getTime();
  if (updated - row.createdAt.getTime() <= EDIT_GRACE_MS) return null;
  if (
    row.moderatedAt &&
    Math.abs(updated - row.moderatedAt.getTime()) <= EDIT_GRACE_MS
  ) {
    return null;
  }
  return row.updatedAt;
}

/**
 * The hunter's gem page: the board row for one gem, plus its timeline.
 *
 * Twelve queries whatever the gem's history: gems (1), gem facts (6: the
 * tips half asks only for the currency), deadline (1), updates count (1),
 * the timeline (1), open handover (1), tips per update (1).
 */
@Injectable()
export class HunterGemPageService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly loader: ReliabilityLoader,
  ) {}

  /** Injected so tests can pin the clock. */
  protected now(): Date {
    return new Date();
  }

  async getGem(
    hunterId: string,
    projectId: string,
    query: HunterGemPageQuery = {},
  ): Promise<HunterGemPageDto> {
    const now = this.now();
    // Same ownership rule as the board: 404 for a gem the caller does not
    // keep, so the page does not confirm that the gem exists.
    const gems = await this.loader.loadGems([hunterId]);
    const gem = gemsOwnedBy(gems, hunterId).find(
      (row) => row.projectId === projectId,
    );
    if (!gem) throw new NotFoundException('Gem not found');

    const ids = [projectId];
    const [facts, deadlines, updatesCount, rows, handover] = await Promise.all([
      this.loader.loadFacts(ids, [], now),
      this.loader.loadNextDeadlines(ids, now),
      this.loader.loadUpdatesCount(ids),
      this.prisma.update.findMany({
        where: { projectId, status: UpdateStatus.published },
        orderBy: [{ createdAt: 'desc' }, { id: 'asc' }],
        take: query.limit ?? GEM_PAGE_UPDATES_DEFAULT_LIMIT,
        select: {
          id: true,
          title: true,
          urgency: true,
          createdAt: true,
          updatedAt: true,
          moderatedAt: true,
          _count: { select: { comments: true } },
        },
      }),
      this.loadPendingHandover(projectId),
    ]);
    const tipsByUpdate = await this.loadUpdateTips(
      rows.map((row) => row.id),
      facts.tips,
    );

    const newest = rows[0];
    const boardGem = assembleBoardGem({
      gem,
      facts,
      waiting: waitingByGem(facts, now),
      updatesCount: updatesCount.get(projectId) ?? 0,
      lastUpdate: newest && { ...newest, projectId },
      nextDeadlineAt: deadlines.get(projectId),
      now,
    });
    const lastUpdateAt = facts.lastUpdateAtByGem.get(projectId);

    return {
      gem: { ...boardGem, pendingHandover: handover },
      updates: rows.map(
        (row): HunterGemUpdateDto => ({
          id: row.id,
          title: row.title,
          priority: row.urgency,
          createdAt: row.createdAt.toISOString(),
          editedAt: editedAtOf(row)?.toISOString() ?? null,
          likesCount: 0,
          commentsCount: row._count.comments,
          tipsAtomic: (tipsByUpdate.get(row.id) ?? 0n).toString(),
          tipsCurrencyCode: facts.tips.currencyCode,
          tipsCurrencyDecimals: facts.tips.decimals,
        }),
      ),
      gapDays:
        boardGem.state === 'quiet' && lastUpdateAt
          ? daysSince(lastUpdateAt, now)
          : null,
    };
  }

  /** The gem's open handover, if any (at most one is allowed). 1 query. */
  private async loadPendingHandover(
    projectId: string,
  ): Promise<PendingHandoverDto | null> {
    const invite = await this.prisma.projectHunterInvite.findFirst({
      relationLoadStrategy: 'join',
      where: {
        projectId,
        kind: ProjectInviteKind.handover,
        status: InviteStatus.pending,
      },
      orderBy: { updatedAt: 'desc' },
      select: {
        id: true,
        updatedAt: true,
        hunter: { select: { id: true, username: true, displayName: true } },
      },
    });
    if (!invite) return null;
    return {
      inviteId: invite.id,
      hunter: invite.hunter,
      // The row is reopened for each new offer, so updatedAt is when this
      // one was made.
      createdAt: invite.updatedAt.toISOString(),
    };
  }

  /** Tips per update in the active currency, type tip only. 1 query. */
  private async loadUpdateTips(
    updateIds: string[],
    currency: TipTotals,
  ): Promise<Map<string, bigint>> {
    const map = new Map<string, bigint>();
    if (updateIds.length === 0 || !currency.currencyCode) return map;
    const rows = await this.prisma.tipTransaction.groupBy({
      by: ['contextId'],
      where: {
        contextType: UPDATE_TIP_CONTEXT,
        contextId: { in: updateIds },
        currencyCode: currency.currencyCode,
        type: TipTransactionType.tip,
      },
      _sum: { amountAtomic: true },
    });
    for (const row of rows) {
      if (row.contextId) map.set(row.contextId, row._sum.amountAtomic ?? 0n);
    }
    return map;
  }
}
