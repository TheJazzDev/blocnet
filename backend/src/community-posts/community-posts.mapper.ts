import { CommunityReactionKind, Prisma } from '@prisma/client';

const authorSelect = {
  id: true,
  email: true,
  displayName: true,
  avatarUrl: true,
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
  displayName: string | null;
  avatarUrl: string | null;
}) {
  const rawUsername = actor.email?.split('@')[0] ?? actor.id;
  const normalized = rawUsername
    .toLowerCase()
    .replace(/[^a-z0-9._-]/g, '')
    .trim();

  return {
    id: actor.id,
    name: actor.displayName ?? actor.email ?? 'User',
    username: `@${normalized || actor.id.slice(0, 6)}`,
    imageUrl: actor.avatarUrl ?? '',
    followers: 0,
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
    author: post.author,
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
    author: comment.author,
    admin: toActorPreview(comment.author),
  };
}
