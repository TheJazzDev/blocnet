import type {
  HunterBoardGemDto,
  HunterReliabilityDto,
} from './dto/hunter-reliability-response.dto';
import {
  cadenceDays,
  coverage,
  daysSince,
  gemState,
  lastActivityAt,
  membersWaitingByGem,
  responseCounts,
  shareOf,
  standing,
  type OwnedGemFacts,
  type ReliabilityStanding,
} from './reliability.calc';
import {
  DAY_MS,
  ESCALATE_WAITING_AT,
  RECENT_UPDATES_DAYS,
} from './reliability.constants';
import type {
  GemRow,
  LastUpdateRow,
  ProfileSummaryRow,
  ReliabilityFacts,
} from './reliability.loader';

/**
 * Turns loaded facts into response shapes. Pure: no Prisma, `now` passed in.
 */

export function gemsOwnedBy(gems: GemRow[], hunterId: string): GemRow[] {
  return gems.filter((gem) => gem.ownerIds.includes(hunterId));
}

export function toGemFacts(
  gem: GemRow,
  lastUpdateAtByGem: Map<string, Date>,
): OwnedGemFacts {
  return {
    projectId: gem.projectId,
    listedAt: gem.listedAt,
    lastUpdateAt: lastUpdateAtByGem.get(gem.projectId) ?? null,
  };
}

/** Coverage and standing only — the two queries' worth a gem card needs. */
export function summarizeStanding(
  owned: GemRow[],
  lastUpdateAtByGem: Map<string, Date>,
  now: Date,
): { standing: ReliabilityStanding; coverage: number | null } {
  const facts = owned.map((gem) => toGemFacts(gem, lastUpdateAtByGem));
  return { standing: standing(facts, now), coverage: coverage(facts, now) };
}

function sumBy(ids: Set<string>, counts: Map<string, number>): number {
  let total = 0;
  for (const id of ids) total += counts.get(id) ?? 0;
  return total;
}

export function assembleReliability(input: {
  hunterId: string;
  profile: ProfileSummaryRow | null;
  owned: GemRow[];
  facts: ReliabilityFacts;
  now: Date;
}): HunterReliabilityDto {
  const { hunterId, profile, owned, facts, now } = input;
  const ids = new Set(owned.map((gem) => gem.projectId));
  const gemFacts = owned.map((gem) => toGemFacts(gem, facts.lastUpdateAtByGem));
  const mine = <T extends { projectId: string }>(rows: T[]) =>
    rows.filter((row) => ids.has(row.projectId));

  const updates = mine(facts.updates);
  const asks = mine(facts.asks);
  const recentFrom = now.getTime() - RECENT_UPDATES_DAYS * DAY_MS;
  const response = responseCounts(asks, updates, now);

  return {
    profileId: hunterId,
    username: profile?.username ?? null,
    displayName: profile?.displayName ?? null,
    avatarUrl: profile?.avatarUrl ?? null,
    level: profile?.currentLevel ?? null,
    standing: standing(gemFacts, now),
    coverage: roundShare(coverage(gemFacts, now)),
    cadenceDays: cadenceDays(updates, now),
    response: roundShare(shareOf(response)),
    responseAnswered: response.answered,
    responseAsked: response.asked,
    gemsOwned: owned.length,
    updates30d: updates.filter((u) => u.at.getTime() >= recentFrom).length,
    followersTotal: sumBy(ids, facts.followersByGem),
    tipsReceivedTotal: (facts.tips.byHunter.get(hunterId) ?? 0n).toString(),
    tipsCurrencyCode: facts.tips.currencyCode,
    tipsCurrencyDecimals: facts.tips.decimals,
    membersWaiting: sumBy(
      ids,
      membersWaitingByGem(asks, facts.lastUpdateAtByGem, now),
    ),
    openReports: sumBy(ids, facts.openReportsByGem),
    escalatesAtWaiting: ESCALATE_WAITING_AT,
    computedAt: now.toISOString(),
  };
}

/**
 * Members waiting per gem: asks in the last week made after the gem's latest
 * published update.
 */
export function waitingByGem(
  facts: ReliabilityFacts,
  now: Date,
): Map<string, number> {
  return membersWaitingByGem(facts.asks, facts.lastUpdateAtByGem, now);
}

export function assembleBoardGem(input: {
  gem: GemRow;
  facts: ReliabilityFacts;
  waiting: Map<string, number>;
  lastUpdate: LastUpdateRow | undefined;
  nextDeadlineAt: Date | undefined;
  now: Date;
}): HunterBoardGemDto {
  const { gem, facts, waiting, lastUpdate, nextDeadlineAt, now } = input;
  const last = lastActivityAt(toGemFacts(gem, facts.lastUpdateAtByGem));
  return {
    projectId: gem.projectId,
    name: gem.name,
    logoUrl: null,
    primaryTag: gem.primaryTag,
    followersCount: facts.followersByGem.get(gem.projectId) ?? 0,
    listedAt: gem.listedAt.toISOString(),
    lastActivityAt: last.toISOString(),
    lastUpdate: lastUpdate
      ? {
          id: lastUpdate.id,
          title: lastUpdate.title,
          publishedAt: lastUpdate.createdAt.toISOString(),
        }
      : null,
    daysQuiet: daysSince(last, now),
    state: gemState(last, now),
    membersWaiting: waiting.get(gem.projectId) ?? 0,
    openReports: facts.openReportsByGem.get(gem.projectId) ?? 0,
    escalatesAtWaiting: ESCALATE_WAITING_AT,
    nextDeadlineAt: nextDeadlineAt?.toISOString() ?? null,
  };
}

/** Shares are shown as percentages; three decimals is plenty and keeps JSON tidy. */
function roundShare(value: number | null): number | null {
  return value === null ? null : Math.round(value * 1000) / 1000;
}
