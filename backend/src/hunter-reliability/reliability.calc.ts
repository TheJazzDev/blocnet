import { isoWeekKey } from '../common/utils/iso-week.util';
import {
  DAY_MS,
  DUE_AFTER_DAYS,
  NEW_HUNTER_DAYS,
  QUIET_AFTER_DAYS,
  RELIABILITY_WINDOW_DAYS,
  RELIABLE_MIN_COVERAGE,
  RESPONSE_WINDOW_DAYS,
  SLIPPING_MIN_COVERAGE,
} from './reliability.constants';

/**
 * Pure reliability arithmetic. No Prisma, no clock: every function takes `now`
 * so the rules can be tested against fixed dates.
 */

export type ReliabilityStanding = 'new' | 'reliable' | 'slipping' | 'quiet';
export type GemState = 'current' | 'due' | 'quiet';

export const RELIABILITY_STANDINGS: ReliabilityStanding[] = [
  'reliable',
  'slipping',
  'quiet',
  'new',
];
export const GEM_STATES: GemState[] = ['current', 'due', 'quiet'];

/** A timestamped event on one gem: a published update, or a member ask. */
export interface GemEvent {
  projectId: string;
  at: Date;
}

/** What reliability needs to know about one gem a hunter owns. */
export interface OwnedGemFacts {
  projectId: string;
  listedAt: Date;
  /** Newest published update, or null when the gem has never had one. */
  lastUpdateAt: Date | null;
}

/**
 * Who keeps a gem: its assigned hunters, or the owning admin when none are
 * assigned. The one ownership rule — nudges, reliability, the hunter's board
 * and the moderator queue all use it.
 */
export function ownersOf(project: {
  ownerAdminId: string;
  hunters: { hunterId: string }[];
}): string[] {
  if (project.hunters.length > 0) {
    return project.hunters.map((row) => row.hunterId);
  }
  return [project.ownerAdminId];
}

/** Newest published update, else the listing date. */
export function lastActivityAt(gem: OwnedGemFacts): Date {
  return gem.lastUpdateAt ?? gem.listedAt;
}

/** Whole days since [since]; never negative. */
export function daysSince(since: Date, now: Date): number {
  return Math.max(0, Math.floor((now.getTime() - since.getTime()) / DAY_MS));
}

export function gemState(lastActivity: Date, now: Date): GemState {
  const quietMs = now.getTime() - lastActivity.getTime();
  if (quietMs >= QUIET_AFTER_DAYS * DAY_MS) return 'quiet';
  if (quietMs >= DUE_AFTER_DAYS * DAY_MS) return 'due';
  return 'current';
}

/** Share of owned gems not yet quiet. Null when the hunter owns none. */
export function coverage(gems: OwnedGemFacts[], now: Date): number | null {
  if (gems.length === 0) return null;
  const covered = gems.filter(
    (gem) => gemState(lastActivityAt(gem), now) !== 'quiet',
  ).length;
  return covered / gems.length;
}

export function median(values: number[]): number | null {
  if (values.length === 0) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 1
    ? sorted[mid]
    : (sorted[mid - 1] + sorted[mid]) / 2;
}

/**
 * Median days between consecutive published updates **on the same gem**,
 * pooled across the hunter's gems, over the reliability window.
 *
 * Intervals are per gem, not on one merged timeline: merging would let a hunter
 * with ten gems look fast while each gem individually waits a month. Null with
 * fewer than two intervals — one gap is not a cadence. Rounded to 0.1 day.
 */
export function cadenceDays(updates: GemEvent[], now: Date): number | null {
  const windowStart = now.getTime() - RELIABILITY_WINDOW_DAYS * DAY_MS;
  const byGem = new Map<string, number[]>();
  for (const update of updates) {
    const t = update.at.getTime();
    if (t < windowStart || t > now.getTime()) continue;
    const list = byGem.get(update.projectId) ?? [];
    list.push(t);
    byGem.set(update.projectId, list);
  }

  const intervals: number[] = [];
  for (const times of byGem.values()) {
    times.sort((a, b) => a - b);
    for (let i = 1; i < times.length; i++) {
      intervals.push((times[i] - times[i - 1]) / DAY_MS);
    }
  }
  if (intervals.length < 2) return null;
  const value = median(intervals);
  return value === null ? null : Math.round(value * 10) / 10;
}

/** One gem-week of member asks, and whether the hunter answered it. */
export interface AskGroup {
  projectId: string;
  week: string;
  firstAskAt: Date;
  /** True/false once decided; null while the window is still open and unanswered. */
  answered: boolean | null;
}

/**
 * Groups asks in the reliability window by (gem, ISO week), and decides each
 * group: answered if a published update on that gem landed within
 * RESPONSE_WINDOW_DAYS after the group's first ask.
 *
 * A group whose window is still open with no update yet is undecided (null) —
 * counting it as a miss would punish a hunter for an ask made an hour ago.
 */
export function groupAsks(
  asks: GemEvent[],
  updates: GemEvent[],
  now: Date,
): AskGroup[] {
  const windowStart = now.getTime() - RELIABILITY_WINDOW_DAYS * DAY_MS;
  const responseMs = RESPONSE_WINDOW_DAYS * DAY_MS;

  const groups = new Map<string, AskGroup>();
  for (const ask of asks) {
    const t = ask.at.getTime();
    if (t < windowStart || t > now.getTime()) continue;
    const week = isoWeekKey(ask.at);
    const key = `${ask.projectId}:${week}`;
    const existing = groups.get(key);
    if (!existing || t < existing.firstAskAt.getTime()) {
      groups.set(key, {
        projectId: ask.projectId,
        week,
        firstAskAt: ask.at,
        answered: null,
      });
    }
  }

  const updatesByGem = new Map<string, number[]>();
  for (const update of updates) {
    const list = updatesByGem.get(update.projectId) ?? [];
    list.push(update.at.getTime());
    updatesByGem.set(update.projectId, list);
  }

  for (const group of groups.values()) {
    const start = group.firstAskAt.getTime();
    const end = start + responseMs;
    const hit = (updatesByGem.get(group.projectId) ?? []).some(
      (t) => t > start && t <= end,
    );
    if (hit) group.answered = true;
    else if (now.getTime() >= end) group.answered = false;
  }

  return [...groups.values()];
}

/** Share of decided ask-groups the hunter answered. Null when none are decided. */
export function responseRate(
  asks: GemEvent[],
  updates: GemEvent[],
  now: Date,
): number | null {
  const decided = groupAsks(asks, updates, now).filter(
    (group) => group.answered !== null,
  );
  if (decided.length === 0) return null;
  return decided.filter((group) => group.answered).length / decided.length;
}

export function standing(
  gems: OwnedGemFacts[],
  now: Date,
): ReliabilityStanding {
  if (gems.length === 0) return 'new';
  const firstListed = Math.min(...gems.map((gem) => gem.listedAt.getTime()));
  if (now.getTime() - firstListed < NEW_HUNTER_DAYS * DAY_MS) return 'new';
  const value = coverage(gems, now) ?? 0;
  if (value >= RELIABLE_MIN_COVERAGE) return 'reliable';
  if (value >= SLIPPING_MIN_COVERAGE) return 'slipping';
  return 'quiet';
}

/** Descending, with null after every number. */
function compareNullableDesc(a: number | null, b: number | null): number {
  if (a === b) return 0;
  if (a === null) return 1;
  if (b === null) return -1;
  return b - a;
}

export interface LeaderboardSortable {
  profileId: string;
  standing: ReliabilityStanding;
  coverage: number | null;
  response: number | null;
  updates30d: number;
}

const STANDING_RANK: Record<ReliabilityStanding, number> = {
  reliable: 0,
  slipping: 1,
  quiet: 2,
  new: 3,
};

/**
 * Leaderboard order: standing (reliable, slipping, quiet, then new), coverage,
 * response (unknown last), updates in the last 30 days. Profile id breaks the
 * remaining ties so the order — and therefore the cursor — is stable.
 */
export function compareLeaderboard(
  a: LeaderboardSortable,
  b: LeaderboardSortable,
): number {
  return (
    STANDING_RANK[a.standing] - STANDING_RANK[b.standing] ||
    compareNullableDesc(a.coverage, b.coverage) ||
    compareNullableDesc(a.response, b.response) ||
    b.updates30d - a.updates30d ||
    a.profileId.localeCompare(b.profileId)
  );
}

export interface BoardGemSortable {
  projectId: string;
  name: string;
  state: GemState;
  membersWaiting: number;
  daysQuiet: number;
}

const STATE_RANK: Record<GemState, number> = { quiet: 0, due: 1, current: 2 };

/**
 * The hunter's to-do order: quiet gems first, then due, then current; within
 * a group, the gem more members are waiting on, then the one silent longest.
 */
export function compareBoardGems(
  a: BoardGemSortable,
  b: BoardGemSortable,
): number {
  return (
    STATE_RANK[a.state] - STATE_RANK[b.state] ||
    b.membersWaiting - a.membersWaiting ||
    b.daysQuiet - a.daysQuiet ||
    a.name.localeCompare(b.name) ||
    a.projectId.localeCompare(b.projectId)
  );
}
