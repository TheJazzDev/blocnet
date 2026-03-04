import { CommunityReactionKind, Prisma } from '@prisma/client';

const authorSelect = {
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
      pointsRequirement: true,
      isActive: true,
      sortOrder: true,
      createdAt: true,
    },
  },
  currentLevel: {
    select: {
      id: true,
      slug: true,
      name: true,
      description: true,
      iconUrl: true,
      level: true,
      requiredBnp: true,
      requiredComments: true,
      requiredDaysActive: true,
      requiredQuests: true,
      requiredUpdates: true,
      requiredProjects: true,
      color: true,
      isActive: true,
      sortOrder: true,
    },
  },
} satisfies Prisma.ProfileSelect;

export const communityPostCommentInclude = {
  author: {
    select: authorSelect,
  },
} satisfies Prisma.CommunityPostCommentInclude;

export function buildCommunityPostInclude(viewerId: string) {
  return {
    author: {
      select: authorSelect,
    },
    _count: {
      select: {
        comments: true,
        reactions: true,
      },
    },
    reactions: {
      where: {
        userId: viewerId,
        kind: CommunityReactionKind.like,
      },
      select: {
        id: true,
      },
      take: 1,
    },
    bookmarks: {
      where: {
        userId: viewerId,
      },
      select: {
        id: true,
      },
      take: 1,
    },
  } satisfies Prisma.CommunityPostInclude;
}

export type CommunityPostWithViewerState = Prisma.CommunityPostGetPayload<{
  include: ReturnType<typeof buildCommunityPostInclude>;
}>;

export type CommunityPostCommentWithAuthor =
  Prisma.CommunityPostCommentGetPayload<{
    include: typeof communityPostCommentInclude;
  }>;

function toActorPreview(actor: {
  id: string;
  email: string;
  username: string | null;
  displayName: string | null;
  avatarUrl: string | null;
  roles: Array<{ role: string }>;
  primaryBadge: {
    id: string;
    slug: string;
    name: string;
    description: string;
    imageUrl: string;
    category: string;
    rarity: string;
    pointsRequirement: number;
    isActive: boolean;
    sortOrder: number;
    createdAt: Date;
  } | null;
  currentLevel: {
    id: string;
    slug: string;
    name: string;
    description: string;
    iconUrl: string;
    level: number;
    requiredBnp: bigint;
    requiredComments: number;
    requiredDaysActive: number;
    requiredQuests: number;
    requiredUpdates: number;
    requiredProjects: number;
    color: string | null;
    isActive: boolean;
    sortOrder: number;
  } | null;
}) {
  const rawUsername = (actor.username ?? '')
    .replaceAll('@', '')
    .trim();
  const normalized = rawUsername.toLowerCase().replace(/[^a-z0-9._-]/g, '');
  const displayName = actor.displayName?.trim() || 'Blocnet Member';

  return {
    id: actor.id,
    name: displayName,
    username: `@${normalized || actor.id.slice(0, 6)}`,
    imageUrl: actor.avatarUrl ?? '',
    followers: 0,
    roles: actor.roles.map((entry) => entry.role),
    primaryBadge: actor.primaryBadge,
    currentLevel: actor.currentLevel
      ? {
          id: actor.currentLevel.id,
          slug: actor.currentLevel.slug,
          name: actor.currentLevel.name,
          description: actor.currentLevel.description,
          iconUrl: actor.currentLevel.iconUrl,
          level: actor.currentLevel.level,
          requiredBnp: actor.currentLevel.requiredBnp.toString(),
          requiredComments: actor.currentLevel.requiredComments,
          requiredDaysActive: actor.currentLevel.requiredDaysActive,
          requiredQuests: actor.currentLevel.requiredQuests,
          requiredUpdates: actor.currentLevel.requiredUpdates,
          requiredProjects: actor.currentLevel.requiredProjects,
          color: actor.currentLevel.color,
          isActive: actor.currentLevel.isActive,
          sortOrder: actor.currentLevel.sortOrder,
        }
      : null,
  };
}

export function toCommunityPostResponse(post: CommunityPostWithViewerState) {
  return {
    id: post.id,
    authorId: post.authorId,
    topic: post.topic,
    content: post.content,
    createdAt: post.createdAt,
    updatedAt: post.updatedAt,
    likesCount: post._count.reactions,
    commentsCount: post._count.comments,
    isLiked: post.reactions.length > 0,
    isBookmarked: post.bookmarks.length > 0,
    author: {
      id: post.author.id,
      displayName: post.author.displayName,
      username: post.author.username,
      avatarUrl: post.author.avatarUrl,
    },
    admin: toActorPreview(post.author),
  };
}

export function toCommunityPostCommentResponse(
  comment: CommunityPostCommentWithAuthor,
) {
  return {
    id: comment.id,
    postId: comment.postId,
    authorId: comment.authorId,
    content: comment.content,
    createdAt: comment.createdAt,
    updatedAt: comment.updatedAt,
    author: {
      id: comment.author.id,
      displayName: comment.author.displayName,
      username: comment.author.username,
      avatarUrl: comment.author.avatarUrl,
    },
    admin: toActorPreview(comment.author),
  };
}
