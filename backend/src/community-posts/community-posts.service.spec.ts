import { BadRequestException } from '@nestjs/common';
import { ContentModerationStatus } from '@prisma/client';
import { CommunityPostsService } from './community-posts.service';

describe('CommunityPostsService.createComment — reply validation', () => {
  const actor = { id: 'user-1', roles: [] } as any;

  const prisma = {
    communityPost: { findFirst: jest.fn() },
    communityPostComment: { findUnique: jest.fn(), create: jest.fn() },
  };

  const auditLogService = { create: jest.fn() };
  const blocksService = {};
  const communityModerationEnforcementService = {
    assertCanCreateComment: jest.fn(),
  };
  const levelsService = { updateUserLevel: jest.fn() };
  const mentionsService = { createCommunityPostCommentMentions: jest.fn() };

  let service: CommunityPostsService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new CommunityPostsService(
      prisma as any,
      auditLogService as any,
      blocksService as any,
      communityModerationEnforcementService as any,
      levelsService as any,
      mentionsService as any,
    );
    prisma.communityPost.findFirst.mockResolvedValue({ id: 'post-1' });
  });

  it('rejects a replyToId that belongs to a different post', async () => {
    prisma.communityPostComment.findUnique.mockResolvedValue({
      id: 'comment-other',
      postId: 'some-other-post',
    });

    await expect(
      service.createComment(actor, 'post-1', {
        content: 'hi',
        replyToId: 'comment-other',
      } as any),
    ).rejects.toThrow(BadRequestException);

    expect(prisma.communityPostComment.create).not.toHaveBeenCalled();
  });

  it('rejects a replyToId that does not exist at all', async () => {
    prisma.communityPostComment.findUnique.mockResolvedValue(null);

    await expect(
      service.createComment(actor, 'post-1', {
        content: 'hi',
        replyToId: 'does-not-exist',
      } as any),
    ).rejects.toThrow(BadRequestException);

    expect(prisma.communityPostComment.create).not.toHaveBeenCalled();
  });

  it('allows a replyToId that belongs to the same post', async () => {
    prisma.communityPostComment.findUnique.mockResolvedValue({
      id: 'comment-parent',
      postId: 'post-1',
    });
    prisma.communityPostComment.create.mockResolvedValue({
      id: 'comment-new',
      postId: 'post-1',
      authorId: 'user-1',
      content: 'hi',
      status: ContentModerationStatus.active,
      createdAt: new Date(),
      updatedAt: new Date(),
      replyToId: 'comment-parent',
      replyTo: null,
      _count: { reactions: 0 },
      reactions: [],
      author: {
        id: 'user-1',
        email: 'user1@blocnet.app',
        username: 'jazzdev',
        displayName: 'Jazz',
        avatarUrl: null,
        roles: [],
        primaryBadge: null,
        currentLevel: null,
      },
    });

    await service.createComment(actor, 'post-1', {
      content: 'hi',
      replyToId: 'comment-parent',
    } as any);

    expect(prisma.communityPostComment.create).toHaveBeenCalled();
  });
});
