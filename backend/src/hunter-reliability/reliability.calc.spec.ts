import {
  cadenceDays,
  compareBoardGems,
  compareLeaderboard,
  coverage,
  daysSince,
  gemState,
  groupAsks,
  lastActivityAt,
  median,
  ownersOf,
  responseRate,
  standing,
  type BoardGemSortable,
  type GemEvent,
  type LeaderboardSortable,
  type OwnedGemFacts,
} from './reliability.calc';

// Wednesday, ISO week 2026-W38.
const NOW = new Date('2026-09-16T12:00:00.000Z');
const DAY = 24 * 60 * 60 * 1000;
const daysAgo = (n: number) => new Date(NOW.getTime() - n * DAY);

const gem = (
  projectId: string,
  listedDaysAgo: number,
  lastUpdateDaysAgo: number | null,
): OwnedGemFacts => ({
  projectId,
  listedAt: daysAgo(listedDaysAgo),
  lastUpdateAt: lastUpdateDaysAgo === null ? null : daysAgo(lastUpdateDaysAgo),
});

const ev = (projectId: string, at: Date): GemEvent => ({ projectId, at });

describe('reliability.calc', () => {
  describe('ownersOf', () => {
    it('names assigned hunters when there are any', () => {
      expect(
        ownersOf({
          ownerAdminId: 'admin',
          hunters: [{ hunterId: 'h1' }, { hunterId: 'h2' }],
        }),
      ).toEqual(['h1', 'h2']);
    });

    it('falls back to the owning admin when none are assigned', () => {
      expect(ownersOf({ ownerAdminId: 'admin', hunters: [] })).toEqual([
        'admin',
      ]);
    });
  });

  describe('lastActivityAt / daysSince / gemState', () => {
    it('uses the newest update, else the listing date', () => {
      expect(lastActivityAt(gem('a', 40, 3))).toEqual(daysAgo(3));
      expect(lastActivityAt(gem('a', 40, null))).toEqual(daysAgo(40));
    });

    it('counts whole days and never goes negative', () => {
      expect(daysSince(daysAgo(3.9), NOW)).toBe(3);
      expect(daysSince(new Date(NOW.getTime() + DAY), NOW)).toBe(0);
    });

    it('is current under 10 days, due from 10, quiet from 14', () => {
      expect(gemState(daysAgo(0), NOW)).toBe('current');
      expect(gemState(new Date(NOW.getTime() - 10 * DAY + 1), NOW)).toBe(
        'current',
      );
      expect(gemState(daysAgo(10), NOW)).toBe('due');
      expect(gemState(new Date(NOW.getTime() - 14 * DAY + 1), NOW)).toBe('due');
      expect(gemState(daysAgo(14), NOW)).toBe('quiet');
      expect(gemState(daysAgo(200), NOW)).toBe('quiet');
    });
  });

  describe('coverage', () => {
    it('is null when the hunter owns nothing', () => {
      expect(coverage([], NOW)).toBeNull();
    });

    it('is the share of gems active in the last 14 days', () => {
      expect(
        coverage(
          [
            gem('a', 60, 2),
            gem('b', 60, 11),
            gem('c', 60, 14),
            gem('d', 60, 30),
          ],
          NOW,
        ),
      ).toBe(0.5);
    });

    it('counts a never-updated gem from its listing date', () => {
      expect(coverage([gem('fresh', 5, null)], NOW)).toBe(1);
      expect(coverage([gem('stale', 20, null)], NOW)).toBe(0);
    });
  });

  describe('median', () => {
    it('handles empty, odd and even lists without mutating input', () => {
      const input = [5, 1, 3];
      expect(median([])).toBeNull();
      expect(median(input)).toBe(3);
      expect(input).toEqual([5, 1, 3]);
      expect(median([4, 1, 3, 2])).toBe(2.5);
    });
  });

  describe('cadenceDays', () => {
    it('is null with fewer than two intervals', () => {
      expect(cadenceDays([], NOW)).toBeNull();
      expect(
        cadenceDays([ev('a', daysAgo(10)), ev('a', daysAgo(5))], NOW),
      ).toBeNull();
    });

    it('measures intervals per gem, not on a merged timeline', () => {
      // Gem a: every 10 days. Gem b: every 10 days, offset by 5.
      // Merged, the gaps would be 5 days; per gem they are 10.
      const updates = [
        ev('a', daysAgo(30)),
        ev('a', daysAgo(20)),
        ev('a', daysAgo(10)),
        ev('b', daysAgo(25)),
        ev('b', daysAgo(15)),
      ];
      expect(cadenceDays(updates, NOW)).toBe(10);
    });

    it('takes the median of pooled intervals, in any input order', () => {
      const updates = [
        ev('a', daysAgo(1)),
        ev('a', daysAgo(21)),
        ev('a', daysAgo(3)),
        ev('b', daysAgo(40)),
        ev('b', daysAgo(33)),
      ];
      // a: 21→3 = 18, 3→1 = 2; b: 7. Median of [2, 7, 18] = 7.
      expect(cadenceDays(updates, NOW)).toBe(7);
    });

    it('ignores updates older than 90 days and rounds to 0.1', () => {
      const updates = [
        ev('a', daysAgo(200)),
        ev('a', daysAgo(89)),
        ev('a', daysAgo(88.25)),
        ev('a', daysAgo(87.5)),
      ];
      // 200→89 is out of window; remaining gaps 0.75 and 0.75.
      expect(cadenceDays(updates, NOW)).toBe(0.8);
    });
  });

  describe('groupAsks / responseRate', () => {
    it('is null when there are no asks', () => {
      expect(responseRate([], [ev('a', daysAgo(1))], NOW)).toBeNull();
    });

    it('groups asks by gem and ISO week, keyed on the first ask', () => {
      // 2026-09-07 (Mon) and 2026-09-10 (Thu) share W37; 2026-09-14 is W38.
      const asks = [
        ev('a', new Date('2026-09-10T09:00:00Z')),
        ev('a', new Date('2026-09-07T09:00:00Z')),
        ev('a', new Date('2026-09-14T09:00:00Z')),
        ev('b', new Date('2026-09-08T09:00:00Z')),
      ];
      const groups = groupAsks(asks, [], NOW);
      expect(groups).toHaveLength(3);
      const aW37 = groups.find(
        (g) => g.projectId === 'a' && g.week === '2026-W37',
      );
      expect(aW37?.firstAskAt.toISOString()).toBe('2026-09-07T09:00:00.000Z');
    });

    it('answers a group only with an update within 7 days after the first ask', () => {
      const first = new Date('2026-08-03T10:00:00Z'); // W32
      const asks = [ev('a', first)];
      const at = (ms: number) => [ev('a', new Date(first.getTime() + ms))];

      expect(groupAsks(asks, at(-1), NOW)[0].answered).toBe(false); // before
      expect(groupAsks(asks, at(0), NOW)[0].answered).toBe(false); // same instant
      expect(groupAsks(asks, at(DAY), NOW)[0].answered).toBe(true);
      expect(groupAsks(asks, at(7 * DAY), NOW)[0].answered).toBe(true); // edge
      expect(groupAsks(asks, at(7 * DAY + 1), NOW)[0].answered).toBe(false);
      // An update on another gem does not answer this one.
      expect(
        groupAsks(asks, [ev('b', new Date(first.getTime() + DAY))], NOW)[0]
          .answered,
      ).toBe(false);
    });

    it('leaves a still-open, unanswered group undecided', () => {
      const asks = [ev('a', daysAgo(2))];
      expect(groupAsks(asks, [], NOW)[0].answered).toBeNull();
      expect(responseRate(asks, [], NOW)).toBeNull();
      // …but an open group already answered counts.
      expect(responseRate(asks, [ev('a', daysAgo(1))], NOW)).toBe(1);
    });

    it('ignores asks older than 90 days', () => {
      expect(groupAsks([ev('a', daysAgo(91))], [], NOW)).toHaveLength(0);
    });

    it('is the share of decided groups answered', () => {
      const asks = [
        ev('a', new Date('2026-07-06T10:00:00Z')), // answered
        ev('a', new Date('2026-07-07T10:00:00Z')), // same week, same group
        ev('a', new Date('2026-07-20T10:00:00Z')), // missed
        ev('b', new Date('2026-08-03T10:00:00Z')), // answered
        ev('b', new Date('2026-08-24T10:00:00Z')), // missed
        ev('b', daysAgo(1)), // still open → excluded
      ];
      const updates = [
        ev('a', new Date('2026-07-09T10:00:00Z')),
        ev('b', new Date('2026-08-04T10:00:00Z')),
      ];
      expect(responseRate(asks, updates, NOW)).toBe(0.5);
    });
  });

  describe('standing', () => {
    it('is new with no gems', () => {
      expect(standing([], NOW)).toBe('new');
    });

    it('is new while the first gem is under 14 days old', () => {
      expect(standing([gem('a', 13, null), gem('b', 5, null)], NOW)).toBe(
        'new',
      );
    });

    it('stops being new once the first gem is 14 days old', () => {
      expect(standing([gem('a', 14, 1)], NOW)).toBe('reliable');
    });

    it('bands coverage at 0.8 and 0.5', () => {
      const withCoverage = (current: number, total: number) =>
        Array.from({ length: total }, (_, i) =>
          gem(`g${i}`, 100, i < current ? 1 : 30),
        );
      expect(standing(withCoverage(4, 5), NOW)).toBe('reliable'); // 0.8
      expect(standing(withCoverage(7, 10), NOW)).toBe('slipping'); // 0.7
      expect(standing(withCoverage(1, 2), NOW)).toBe('slipping'); // 0.5
      expect(standing(withCoverage(4, 9), NOW)).toBe('quiet'); // 0.44
      expect(standing(withCoverage(0, 3), NOW)).toBe('quiet');
    });
  });

  describe('compareLeaderboard', () => {
    const row = (
      profileId: string,
      overrides: Partial<LeaderboardSortable> = {},
    ): LeaderboardSortable => ({
      profileId,
      standing: 'reliable',
      coverage: 1,
      response: 1,
      updates30d: 0,
      ...overrides,
    });
    const order = (rows: LeaderboardSortable[]) =>
      [...rows].sort(compareLeaderboard).map((r) => r.profileId);

    it('ranks reliable, slipping, quiet, then new', () => {
      expect(
        order([
          row('new', { standing: 'new', coverage: 1 }),
          row('quiet', { standing: 'quiet', coverage: 0.1 }),
          row('reliable', { standing: 'reliable', coverage: 0.8 }),
          row('slipping', { standing: 'slipping', coverage: 0.6 }),
        ]),
      ).toEqual(['reliable', 'slipping', 'quiet', 'new']);
    });

    it('then coverage desc, response desc with null last, updates30d desc', () => {
      expect(
        order([
          row('lowCov', { coverage: 0.85 }),
          row('nullResp', { response: null, updates30d: 99 }),
          row('lowResp', { response: 0.5 }),
          row('moreUpdates', { updates30d: 5 }),
          row('fewerUpdates', { updates30d: 1 }),
        ]),
      ).toEqual([
        'moreUpdates',
        'fewerUpdates',
        'lowResp',
        'nullResp',
        'lowCov',
      ]);
    });

    it('puts null coverage after any number and breaks ties by id', () => {
      expect(
        order([
          row('b', { standing: 'new', coverage: null }),
          row('a', { standing: 'new', coverage: null }),
          row('c', { standing: 'new', coverage: 0 }),
        ]),
      ).toEqual(['c', 'a', 'b']);
    });
  });

  describe('compareBoardGems', () => {
    const g = (
      projectId: string,
      overrides: Partial<BoardGemSortable> = {},
    ): BoardGemSortable => ({
      projectId,
      name: projectId,
      state: 'current',
      membersWaiting: 0,
      daysQuiet: 0,
      ...overrides,
    });
    const order = (rows: BoardGemSortable[]) =>
      [...rows].sort(compareBoardGems).map((r) => r.projectId);

    it('puts quiet first, then due, then current', () => {
      expect(
        order([
          g('current', { membersWaiting: 50 }),
          g('due', { state: 'due' }),
          g('quiet', { state: 'quiet' }),
        ]),
      ).toEqual(['quiet', 'due', 'current']);
    });

    it('within a group, orders by members waiting then days quiet', () => {
      expect(
        order([
          g('q1', { state: 'quiet', membersWaiting: 1, daysQuiet: 90 }),
          g('q2', { state: 'quiet', membersWaiting: 4, daysQuiet: 15 }),
          g('q3', { state: 'quiet', membersWaiting: 1, daysQuiet: 20 }),
        ]),
      ).toEqual(['q2', 'q1', 'q3']);
    });
  });
});
