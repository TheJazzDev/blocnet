import { Prisma } from '@prisma/client';
import { currentLevelSelect, toCurrentLevelDto } from '../levels/level-summary';

export const updateInclude = {
  author: {
    select: {
      id: true,
      email: true,
      username: true,
      displayName: true,
      avatarUrl: true,
      roles: {
        select: {
          role: true,
        },
      },
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
    },
  },
  project: {
    select: {
      id: true,
      name: true,
      description: true,
      primaryTag: {
        select: {
          id: true,
          name: true,
          slug: true,
        },
      },
      ownerAdminId: true,
      createdAt: true,
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
  _count: {
    select: {
      comments: true,
      likes: true,
      bookmarks: true,
    },
  },
} satisfies Prisma.UpdateInclude;

/**
 * `updateInclude` plus whether this viewer liked or saved each update.
 *
 * Both are filtered, `take: 1` relations, so under `relationLoadStrategy:
 * 'join'` they ride the same lateral join as the rest and add no round trip.
 */
export function updateIncludeFor(viewerId: string) {
  return {
    ...updateInclude,
    likes: {
      where: { userId: viewerId },
      select: { id: true },
      take: 1,
    },
    bookmarks: {
      where: { userId: viewerId },
      select: { id: true },
      take: 1,
    },
  } satisfies Prisma.UpdateInclude;
}

export type UpdateWithRelations = Prisma.UpdateGetPayload<{
  include: typeof updateInclude;
}> & {
  likes?: { id: string }[];
  bookmarks?: { id: string }[];
};

export function toUpdateResponse(
  rawUpdate: UpdateWithRelations,
  options?: { isCommented?: boolean },
) {
  // The viewer rows only feed the two flags; they are not part of the payload.
  const { likes, bookmarks, ...update } = rawUpdate;

  const rawUsername = (update.author.username ?? '').replaceAll('@', '').trim();
  const normalized = rawUsername.toLowerCase().replace(/[^a-z0-9._-]/g, '');
  const fallbackUsername = update.author.id.slice(0, 6);
  const username = `@${normalized || fallbackUsername}`;
  const displayName = update.author.displayName?.trim() || 'Blocnet Member';

  return {
    ...update,
    author: {
      id: update.author.id,
      displayName: update.author.displayName,
      username: update.author.username,
      avatarUrl: update.author.avatarUrl,
    },
    admin: {
      id: update.author.id,
      name: displayName,
      username,
      imageUrl: update.author.avatarUrl ?? '',
      followers: 0,
      roles: update.author.roles.map((entry) => entry.role),
      primaryBadge: update.author.primaryBadge ?? null,
      currentLevel: toCurrentLevelDto(update.author.currentLevel),
    },
    project: {
      id: update.project.id,
      name: update.project.name,
      description: update.project.description,
      details: update.project.description,
      primaryTagId: update.project.primaryTag.id,
      primaryTag: update.project.primaryTag.name,
      adminId: update.project.ownerAdminId,
      createdAt: update.project.createdAt,
    },
    secondaryTagIds: update.secondaryTags.map((row) => row.secondaryTag.id),
    secondaryTags: update.secondaryTags.map((row) => row.secondaryTag.name),
    commentsCount: update._count?.comments ?? 0,
    likesCount: update._count?.likes ?? 0,
    bookmarksCount: update._count?.bookmarks ?? 0,
    likedByMe: (likes?.length ?? 0) > 0,
    bookmarkedByMe: (bookmarks?.length ?? 0) > 0,
    isCommented: options?.isCommented === true,
  };
}
