import { Prisma } from '@prisma/client';
import type { OwnerReliabilityDto } from '../hunter-reliability/dto/hunter-reliability-response.dto';
import { currentLevelSelect, toCurrentLevelDto } from '../levels/level-summary';

export const projectInclude = {
  primaryTag: {
    select: {
      id: true,
      name: true,
      slug: true,
    },
  },
  secondaryTags: {
    select: {
      secondaryTag: {
        select: {
          id: true,
          name: true,
          slug: true,
        },
      },
    },
  },
  ownerAdmin: {
    select: {
      id: true,
      email: true,
      username: true,
      displayName: true,
      avatarUrl: true,
      currentLevel: {
        select: currentLevelSelect,
      },
    },
  },
  // Who keeps the gem, for the owner's reliability on the card. Ordered so
  // the earliest-assigned hunter is the one a card names.
  hunters: {
    select: { hunterId: true },
    orderBy: { createdAt: 'asc' },
  },
  _count: {
    select: {
      follows: true,
      updates: true,
    },
  },
} satisfies Prisma.ProjectInclude;

export type ProjectWithRelations = Prisma.ProjectGetPayload<{
  include: typeof projectInclude;
}>;

/**
 * [ownerReliability] is attached by the list and detail reads, which batch it;
 * other callers leave it null rather than pay for it.
 */
export function toProjectResponse(
  project: ProjectWithRelations,
  ownerReliability: OwnerReliabilityDto | null = null,
) {
  const {
    _count,
    ownerAdmin,
    primaryTag,
    secondaryTags,
    // Ownership is used for ownerReliability, not echoed to clients.
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    hunters: _hunters,
    ...rest
  } = project;
  const rawUsername = (ownerAdmin.username ?? '').replaceAll('@', '').trim();
  const normalized = rawUsername.toLowerCase().replace(/[^a-z0-9._-]/g, '');
  const username = `@${normalized || ownerAdmin.id.slice(0, 6)}`;
  const displayName = ownerAdmin.displayName?.trim() || 'Blocnet Member';

  return {
    ...rest,
    primaryTagId: primaryTag.id,
    primaryTag: primaryTag.name,
    secondaryTagIds: secondaryTags.map((row) => row.secondaryTag.id),
    secondaryTags: secondaryTags.map((row) => row.secondaryTag.name),
    followersCount: _count.follows,
    updatesCount: _count.updates,
    admin: {
      id: ownerAdmin.id,
      name: displayName,
      username,
      imageUrl: ownerAdmin.avatarUrl ?? '',
      followers: _count.follows,
      currentLevel: toCurrentLevelDto(ownerAdmin.currentLevel),
    },
    ownerReliability,
  };
}
