import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { MiningCalculatorService } from './mining-calculator.service';
import { MiningConfigService } from './mining-config.service';
import {
  buildAheadOfWhere,
  buildLeaderboardWhere,
  buildSearchFilters,
  leaderboardOrderBy,
  leaderboardProfileSelect,
} from './mining-leaderboard.query';
import {
  LeaderboardMe,
  LeaderboardRow,
  LeaderboardRowContext,
  toLeaderboardRow,
} from './mining-leaderboard.row';

type GetLeaderboardOptions = {
  q?: string;
  limit?: number;
  offset?: number;
  includePrivateFields?: boolean;
  /**
   * When set, the response carries `me`: the viewer's own row ranked on the
   * unsearched board, or null when the viewer is not ranked.
   */
  viewerId?: string;
};

@Injectable()
export class MiningLeaderboardService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly miningCalculator: MiningCalculatorService,
    private readonly miningConfigService: MiningConfigService,
  ) {}

  async getLeaderboard(options: GetLeaderboardOptions = {}) {
    const asOf = new Date();
    const config = await this.miningConfigService.getEffectiveConfig();
    const limit = Math.min(Math.max(options.limit ?? 20, 1), 100);
    const offset = Math.max(options.offset ?? 0, 0);
    const includePrivateFields = options.includePrivateFields ?? false;
    const searchFilters = buildSearchFilters(
      options.q?.trim() || undefined,
      includePrivateFields,
    );
    const leaderboardWhere = buildLeaderboardWhere(asOf, searchFilters);

    const [profiles, total, viewer] = await Promise.all([
      this.prisma.profile.findMany({
        where: leaderboardWhere,
        orderBy: leaderboardOrderBy,
        skip: offset,
        take: limit,
        select: leaderboardProfileSelect,
      }),
      this.prisma.profile.count({
        where: leaderboardWhere,
      }),
      options.viewerId
        ? this.prisma.profile.findFirst({
            where: { ...buildLeaderboardWhere(asOf), id: options.viewerId },
            select: leaderboardProfileSelect,
          })
        : Promise.resolve(null),
    ]);

    const viewerRank = viewer
      ? 1 +
        (await this.prisma.profile.count({
          where: buildAheadOfWhere(asOf, viewer),
        }))
      : null;

    const userIds = profiles.map((profile) => profile.id);
    if (viewer && !userIds.includes(viewer.id)) {
      userIds.push(viewer.id);
    }
    const maturedByUserId = await this.loadMaturedUnclaimed(userIds, asOf);

    const ctx: LeaderboardRowContext = {
      asOf,
      config,
      miningCalculator: this.miningCalculator,
      includePrivateFields,
    };

    const data: LeaderboardRow[] = profiles.map((profile, index) =>
      toLeaderboardRow(
        profile,
        offset + index + 1,
        maturedByUserId.get(profile.id) ?? 0,
        ctx,
      ),
    );

    const base = { asOf, total, limit, offset, data };
    if (options.viewerId === undefined) {
      return base;
    }

    let me: LeaderboardMe | null = null;
    if (viewer && viewerRank !== null) {
      const row = toLeaderboardRow(
        viewer,
        viewerRank,
        maturedByUserId.get(viewer.id) ?? 0,
        ctx,
      );
      me = { ...row, isMiningNow: row.sessionStatus === 'running' };
    }

    return { ...base, me };
  }

  private async loadMaturedUnclaimed(
    userIds: string[],
    asOf: Date,
  ): Promise<Map<string, number>> {
    if (userIds.length === 0) {
      return new Map();
    }

    const rows = await this.prisma.miningHourlyCheckpoint.groupBy({
      by: ['userId'],
      where: {
        userId: {
          in: userIds,
        },
        claimedAt: null,
        expiredAt: null,
        hourEndAt: {
          lte: asOf,
        },
      },
      _sum: {
        points: true,
      },
    });

    return new Map(rows.map((row) => [row.userId, row._sum.points ?? 0]));
  }
}
