import { Prisma } from '@prisma/client';

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
    },
  },
} satisfies Prisma.UpdateInclude;

export type UpdateWithRelations = Prisma.UpdateGetPayload<{
  include: typeof updateInclude;
}>;

export function toUpdateResponse(update: UpdateWithRelations) {
  const rawUsername = (update.author.username ?? '')
    .replaceAll('@', '')
    .trim();
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
    likesCount: 0,
  };
}
