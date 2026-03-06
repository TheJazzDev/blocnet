import { ForbiddenException } from '@nestjs/common';
import { AppRole } from '../common/enums/role.enum';
import { CommunityModerationService } from './community-moderation.service';

describe('CommunityModerationService', () => {
  function createService() {
    const prisma = {
      communityPost: {
        findUnique: jest.fn(),
      },
      communityPostComment: {
        findUnique: jest.fn(),
      },
      communityModerationReport: {
        create: jest.fn(),
        findMany: jest.fn(),
        count: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      profile: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      communityModerationAction: {
        create: jest.fn(),
      },
    } as any;

    const auditLogService = {
      create: jest.fn().mockResolvedValue(undefined),
    } as any;

    const service = new CommunityModerationService(prisma, auditLogService);
    return { service, prisma, auditLogService };
  }

  it('blocks community moderator mute above 72 hours', async () => {
    const { service, prisma } = createService();

    prisma.profile.findUnique.mockResolvedValue({
      id: 'target-1',
      email: 'user@blocnet.app',
      displayName: 'User',
      communityMutedUntil: null,
      communitySuspendedUntil: null,
      communityPostingRestrictedUntil: null,
      communityCommentingRestrictedUntil: null,
      communityLastWarnedAt: null,
      roles: [{ role: 'user' }],
    });

    await expect(
      service.applyMute(
        {
          id: 'actor-1',
          email: 'mod@blocnet.app',
          roles: [AppRole.COMMUNITY_MODERATOR],
        } as any,
        'target-1',
        {
          durationHours: 100,
          reason: 'Repeated spam',
        },
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);

    expect(prisma.profile.update).not.toHaveBeenCalled();
  });

  it('blocks community moderator from applying suspension', async () => {
    const { service } = createService();

    await expect(
      service.applySuspension(
        {
          id: 'actor-2',
          email: 'mod2@blocnet.app',
          roles: [AppRole.COMMUNITY_MODERATOR],
        } as any,
        'target-2',
        {
          durationHours: 24,
          reason: 'Escalation test',
        },
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('allows community admin to apply suspension', async () => {
    const { service, prisma } = createService();

    prisma.profile.findUnique
      .mockResolvedValueOnce({
        id: 'target-3',
        email: 'member@blocnet.app',
        displayName: 'Member',
        communityMutedUntil: null,
        communitySuspendedUntil: null,
        communityPostingRestrictedUntil: null,
        communityCommentingRestrictedUntil: null,
        communityLastWarnedAt: null,
        roles: [{ role: 'user' }],
      })
      .mockResolvedValueOnce({
        id: 'target-3',
        email: 'member@blocnet.app',
        username: 'member',
        displayName: 'Member',
        communityWarnCount: 0,
        communityLastWarnedAt: null,
        communityMutedUntil: null,
        communitySuspendedUntil: new Date(),
        communityPostingRestrictedUntil: null,
        communityCommentingRestrictedUntil: null,
        roles: [{ role: 'user' }],
      });

    prisma.profile.update.mockResolvedValue({});
    prisma.communityModerationAction.create.mockResolvedValue({
      id: 'action-1',
    });

    await service.applySuspension(
      {
        id: 'actor-3',
        email: 'community-admin@blocnet.app',
        roles: [AppRole.COMMUNITY_ADMIN],
      } as any,
      'target-3',
      {
        durationHours: 24,
        reason: 'Serious policy violation',
      },
    );

    expect(prisma.profile.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'target-3' },
        data: expect.objectContaining({
          communitySuspendedUntil: expect.any(Date),
        }),
      }),
    );
    expect(prisma.communityModerationAction.create).toHaveBeenCalled();
  });

  it('blocks community moderator from sanctioning community admins', async () => {
    const { service, prisma } = createService();

    prisma.profile.findUnique.mockResolvedValue({
      id: 'target-4',
      email: 'community-admin@blocnet.app',
      displayName: 'Community Admin',
      communityMutedUntil: null,
      communitySuspendedUntil: null,
      communityPostingRestrictedUntil: null,
      communityCommentingRestrictedUntil: null,
      communityLastWarnedAt: null,
      roles: [{ role: 'community_admin' }],
    });

    await expect(
      service.applyMute(
        {
          id: 'actor-4',
          email: 'community-moderator@blocnet.app',
          roles: [AppRole.COMMUNITY_MODERATOR],
        } as any,
        'target-4',
        {
          durationHours: 12,
          reason: 'Role boundary check',
        },
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});
