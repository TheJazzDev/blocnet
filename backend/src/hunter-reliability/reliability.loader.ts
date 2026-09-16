import { Injectable } from '@nestjs/common';
import {
  Prisma,
  ProjectStatus,
  TipTransactionType,
  UpdateStatus,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ownersOf, waitingWindow, type GemEvent } from './reliability.calc';
import { DAY_MS, RELIABILITY_WINDOW_DAYS } from './reliability.constants';

/**
 * Batched reads behind reliability.
 *
 * Every method is a fixed number of queries whatever the number of hunters or
 * gems — there is no per-gem or per-hunter query anywhere in this module.
 */

/** A live gem and whoever keeps it, per `ownersOf`. */
export interface GemRow {
  projectId: string;
  name: string;
  primaryTag: string;
  listedAt: Date;
  ownerIds: string[];
}

export interface TipTotals {
  currencyCode: string | null;
  decimals: number | null;
  byHunter: Map<string, bigint>;
}

export interface ReliabilityFacts {
  lastUpdateAtByGem: Map<string, Date>;
  /** Published updates on the gems inside the reliability window. */
  updates: GemEvent[];
  /** Member asks on the gems inside the reliability window. */
  asks: GemEvent[];
  openReportsByGem: Map<string, number>;
  followersByGem: Map<string, number>;
  tips: TipTotals;
}

interface EventRow {
  projectId: string;
  createdAt: Date;
}

const NO_EVENTS: EventRow[] = [];
const NO_COUNTS: { projectId: string; _count: { _all: number } }[] = [];

export interface LastUpdateRow {
  id: string;
  projectId: string;
  title: string;
  createdAt: Date;
}

export const profileSummarySelect = {
  id: true,
  username: true,
  displayName: true,
  avatarUrl: true,
  currentLevel: {
    select: {
      id: true,
      slug: true,
      name: true,
      level: true,
      iconUrl: true,
      color: true,
    },
  },
} satisfies Prisma.ProfileSelect;

export type ProfileSummaryRow = Prisma.ProfileGetPayload<{
  select: typeof profileSummarySelect;
}>;

/**
 * The asks on one gem that still count as members waiting (`waitingWindow`),
 * as a Prisma filter — for reads that count in the database rather than load
 * the asks.
 */
export function waitingAsksWhere(
  projectId: string,
  clearedAt: Date | null,
  now: Date,
): Prisma.ProjectUpdateRequestWhereInput {
  const { from, after } = waitingWindow(clearedAt, now);
  return {
    projectId,
    createdAt: after ? { gt: after } : { gte: from },
  };
}

/**
 * Only `active` gems count against a hunter. A paused, archived or hidden gem
 * is one an admin has taken out of circulation; holding the hunter to a
 * fortnightly update on it would be unfair.
 */
const LIVE_GEM_STATUS = ProjectStatus.active;

@Injectable()
export class ReliabilityLoader {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Live gems with their owners. With [hunterIds], only gems at least one of
   * those hunters keeps; without, every live gem (the leaderboard). 1 query.
   */
  async loadGems(hunterIds?: string[]): Promise<GemRow[]> {
    if (hunterIds && hunterIds.length === 0) return [];

    const ownerFilter: Prisma.ProjectWhereInput | undefined = hunterIds
      ? {
          OR: [
            { hunters: { some: { hunterId: { in: hunterIds } } } },
            { hunters: { none: {} }, ownerAdminId: { in: hunterIds } },
          ],
        }
      : undefined;

    const rows = await this.prisma.project.findMany({
      relationLoadStrategy: 'join',
      where: { status: LIVE_GEM_STATUS, ...ownerFilter },
      select: {
        id: true,
        name: true,
        createdAt: true,
        ownerAdminId: true,
        primaryTag: { select: { name: true } },
        hunters: { select: { hunterId: true }, orderBy: { createdAt: 'asc' } },
      },
    });

    return rows.map((row) => ({
      projectId: row.id,
      name: row.name,
      primaryTag: row.primaryTag.name,
      listedAt: row.createdAt,
      ownerIds: ownersOf(row),
    }));
  }

  /** Newest published update per gem. 1 query. */
  async loadLastUpdateAt(projectIds: string[]): Promise<Map<string, Date>> {
    if (projectIds.length === 0) return new Map();
    const rows = await this.prisma.update.groupBy({
      by: ['projectId'],
      where: { projectId: { in: projectIds }, status: UpdateStatus.published },
      _max: { createdAt: true },
    });
    const map = new Map<string, Date>();
    for (const row of rows) {
      if (row._max.createdAt) map.set(row.projectId, row._max.createdAt);
    }
    return map;
  }

  /** Everything reliability needs for these gems and hunters. 7 queries. */
  async loadFacts(
    projectIds: string[],
    hunterIds: string[],
    now: Date,
  ): Promise<ReliabilityFacts> {
    const windowStart = new Date(
      now.getTime() - RELIABILITY_WINDOW_DAYS * DAY_MS,
    );
    const hasGems = projectIds.length > 0;
    const inGems = { projectId: { in: projectIds } };

    const [lastUpdateAtByGem, updates, asks, reportRows, followRows, tips] =
      await Promise.all([
        this.loadLastUpdateAt(projectIds),
        hasGems
          ? this.prisma.update.findMany({
              where: {
                ...inGems,
                status: UpdateStatus.published,
                createdAt: { gte: windowStart },
              },
              select: { projectId: true, createdAt: true },
            })
          : Promise.resolve(NO_EVENTS),
        hasGems
          ? this.prisma.projectUpdateRequest.findMany({
              where: { ...inGems, createdAt: { gte: windowStart } },
              select: { projectId: true, createdAt: true },
            })
          : Promise.resolve(NO_EVENTS),
        hasGems
          ? this.prisma.projectInactivityReport.groupBy({
              by: ['projectId'],
              where: { ...inGems, resolvedAt: null },
              _count: { _all: true },
            })
          : Promise.resolve(NO_COUNTS),
        hasGems
          ? this.prisma.projectFollow.groupBy({
              by: ['projectId'],
              where: inGems,
              _count: { _all: true },
            })
          : Promise.resolve(NO_COUNTS),
        this.loadTips(hunterIds),
      ]);

    return {
      lastUpdateAtByGem,
      updates: updates.map((row) => ({
        projectId: row.projectId,
        at: row.createdAt,
      })),
      asks: asks.map((row) => ({
        projectId: row.projectId,
        at: row.createdAt,
      })),
      openReportsByGem: countMap(reportRows),
      followersByGem: countMap(followRows),
      tips,
    };
  }

  /**
   * Tips received, in the active tipping currency only — summing atomic units
   * across currencies would add unlike things. 2 queries.
   */
  async loadTips(hunterIds: string[]): Promise<TipTotals> {
    const currency = await this.prisma.tipCurrency.findFirst({
      where: { isActiveTippingCurrency: true, isEnabled: true },
      select: { code: true, decimals: true },
    });
    const byHunter = new Map<string, bigint>();
    if (!currency || hunterIds.length === 0) {
      return {
        currencyCode: currency?.code ?? null,
        decimals: currency?.decimals ?? null,
        byHunter,
      };
    }

    const rows = await this.prisma.tipTransaction.groupBy({
      by: ['recipientUserId'],
      where: {
        recipientUserId: { in: hunterIds },
        currencyCode: currency.code,
        type: TipTransactionType.tip,
      },
      _sum: { amountAtomic: true },
    });
    for (const row of rows) {
      byHunter.set(row.recipientUserId, row._sum.amountAtomic ?? 0n);
    }
    return {
      currencyCode: currency.code,
      decimals: currency.decimals,
      byHunter,
    };
  }

  /** 1 query. */
  async loadProfiles(
    ids: string[],
    options: { activeOnly?: boolean } = {},
  ): Promise<ProfileSummaryRow[]> {
    if (ids.length === 0) return [];
    return this.prisma.profile.findMany({
      relationLoadStrategy: 'join',
      where: {
        id: { in: ids },
        ...(options.activeOnly ? { isDeactivated: false } : {}),
      },
      select: profileSummarySelect,
    });
  }

  /** The newest published update row per gem, for the board. 1 query. */
  async loadLastUpdateRows(
    lastUpdateAtByGem: Map<string, Date>,
  ): Promise<Map<string, LastUpdateRow>> {
    if (lastUpdateAtByGem.size === 0) return new Map();
    const rows = await this.prisma.update.findMany({
      where: {
        status: UpdateStatus.published,
        OR: [...lastUpdateAtByGem].map(([projectId, createdAt]) => ({
          projectId,
          createdAt,
        })),
      },
      select: { id: true, projectId: true, title: true, createdAt: true },
      orderBy: { id: 'asc' },
    });
    // Two updates with the identical timestamp are possible; keep one, stably.
    const map = new Map<string, LastUpdateRow>();
    for (const row of rows) {
      if (!map.has(row.projectId)) map.set(row.projectId, row);
    }
    return map;
  }

  /** Soonest future deadline among each gem's published updates. 1 query. */
  async loadNextDeadlines(
    projectIds: string[],
    now: Date,
  ): Promise<Map<string, Date>> {
    if (projectIds.length === 0) return new Map();
    const rows = await this.prisma.update.groupBy({
      by: ['projectId'],
      where: {
        projectId: { in: projectIds },
        status: UpdateStatus.published,
        deadlineAt: { gt: now },
      },
      _min: { deadlineAt: true },
    });
    const map = new Map<string, Date>();
    for (const row of rows) {
      if (row._min.deadlineAt) map.set(row.projectId, row._min.deadlineAt);
    }
    return map;
  }
}

function countMap(
  rows: { projectId: string; _count: { _all: number } }[],
): Map<string, number> {
  return new Map(rows.map((row) => [row.projectId, row._count._all]));
}
