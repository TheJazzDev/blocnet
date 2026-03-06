import { ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CommunityModerationEnforcementService {
  constructor(private readonly prisma: PrismaService) {}

  async assertCanCreateCommunityPost(userId: string): Promise<void> {
    const state = await this.loadProfileModerationState(userId);
    const now = new Date();

    if (state.communitySuspendedUntil && state.communitySuspendedUntil > now) {
      throw new ForbiddenException(
        `Your account is suspended from community participation until ${state.communitySuspendedUntil.toISOString()}`,
      );
    }

    if (state.communityMutedUntil && state.communityMutedUntil > now) {
      throw new ForbiddenException(
        `Your account is muted from community participation until ${state.communityMutedUntil.toISOString()}`,
      );
    }

    if (
      state.communityPostingRestrictedUntil &&
      state.communityPostingRestrictedUntil > now
    ) {
      throw new ForbiddenException(
        `Posting is restricted until ${state.communityPostingRestrictedUntil.toISOString()}`,
      );
    }
  }

  async assertCanCreateComment(userId: string): Promise<void> {
    const state = await this.loadProfileModerationState(userId);
    const now = new Date();

    if (state.communitySuspendedUntil && state.communitySuspendedUntil > now) {
      throw new ForbiddenException(
        `Your account is suspended from commenting until ${state.communitySuspendedUntil.toISOString()}`,
      );
    }

    if (state.communityMutedUntil && state.communityMutedUntil > now) {
      throw new ForbiddenException(
        `Your account is muted from commenting until ${state.communityMutedUntil.toISOString()}`,
      );
    }

    if (
      state.communityCommentingRestrictedUntil &&
      state.communityCommentingRestrictedUntil > now
    ) {
      throw new ForbiddenException(
        `Commenting is restricted until ${state.communityCommentingRestrictedUntil.toISOString()}`,
      );
    }
  }

  private async loadProfileModerationState(userId: string) {
    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: {
        id: true,
        communityMutedUntil: true,
        communitySuspendedUntil: true,
        communityPostingRestrictedUntil: true,
        communityCommentingRestrictedUntil: true,
      },
    });

    if (!profile) {
      throw new ForbiddenException('User profile not found');
    }

    return profile;
  }
}
