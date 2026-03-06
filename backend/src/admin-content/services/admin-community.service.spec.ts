import { ContentModerationStatus } from '@prisma/client';
import { ForbiddenException } from '@nestjs/common';
import { AppRole } from '../../common/enums/role.enum';
import { AdminCommunityService } from './admin-community.service';

describe('AdminCommunityService', () => {
  function createService() {
    const prisma = {
      communityPost: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      communityPostComment: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
    } as any;

    const auditLogService = {
      create: jest.fn().mockResolvedValue(undefined),
    } as any;

    const service = new AdminCommunityService(prisma, auditLogService);
    return { service, prisma, auditLogService };
  }

  it('blocks community moderator from archiving community posts', async () => {
    const { service, prisma } = createService();

    await expect(
      service.moderateCommunityPostStatus(
        {
          id: 'actor-1',
          email: 'mod@blocnet.app',
          roles: [AppRole.COMMUNITY_MODERATOR],
        } as any,
        'post-1',
        {
          status: ContentModerationStatus.archived,
          reason: 'Escalated abuse',
        },
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);

    expect(prisma.communityPost.findUnique).not.toHaveBeenCalled();
    expect(prisma.communityPost.update).not.toHaveBeenCalled();
  });

  it('allows community admin to archive community posts', async () => {
    const { service, prisma, auditLogService } = createService();

    prisma.communityPost.findUnique.mockResolvedValue({
      id: 'post-1',
      status: ContentModerationStatus.hidden,
    });
    prisma.communityPost.update.mockResolvedValue({
      id: 'post-1',
      status: ContentModerationStatus.archived,
    });

    await service.moderateCommunityPostStatus(
      {
        id: 'actor-2',
        email: 'community-admin@blocnet.app',
        roles: [AppRole.COMMUNITY_ADMIN],
      } as any,
      'post-1',
      {
        status: ContentModerationStatus.archived,
        reason: 'Policy archive',
      },
    );

    expect(prisma.communityPost.findUnique).toHaveBeenCalled();
    expect(prisma.communityPost.update).toHaveBeenCalled();
    expect(auditLogService.create).toHaveBeenCalled();
  });
});
