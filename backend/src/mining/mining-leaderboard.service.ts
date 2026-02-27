import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { MiningCalculatorService } from './mining-calculator.service';

type MiningSessionStatus = 'idle' | 'running' | 'claimable';

type GetLeaderboardOptions = {
  q?: string;
  limit?: number;
  offset?: number;
  includePrivateFields?: boolean;
};

@Injectable()
export class MiningLeaderboardService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly miningCalculator: MiningCalculatorService,
  ) {}

  async getLeaderboard(options: GetLeaderboardOptions = {}) {
    const asOf = new Date();
    const limit = Math.min(Math.max(options.limit ?? 20, 1), 100);
    const offset = Math.max(options.offset ?? 0, 0);
    const searchQuery = options.q?.trim();

    const searchFilters: Prisma.ProfileWhereInput[] = [];
    if (searchQuery && searchQuery.length > 0) {
      searchFilters.push(
        {
          displayName: {
            contains: searchQuery,
            mode: 'insensitive',
          },
        },
        {
          username: {
            contains: searchQuery,
            mode: 'insensitive',
          },
        },
      );

      if (options.includePrivateFields) {
        searchFilters.push({
          email: {
            contains: searchQuery,
            mode: 'insensitive',
          },
        });
      }

      if (searchQuery.length >= 8) {
        searchFilters.push({
          id: searchQuery,
        });
      }
    }

    const leaderboardWhere: Prisma.ProfileWhereInput = {
      isDeactivated: false,
      AND: [
        {
          OR: [
            {
              miningClaimedPoints: {
                gt: BigInt(0),
              },
            },
            {
              miningSessions: {
                some: {},
              },
            },
          ],
        },
        ...(searchFilters.length > 0
          ? [
              {
                OR: searchFilters,
              } as Prisma.ProfileWhereInput,
            ]
          : []),
      ],
    };

    const [profiles, total] = await Promise.all([
      this.prisma.profile.findMany({
        where: leaderboardWhere,
        orderBy: [
          {
            miningClaimedPoints: 'desc',
          },
          {
            createdAt: 'asc',
          },
        ],
        skip: offset,
        take: limit,
        select: {
          id: true,
          email: true,
          username: true,
          displayName: true,
          avatarUrl: true,
          miningClaimedPoints: true,
          primaryBadge: {
            select: {
              id: true,
              slug: true,
              name: true,
              description: true,
              imageUrl: true,
              category: true,
              rarity: true,
            },
          },
          miningSessions: {
            where: {
              claimedAt: null,
            },
            orderBy: {
              startsAt: 'desc',
            },
            take: 1,
            select: {
              id: true,
              startsAt: true,
              endsAt: true,
              boostBpsSnapshot: true,
              activeReferralsSnapshot: true,
            },
          },
        },
      }),
      this.prisma.profile.count({
        where: leaderboardWhere,
      }),
    ]);

    if (profiles.length === 0) {
      return {
        asOf,
        total,
        limit,
        offset,
        data: [] as Array<Record<string, unknown>>,
      };
    }

    const userIds = profiles.map((profile) => profile.id);
    const maturedUnclaimedRows =
      await this.prisma.miningHourlyCheckpoint.groupBy({
        by: ['userId'],
        where: {
          userId: {
            in: userIds,
          },
          claimedAt: null,
          hourEndAt: {
            lte: asOf,
          },
        },
        _sum: {
          points: true,
        },
      });

    const maturedByUserId = new Map<string, number>(
      maturedUnclaimedRows.map((row) => [row.userId, row._sum.points ?? 0]),
    );

    return {
      asOf,
      total,
      limit,
      offset,
      data: profiles.map((profile, index) => {
        const currentSession = profile.miningSessions[0] ?? null;
        const claimedTotalPoints = this.bigIntToNumber(
          profile.miningClaimedPoints,
        );
        const maturedUnclaimedPoints = maturedByUserId.get(profile.id) ?? 0;
        const lifetimeEarnedPoints =
          claimedTotalPoints + maturedUnclaimedPoints;
        const sessionStatus: MiningSessionStatus = !currentSession
          ? ('idle' as MiningSessionStatus)
          : currentSession.endsAt.getTime() <= asOf.getTime()
            ? ('claimable' as MiningSessionStatus)
            : ('running' as MiningSessionStatus);

        return {
          rank: offset + index + 1,
          userId: profile.id,
          email: options.includePrivateFields ? profile.email : undefined,
          username: profile.username,
          displayName: profile.displayName,
          avatarUrl: profile.avatarUrl,
          primaryBadge: profile.primaryBadge ?? null,
          claimedTotalPoints,
          maturedUnclaimedPoints,
          lifetimeEarnedPoints,
          sessionStatus,
          sessionProgressPct: currentSession
            ? this.miningCalculator.computeProgressPct(
                currentSession.startsAt,
                currentSession.endsAt,
                asOf,
              )
            : 0,
          sessionEndsAt: currentSession?.endsAt ?? null,
          boostBpsSnapshot: currentSession?.boostBpsSnapshot ?? 0,
          activeReferralsSnapshot: currentSession?.activeReferralsSnapshot ?? 0,
        };
      }),
    };
  }

  private bigIntToNumber(value: bigint | number): number {
    return typeof value === 'bigint' ? Number(value) : Number(value);
  }
}
