import { Prisma } from '@prisma/client';

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
      displayName: true,
      avatarUrl: true,
    },
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

export function toProjectResponse(project: ProjectWithRelations) {
  const { _count, ownerAdmin, primaryTag, secondaryTags, ...rest } = project;
  const rawUsername = ownerAdmin.email?.split('@')[0] ?? ownerAdmin.id;
  const normalized = rawUsername
    .toLowerCase()
    .replace(/[^a-z0-9._-]/g, '')
    .trim();
  const username = `@${normalized || ownerAdmin.id.slice(0, 6)}`;

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
      name: ownerAdmin.displayName ?? ownerAdmin.email ?? 'Admin',
      username,
      imageUrl: ownerAdmin.avatarUrl ?? '',
      followers: _count.follows,
    },
  };
}
