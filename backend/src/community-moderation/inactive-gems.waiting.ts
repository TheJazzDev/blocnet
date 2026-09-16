import {
  isStillWaiting,
  membersWaitingByGem,
  type GemEvent,
} from '../hunter-reliability/reliability.calc';
import {
  DAY_MS,
  ESCALATE_WAITING_AT,
  MEMBERS_WAITING_DAYS,
} from '../hunter-reliability/reliability.constants';
import type { ReliabilityLoader } from '../hunter-reliability/reliability.loader';
import type { PrismaService } from '../prisma/prisma.service';

/**
 * Written when a moderator closes a gem in the inactive-gems queue. Also the
 * marker that a moderator has dealt with a gem's wait: asks up to that moment
 * no longer count towards escalating it again.
 */
export const INACTIVE_GEMS_RESOLVED_ACTION =
  'project.inactivity_reports_resolved';

export type InactiveGemReason = 'reports' | 'waiting';
export const INACTIVE_GEM_REASONS: InactiveGemReason[] = ['reports', 'waiting'];

export interface WaitingEscalation {
  /** Members waiting since the later of the last update and the last resolution. */
  waiting: number;
  /** The earliest ask in that count. */
  since: Date;
}

export interface WaitingFacts {
  lastUpdateAt: Map<string, Date>;
  /** Members waiting now — the number the hunter and the member see. */
  waiting: Map<string, number>;
  /** Gems at or over `ESCALATE_WAITING_AT` that no moderator has yet handled. */
  escalated: Map<string, WaitingEscalation>;
}

/**
 * Waiting counts for [projectIds], plus every gem whose wait has reached the
 * escalation threshold. At most 4 queries, whatever the number of gems:
 *
 * 1. gems with at least ESCALATE_WAITING_AT asks this week — a superset of
 *    the escalated ones, found in the database so no gem is loaded blind;
 * 2. latest published update per gem; 3. this week's asks on those gems;
 * 4. the latest moderator resolution per gem.
 *
 * [scope] limits step 1 to those gems (resolving a single gem).
 */
export async function loadWaitingFacts(
  prisma: PrismaService,
  loader: ReliabilityLoader,
  input: { projectIds: string[]; now: Date; scope?: string[] },
): Promise<WaitingFacts> {
  const { projectIds, now, scope } = input;
  const from = new Date(now.getTime() - MEMBERS_WAITING_DAYS * DAY_MS);

  const candidates = await prisma.projectUpdateRequest.groupBy({
    by: ['projectId'],
    where: {
      createdAt: { gte: from },
      ...(scope ? { projectId: { in: scope } } : {}),
    },
    having: { projectId: { _count: { gte: ESCALATE_WAITING_AT } } },
  });

  const ids = [
    ...new Set([...projectIds, ...candidates.map((row) => row.projectId)]),
  ];
  if (ids.length === 0) {
    return {
      lastUpdateAt: new Map(),
      waiting: new Map(),
      escalated: new Map(),
    };
  }

  const [lastUpdateAt, askRows, resolutionRows] = await Promise.all([
    loader.loadLastUpdateAt(ids),
    prisma.projectUpdateRequest.findMany({
      where: { projectId: { in: ids }, createdAt: { gte: from } },
      select: { projectId: true, createdAt: true },
    }),
    prisma.auditLog.groupBy({
      by: ['resourceId'],
      where: {
        action: INACTIVE_GEMS_RESOLVED_ACTION,
        resourceType: 'project',
        resourceId: { in: ids },
        createdAt: { gte: from },
      },
      _max: { createdAt: true },
    }),
  ]);

  const asks: GemEvent[] = askRows.map((row) => ({
    projectId: row.projectId,
    at: row.createdAt,
  }));

  const clearedAt = new Map(lastUpdateAt);
  for (const row of resolutionRows) {
    const resolved = row._max.createdAt;
    if (!row.resourceId || !resolved) continue;
    const posted = clearedAt.get(row.resourceId);
    if (!posted || resolved > posted) clearedAt.set(row.resourceId, resolved);
  }

  return {
    lastUpdateAt,
    waiting: membersWaitingByGem(asks, lastUpdateAt, now),
    escalated: escalations(asks, clearedAt, now),
  };
}

/** Gems whose uncleared wait is at or over the threshold. Pure. */
export function escalations(
  asks: GemEvent[],
  clearedAt: Map<string, Date>,
  now: Date,
): Map<string, WaitingEscalation> {
  const byGem = new Map<string, WaitingEscalation>();
  for (const ask of asks) {
    const cleared = clearedAt.get(ask.projectId) ?? null;
    if (!isStillWaiting(ask.at, cleared, now)) continue;
    const entry = byGem.get(ask.projectId);
    if (!entry) {
      byGem.set(ask.projectId, { waiting: 1, since: ask.at });
      continue;
    }
    entry.waiting += 1;
    if (ask.at < entry.since) entry.since = ask.at;
  }
  for (const [projectId, entry] of byGem) {
    if (entry.waiting < ESCALATE_WAITING_AT) byGem.delete(projectId);
  }
  return byGem;
}
