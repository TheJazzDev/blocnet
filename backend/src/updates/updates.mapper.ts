import { Prisma } from '@prisma/client';

export const updateInclude = {
  author: {
    select: {
      id: true,
      email: true,
      displayName: true,
      avatarUrl: true,
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
} satisfies Prisma.UpdateInclude;

export type UpdateWithRelations = Prisma.UpdateGetPayload<{
  include: typeof updateInclude;
}>;

export function toUpdateResponse(update: UpdateWithRelations) {
  const rawUsername = update.author.email?.split('@')[0] ?? update.author.id;
  const normalized = rawUsername
    .toLowerCase()
    .replace(/[^a-z0-9._-]/g, '')
    .trim();
  const fallbackUsername = update.author.id.slice(0, 6);
  const username = `@${normalized || fallbackUsername}`;

  return {
    ...update,
    author: update.author,
    admin: {
      id: update.author.id,
      name: update.author.displayName ?? update.author.email ?? 'Admin',
      username,
      imageUrl: update.author.avatarUrl ?? '',
      followers: 0,
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
  };
}
