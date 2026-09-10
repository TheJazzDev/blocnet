import { BadRequestException } from '@nestjs/common';
import { UpdateStatus } from '@prisma/client';
import { CommentsService } from './comments.service';

describe('CommentsService.createComment — reply validation', () => {
  const actor = { id: 'user-1', roles: [] } as any;

  const prisma = {
    update: { findUnique: jest.fn() },
    comment: { findUnique: jest.fn(), create: jest.fn() },
  };

  const auditLogService = { create: jest.fn() };
  const badgesService = { checkEngagementMilestones: jest.fn() };
  const blocksService = {};
  const communityModerationEnforcementService = {
    assertCanCreateComment: jest.fn(),
  };
  const levelsService = { updateUserLevel: jest.fn() };
  const questsService = { checkAndCompleteByAction: jest.fn() };
  const mentionsService = { createCommentMentions: jest.fn() };

  let service: CommentsService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new CommentsService(
      prisma as any,
      auditLogService as any,
      badgesService as any,
      blocksService as any,
      communityModerationEnforcementService as any,
      levelsService as any,
      questsService as any,
      mentionsService as any,
    );
    prisma.update.findUnique.mockResolvedValue({
      id: 'update-1',
      projectId: 'project-1',
      status: UpdateStatus.published,
    });
  });

  it('rejects a replyToId that belongs to a different update', async () => {
    prisma.comment.findUnique.mockResolvedValue({
      id: 'comment-other',
      updateId: 'some-other-update',
    });

    await expect(
      service.createComment(actor, 'update-1', {
        content: 'hi',
        replyToId: 'comment-other',
      } as any),
    ).rejects.toThrow(BadRequestException);

    expect(prisma.comment.create).not.toHaveBeenCalled();
  });

  it('rejects a replyToId that does not exist at all', async () => {
    prisma.comment.findUnique.mockResolvedValue(null);

    await expect(
      service.createComment(actor, 'update-1', {
        content: 'hi',
        replyToId: 'does-not-exist',
      } as any),
    ).rejects.toThrow(BadRequestException);

    expect(prisma.comment.create).not.toHaveBeenCalled();
  });

  it('allows a replyToId that belongs to the same update', async () => {
    prisma.comment.findUnique.mockResolvedValue({
      id: 'comment-parent',
      updateId: 'update-1',
    });
    prisma.comment.create.mockResolvedValue({
      id: 'comment-new',
      author: {
        id: 'user-1',
        username: 'jazzdev',
        displayName: 'Jazz',
        roles: [],
      },
      _count: { reactions: 0 },
      reactions: [],
    });

    await service.createComment(actor, 'update-1', {
      content: 'hi',
      replyToId: 'comment-parent',
    } as any);

    expect(prisma.comment.create).toHaveBeenCalled();
  });

  it('skips the reply check entirely for a top-level comment', async () => {
    prisma.comment.create.mockResolvedValue({
      id: 'comment-new',
      author: {
        id: 'user-1',
        username: 'jazzdev',
        displayName: 'Jazz',
        roles: [],
      },
      _count: { reactions: 0 },
      reactions: [],
    });

    await service.createComment(actor, 'update-1', {
      content: 'hi',
    } as any);

    expect(prisma.comment.findUnique).not.toHaveBeenCalled();
    expect(prisma.comment.create).toHaveBeenCalled();
  });
});
