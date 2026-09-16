import { Injectable, NotFoundException } from '@nestjs/common';
import type {
  HunterBoardResponseDto,
  HunterLeaderboardResponseDto,
  HunterReliabilityDto,
  OwnerReliabilityDto,
} from './dto/hunter-reliability-response.dto';
import {
  LEADERBOARD_DEFAULT_LIMIT,
  type ListHunterLeaderboardQuery,
} from './dto/list-hunter-leaderboard.query';
import {
  assembleBoardGem,
  assembleReliability,
  gemsOwnedBy,
  summarizeStanding,
  waitingByGem,
} from './reliability.assemble';
import {
  compareBoardGems,
  compareLeaderboard,
  ownersOf,
  type ReliabilityStanding,
} from './reliability.calc';
import { ReliabilityLoader } from './reliability.loader';

/**
 * A hunter's reliability: the score members judge hunters by (owner decision
 * 2026-09-16), and the hunter's own view of which gems need them.
 *
 * All reads go through `ReliabilityLoader`, which is batched: the number of
 * queries per request is fixed, whatever the number of gems or hunters.
 */
@Injectable()
export class HunterReliabilityService {
  constructor(private readonly loader: ReliabilityLoader) {}

  /** Injected so tests can pin the clock. */
  protected now(): Date {
    return new Date();
  }

  async getReliability(profileId: string): Promise<HunterReliabilityDto> {
    const now = this.now();
    const [profiles, gems] = await Promise.all([
      this.loader.loadProfiles([profileId]),
      this.loader.loadGems([profileId]),
    ]);
    const profile = profiles[0];
    if (!profile) throw new NotFoundException('Profile not found');

    const owned = gemsOwnedBy(gems, profileId);
    const facts = await this.loader.loadFacts(
      owned.map((gem) => gem.projectId),
      [profileId],
      now,
    );
    return assembleReliability({
      hunterId: profileId,
      profile,
      owned,
      facts,
      now,
    });
  }

  /**
   * Every hunter who keeps at least one live gem, ranked by reliability.
   *
   * Ranked in memory and paged by offset: the ranking is computed, not stored,
   * so there is no index to seek on. Hunters number in the hundreds at most;
   * if that changes, this is the place to materialise the score.
   */
  async getLeaderboard(
    query: ListHunterLeaderboardQuery,
  ): Promise<HunterLeaderboardResponseDto> {
    const now = this.now();
    const limit = query.limit ?? LEADERBOARD_DEFAULT_LIMIT;
    const offset = query.cursor ? Number(query.cursor) : 0;

    const gems = await this.loader.loadGems();
    const hunterIds = [...new Set(gems.flatMap((gem) => gem.ownerIds))];
    const [profiles, facts] = await Promise.all([
      this.loader.loadProfiles(hunterIds, { activeOnly: true }),
      this.loader.loadFacts(
        gems.map((gem) => gem.projectId),
        hunterIds,
        now,
      ),
    ]);

    const ranked = profiles
      .map((profile) =>
        assembleReliability({
          hunterId: profile.id,
          profile,
          owned: gemsOwnedBy(gems, profile.id),
          facts,
          now,
        }),
      )
      .sort(compareLeaderboard);

    const page = ranked.slice(offset, offset + limit);
    const nextOffset = offset + page.length;
    return {
      items: page.map((entry, index) => ({
        ...entry,
        rank: offset + index + 1,
      })),
      nextCursor: nextOffset < ranked.length ? String(nextOffset) : null,
    };
  }

  /** The hunter's own board: their reliability and every gem, worst first. */
  async getBoard(hunterId: string): Promise<HunterBoardResponseDto> {
    const now = this.now();
    const [profiles, gems] = await Promise.all([
      this.loader.loadProfiles([hunterId]),
      this.loader.loadGems([hunterId]),
    ]);
    const owned = gemsOwnedBy(gems, hunterId);
    const projectIds = owned.map((gem) => gem.projectId);

    const [facts, nextDeadlines] = await Promise.all([
      this.loader.loadFacts(projectIds, [hunterId], now),
      this.loader.loadNextDeadlines(projectIds, now),
    ]);
    const lastUpdates = await this.loader.loadLastUpdateRows(
      facts.lastUpdateAtByGem,
    );
    const waiting = waitingByGem(facts, now);

    const boardGems = owned
      .map((gem) =>
        assembleBoardGem({
          gem,
          facts,
          waiting,
          lastUpdate: lastUpdates.get(gem.projectId),
          nextDeadlineAt: nextDeadlines.get(gem.projectId),
          now,
        }),
      )
      .sort(compareBoardGems);

    return {
      reliability: assembleReliability({
        hunterId,
        profile: profiles[0] ?? null,
        owned,
        facts,
        now,
      }),
      gems: boardGems,
    };
  }

  /**
   * Standing and coverage for many hunters at once, in two queries. Used where
   * a list needs a hunter's standing next to each row.
   */
  async standingsFor(
    hunterIds: string[],
  ): Promise<
    Map<string, { standing: ReliabilityStanding; coverage: number | null }>
  > {
    const now = this.now();
    const unique = [...new Set(hunterIds)];
    const gems = await this.loader.loadGems(unique);
    const lastUpdateAt = await this.loader.loadLastUpdateAt(
      gems.map((gem) => gem.projectId),
    );
    return new Map(
      unique.map((id) => [
        id,
        summarizeStanding(gemsOwnedBy(gems, id), lastUpdateAt, now),
      ]),
    );
  }

  /**
   * The compact owner reliability for gem cards, keyed by project id.
   *
   * A gem's "owner" for this purpose is the first person `ownersOf` names:
   * the earliest-assigned hunter, else the owning admin.
   */
  async ownerReliabilityFor(
    projects: {
      id: string;
      ownerAdminId: string;
      hunters: { hunterId: string }[];
    }[],
  ): Promise<Map<string, OwnerReliabilityDto>> {
    const primaryOwner = new Map(
      projects.map((project) => [project.id, ownersOf(project)[0]]),
    );
    const standings = await this.standingsFor([...primaryOwner.values()]);
    const result = new Map<string, OwnerReliabilityDto>();
    for (const [projectId, ownerId] of primaryOwner) {
      const summary = standings.get(ownerId);
      if (!summary) continue;
      result.set(projectId, { profileId: ownerId, ...summary });
    }
    return result;
  }
}
