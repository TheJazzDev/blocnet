import { ForbiddenException } from '@nestjs/common';
import { CommunityModerationEnforcementService } from './community-moderation-enforcement.service';

describe('CommunityModerationEnforcementService', () => {
  function createService() {
    const prisma = {
      profile: {
        findUnique: jest.fn(),
      },
    } as any;

    const service = new CommunityModerationEnforcementService(prisma);
    return { service, prisma };
  }

  it('blocks posting while posting restriction is active', async () => {
    const { service, prisma } = createService();
    prisma.profile.findUnique.mockResolvedValue({
      id: 'user-1',
      communityMutedUntil: null,
      communitySuspendedUntil: null,
      communityPostingRestrictedUntil: new Date(Date.now() + 60_000),
      communityCommentingRestrictedUntil: null,
    });

    await expect(service.assertCanCreateCommunityPost('user-1')).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('blocks commenting while mute is active', async () => {
    const { service, prisma } = createService();
    prisma.profile.findUnique.mockResolvedValue({
      id: 'user-2',
      communityMutedUntil: new Date(Date.now() + 60_000),
      communitySuspendedUntil: null,
      communityPostingRestrictedUntil: null,
      communityCommentingRestrictedUntil: null,
    });

    await expect(service.assertCanCreateComment('user-2')).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });
});
