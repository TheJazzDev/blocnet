import { Prisma } from '@prisma/client';
import { currentLevelSelect } from '../levels/level-summary';

/** Board order: most claimed points first, earliest member wins a tie. */
export const leaderboardOrderBy: Prisma.ProfileOrderByWithRelationInput[] = [
  { miningClaimedPoints: 'desc' },
  { createdAt: 'asc' },
];

export const leaderboardProfileSelect = {
  id: true,
  email: true,
  username: true,
  displayName: true,
  avatarUrl: true,
  createdAt: true,
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
  currentLevel: {
    select: currentLevelSelect,
  },
  miningSessions: {
    where: {
      claimedAt: null,
      expiredAt: null,
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
} satisfies Prisma.ProfileSelect;

export type LeaderboardProfile = Prisma.ProfileGetPayload<{
  select: typeof leaderboardProfileSelect;
}>;

/**
 * Who has a place on the board at all: active members with claimed or
 * matured unclaimed points. A member with 0 claimed and 0 unclaimed points
 * has nothing to rank; starting a cycle alone no longer earns a place (F-61).
 */
export function buildRankedWhere(asOf: Date): Prisma.ProfileWhereInput[] {
  return [
    {
      OR: [
        {
          miningClaimedPoints: {
            gt: BigInt(0),
          },
        },
        {
          miningHourlyCheckpoints: {
            some: {
              claimedAt: null,
              expiredAt: null,
              points: {
                gt: 0,
              },
              hourEndAt: {
                lte: asOf,
              },
            },
          },
        },
      ],
    },
  ];
}

export function buildSearchFilters(
  searchQuery: string | undefined,
  includePrivateFields: boolean,
): Prisma.ProfileWhereInput[] {
  if (!searchQuery) {
    return [];
  }

  const filters: Prisma.ProfileWhereInput[] = [
    { displayName: { contains: searchQuery, mode: 'insensitive' } },
    { username: { contains: searchQuery, mode: 'insensitive' } },
  ];

  if (includePrivateFields) {
    filters.push({ email: { contains: searchQuery, mode: 'insensitive' } });
  }

  if (searchQuery.length >= 8) {
    filters.push({ id: searchQuery });
  }

  return filters;
}

export function buildLeaderboardWhere(
  asOf: Date,
  searchFilters: Prisma.ProfileWhereInput[] = [],
): Prisma.ProfileWhereInput {
  return {
    isDeactivated: false,
    AND: [
      ...buildRankedWhere(asOf),
      ...(searchFilters.length > 0 ? [{ OR: searchFilters }] : []),
    ],
  };
}

/**
 * Profiles that sort strictly ahead of `profile` under `leaderboardOrderBy`,
 * within the unsearched board. Counting these gives the member's rank - 1.
 */
export function buildAheadOfWhere(
  asOf: Date,
  profile: Pick<LeaderboardProfile, 'miningClaimedPoints' | 'createdAt'>,
): Prisma.ProfileWhereInput {
  const where = buildLeaderboardWhere(asOf);
  return {
    ...where,
    AND: [
      ...(where.AND as Prisma.ProfileWhereInput[]),
      {
        OR: [
          { miningClaimedPoints: { gt: profile.miningClaimedPoints } },
          {
            miningClaimedPoints: profile.miningClaimedPoints,
            createdAt: { lt: profile.createdAt },
          },
        ],
      },
    ],
  };
}
