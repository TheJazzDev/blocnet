import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import {
  ContentModerationStatus,
  Prisma,
  ProjectStatus,
  RoleName,
  UpdateStatus,
  UpdateUrgency,
} from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import {
  buildCommunityPostInclude,
  toCommunityPostResponse,
} from '../community-posts/community-posts.mapper';
import { projectInclude, toProjectResponse } from '../projects/projects.mapper';
import { PrismaService } from '../prisma/prisma.service';
import { QuestsService } from '../quests/quests.service';
import { normalizePagination } from '../common/utils/pagination.util';
import { UpdateMeDto } from './dto/update-me.dto';
import { UserAvatarService, UploadedAvatarFile } from './user-avatar.service';

type PaginationInput = {
  limit?: number;
  offset?: number;
};

const PROFILE_ACTIVITY_ALLOWED_ACTIONS = [
  'comment.create',
  'comment.update',
  'comment.delete',
  'community_post.create',
  'community_post.comment.create',
  'community_post.reaction.add',
  'community_post.reaction.remove',
  'community_post.bookmark.add',
  'community_post.bookmark.remove',
  'follow.preferences.update',
  'mining.start',
  'mining.claim',
  'profile.follow',
  'profile.unfollow',
  'project.create',
  'project.update',
  'project.follow',
  'project.unfollow',
  'project_proposal.create',
  'radar.ack',
  'referral.bind',
  'update.create',
  'update.update',
] as const;

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
    private readonly questsService: QuestsService,
    private readonly userAvatarService: UserAvatarService,
  ) {}

  async getMe(userId: string) {
    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      include: {
        roles: {
          select: {
            role: true,
          },
        },
        follows: {
          select: {
            projectId: true,
            alertMinUrgency: true,
            mutedUntil: true,
          },
        },
        followingLinks: {
          select: {
            followeeId: true,
          },
        },
        _count: {
          select: {
            followerLinks: true,
            followingLinks: true,
            bookmarks: true,
          },
        },
        wallet: {
          select: {
            status: true,
            address: true,
          },
        },
        kycProfile: {
          select: {
            status: true,
          },
        },
      },
    });

    if (!profile) {
      return null;
    }
    if (profile.isDeactivated) {
      return null;
    }

    const avatarUrl = await this.userAvatarService.resolveAvatarAccessUrl(
      profile.avatarUrl,
    );
    if (
      avatarUrl &&
      profile.avatarUrl &&
      avatarUrl != profile.avatarUrl &&
      this.userAvatarService.isManagedPublicAvatarUrl(profile.avatarUrl)
    ) {
      try {
        await this.prisma.profile.update({
          where: { id: profile.id },
          data: { avatarUrl },
        });
      } catch {
        // Keep auth response resilient even if background avatar write fails.
      }
    }

    return {
      id: profile.id,
      email: profile.email,
      username: profile.username,
      referralCode: profile.referralCode,
      displayName: profile.displayName,
      avatarUrl,
      bio: profile.bio,
      createdAt: profile.createdAt,
      homeFeedLastSeenAt: profile.homeFeedLastSeenAt,
      roles: profile.roles.map((row) => row.role),
      followedProjectIds: profile.follows.map((row) => row.projectId),
      followedProjects: profile.follows.map((row) => ({
        projectId: row.projectId,
        alertMinUrgency: row.alertMinUrgency,
        mutedUntil: row.mutedUntil,
      })),
      followedProfileIds: profile.followingLinks.map((row) => row.followeeId),
      followersCount: profile._count.followerLinks,
      followingCount: profile._count.followingLinks,
      bookmarkCount: profile._count.bookmarks,
      walletStatus: profile.wallet?.status ?? null,
      walletAddress: profile.wallet?.address ?? null,
      kycStatus: profile.kycProfile?.status ?? null,
    };
  }

  async isUsernameTaken(
    username: string,
    excludeUserId?: string,
  ): Promise<boolean> {
    const profile = await this.prisma.profile.findUnique({
      where: { username: username.toLowerCase() },
      select: { id: true },
    });
    if (!profile) return false;
    if (excludeUserId && profile.id === excludeUserId) return false;
    return true;
  }

  async updateMe(userId: string, dto: UpdateMeDto) {
    if (dto.bio !== undefined && dto.bio.length > 300) {
      throw new BadRequestException('Bio must be 300 characters or less');
    }

    await this.prisma.profile.update({
      where: { id: userId },
      data: {
        displayName: dto.displayName,
        avatarUrl: dto.avatarUrl,
        bio: dto.bio,
      },
    });

    await this.triggerProfileCompleteQuestIfEligible(userId);
    const me = await this.getMe(userId);
    if (!me) {
      throw new NotFoundException('Active profile not found');
    }

    return me;
  }

  async uploadMyAvatar(userId: string, file: UploadedAvatarFile) {
    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: {
        id: true,
        avatarUrl: true,
        isDeactivated: true,
      },
    });
    if (!profile || profile.isDeactivated) {
      throw new NotFoundException('Active profile not found');
    }

    const avatarUrl = await this.userAvatarService.uploadAvatar(userId, file);

    await this.prisma.profile.update({
      where: { id: userId },
      data: { avatarUrl },
    });

    await this.userAvatarService.deletePreviousAvatarIfManaged(
      profile.avatarUrl,
      avatarUrl,
    );
    await this.triggerProfileCompleteQuestIfEligible(userId);

    return { avatarUrl };
  }

  async getPublicProfile(userId: string) {
    const [profile, updates] = await Promise.all([
      this.prisma.profile.findUnique({
        where: { id: userId },
        include: {
          roles: {
            select: {
              role: true,
            },
          },
          _count: {
            select: {
              authoredUpdates: true,
              authoredComments: true,
              ownedProjects: true,
              followerLinks: true,
              followingLinks: true,
            },
          },
        },
      }),
      this.prisma.update.findMany({
        where: {
          authorId: userId,
          status: { not: UpdateStatus.hidden },
        },
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          urgency: true,
          createdAt: true,
        },
      }),
    ]);

    if (!profile) {
      return null;
    }

    const now = new Date();
    const since7d = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const since30d = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    const updatesLast7d = updates.filter(
      (update) => update.createdAt >= since7d,
    ).length;
    const updatesLast30d = updates.filter(
      (update) => update.createdAt >= since30d,
    ).length;
    const highUrgencyLast30d = updates.filter(
      (update) =>
        update.createdAt >= since30d && update.urgency === UpdateUrgency.high,
    ).length;
    const highUrgencyShare30d =
      updatesLast30d === 0
        ? 0
        : Number(((highUrgencyLast30d / updatesLast30d) * 100).toFixed(2));

    const intervalsInHours: number[] = [];
    for (let index = 0; index < updates.length - 1; index += 1) {
      const current = updates[index];
      const next = updates[index + 1];
      const hours =
        (current.createdAt.getTime() - next.createdAt.getTime()) / 3600000;
      if (hours >= 0) {
        intervalsInHours.push(hours);
      }
    }
    intervalsInHours.sort((a, b) => a - b);

    const medianHoursBetweenUpdates =
      intervalsInHours.length === 0
        ? null
        : intervalsInHours.length % 2 === 1
          ? Number(
              intervalsInHours[Math.floor(intervalsInHours.length / 2)].toFixed(
                2,
              ),
            )
          : Number(
              (
                (intervalsInHours[intervalsInHours.length / 2 - 1] +
                  intervalsInHours[intervalsInHours.length / 2]) /
                2
              ).toFixed(2),
            );

    const lastActiveAt = updates.length > 0 ? updates[0].createdAt : null;

    return {
      id: profile.id,
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
      roles: profile.roles.map((row) => row.role),
      stats: {
        projectsCreated: profile._count.ownedProjects,
        updatesCreated: profile._count.authoredUpdates,
        commentsCreated: profile._count.authoredComments,
        followersCount: profile._count.followerLinks,
        followingCount: profile._count.followingLinks,
      },
      trust: {
        updatesLast7d,
        updatesLast30d,
        highUrgencyShare30d,
        medianHoursBetweenUpdates,
        lastActiveAt,
      },
      createdAt: profile.createdAt,
    };
  }

  async searchPublicProfiles(opts: {
    q?: string;
    role?: 'all' | 'hunter' | 'user';
    limit?: number;
    offset?: number;
  }) {
    const { limit, offset } = normalizePagination(opts.offset, opts.limit);
    const q = opts.q?.trim();
    const usernameQuery =
      q && q.startsWith('@') ? q.replace(/^@+/, '').trim() : q;
    const role = opts.role ?? 'all';

    const where: Prisma.ProfileWhereInput = {
      isDeactivated: false,
      ...(role === 'hunter'
        ? { roles: { some: { role: RoleName.hunter } } }
        : role === 'user'
          ? { roles: { none: { role: RoleName.hunter } } }
          : {}),
      ...(q
        ? {
            OR: [
              { displayName: { contains: q, mode: 'insensitive' } },
              { username: { contains: q, mode: 'insensitive' } },
              ...(usernameQuery && usernameQuery != q
                ? [
                    {
                      username: {
                        contains: usernameQuery,
                        mode: 'insensitive' as const,
                      },
                    },
                  ]
                : []),
              { email: { contains: q, mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const [rows, total] = await Promise.all([
      this.prisma.profile.findMany({
        where,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip: offset,
        take: limit,
        select: {
          id: true,
          displayName: true,
          username: true,
          avatarUrl: true,
          email: true,
          roles: {
            select: {
              role: true,
            },
          },
          _count: {
            select: {
              followerLinks: true,
            },
          },
        },
      }),
      this.prisma.profile.count({ where }),
    ]);

    return {
      data: rows.map((row) => ({
        id: row.id,
        displayName: row.displayName,
        username: row.username,
        avatarUrl: row.avatarUrl,
        followersCount: row._count.followerLinks,
        roles: row.roles.map((entry) => entry.role),
        // Keep this field for compatibility with Admin.fromApi fallback handling.
        email: row.email,
      })),
      total,
      limit,
      offset,
    };
  }

  async followProfile(followerId: string, followeeId: string) {
    if (followerId === followeeId) {
      throw new BadRequestException('You cannot follow your own profile');
    }

    const followee = await this.prisma.profile.findUnique({
      where: { id: followeeId },
      select: { id: true, isDeactivated: true },
    });

    if (!followee || followee.isDeactivated) {
      throw new NotFoundException('Profile not found');
    }

    const existing = await this.prisma.userFollow.findUnique({
      where: {
        followerId_followeeId: {
          followerId,
          followeeId,
        },
      },
      select: { id: true, followerId: true, followeeId: true, createdAt: true },
    });

    if (existing) {
      return existing;
    }

    const follow = await this.prisma.userFollow.create({
      data: {
        followerId,
        followeeId,
      },
    });

    await this.auditLogService.create({
      actorId: followerId,
      action: 'profile.follow',
      resourceType: 'user_follow',
      resourceId: follow.id,
      metadata: { followeeId, followerId },
    });

    return follow;
  }

  async unfollowProfile(followerId: string, followeeId: string) {
    if (followerId === followeeId) {
      throw new BadRequestException('You cannot unfollow your own profile');
    }

    const follow = await this.prisma.userFollow.findUnique({
      where: {
        followerId_followeeId: {
          followerId,
          followeeId,
        },
      },
      select: { id: true },
    });

    if (!follow) {
      return { deleted: false };
    }

    await this.prisma.userFollow.delete({ where: { id: follow.id } });

    await this.auditLogService.create({
      actorId: followerId,
      action: 'profile.unfollow',
      resourceType: 'user_follow',
      resourceId: follow.id,
      metadata: { followeeId, followerId },
    });

    return { deleted: true };
  }

  async listWatchlist(userId: string, opts: PaginationInput) {
    const { limit, offset } = normalizePagination(opts.offset, opts.limit);

    const follows = await this.prisma.projectFollow.findMany({
      where: {
        userId,
        project: {
          status: { not: ProjectStatus.hidden },
        },
      },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: limit,
      include: {
        project: {
          include: projectInclude,
        },
      },
    });

    return follows.map((row) => ({
      ...toProjectResponse(row.project),
      followedAt: row.createdAt,
    }));
  }

  async listBookmarks(userId: string, opts: PaginationInput) {
    const { limit, offset } = normalizePagination(opts.offset, opts.limit);

    const bookmarks = await this.prisma.bookmark.findMany({
      where: {
        userId,
        communityPost: {
          status: ContentModerationStatus.active,
        },
      },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: limit,
      include: {
        communityPost: {
          include: buildCommunityPostInclude(userId),
        },
      },
    });

    return bookmarks.map((bookmark) => ({
      ...toCommunityPostResponse(bookmark.communityPost),
      bookmarkedAt: bookmark.createdAt,
    }));
  }

  async listMyActivity(userId: string, opts: PaginationInput) {
    const { limit, offset } = normalizePagination(opts.offset, opts.limit);

    const rows = await this.prisma.auditLog.findMany({
      where: {
        actorId: userId,
        action: {
          in: [...PROFILE_ACTIVITY_ALLOWED_ACTIONS],
        },
      },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: limit,
    });

    return rows.map((row) => ({
      id: row.id,
      action: row.action,
      resourceType: row.resourceType,
      resourceId: row.resourceId,
      metadata: row.metadata,
      createdAt: row.createdAt,
    }));
  }

  private isProfileCompleteForQuest(profile: {
    displayName: string | null;
    username: string | null;
    avatarUrl: string | null;
    bio: string | null;
  }): boolean {
    return Boolean(
      profile.displayName?.trim() &&
      profile.username?.trim() &&
      profile.avatarUrl?.trim() &&
      profile.bio?.trim(),
    );
  }

  private async triggerProfileCompleteQuestIfEligible(userId: string) {
    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: {
        displayName: true,
        username: true,
        avatarUrl: true,
        bio: true,
      },
    });

    if (!profile || !this.isProfileCompleteForQuest(profile)) {
      return;
    }

    try {
      await this.questsService.checkAndCompleteByAction(
        userId,
        'profile_complete',
      );
    } catch (error) {
      this.logger.warn(
        `Failed to process auto quest trigger`,
        JSON.stringify({
          action: 'profile_complete',
          userId,
          error: error instanceof Error ? error.message : String(error),
        }),
      );
    }
  }

  async deactivateAccount(userId: string, reason?: string) {
    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: {
        id: true,
        isDeactivated: true,
        username: true,
        displayName: true,
        avatarUrl: true,
        bio: true,
      },
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    if (profile.isDeactivated) {
      throw new BadRequestException('Account is already deactivated');
    }

    const updated = await this.prisma.profile.update({
      where: { id: userId },
      data: {
        isDeactivated: true,
        deactivatedAt: new Date(),
        deactivatedBy: userId,
        deactivationReason: reason,
        previousUsername: profile.username,
        previousDisplayName: profile.displayName,
        previousAvatarUrl: profile.avatarUrl,
        previousBio: profile.bio,
      },
      select: {
        id: true,
        isDeactivated: true,
        deactivatedAt: true,
      },
    });

    await this.auditLogService.create({
      actorId: userId,
      action: 'account.deactivate',
      resourceType: 'profile',
      resourceId: userId,
      metadata: { reason },
    });

    return updated;
  }

  async reactivateAccount(userId: string) {
    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: {
        id: true,
        isDeactivated: true,
        previousUsername: true,
        previousDisplayName: true,
        previousAvatarUrl: true,
        previousBio: true,
      },
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    if (!profile.isDeactivated) {
      throw new BadRequestException('Account is not deactivated');
    }

    const updated = await this.prisma.profile.update({
      where: { id: userId },
      data: {
        isDeactivated: false,
        deactivatedAt: null,
        deactivatedBy: null,
        deactivationReason: null,
        username: profile.previousUsername,
        displayName: profile.previousDisplayName,
        avatarUrl: profile.previousAvatarUrl,
        bio: profile.previousBio,
        previousUsername: null,
        previousDisplayName: null,
        previousAvatarUrl: null,
        previousBio: null,
      },
      select: {
        id: true,
        isDeactivated: true,
        username: true,
        displayName: true,
      },
    });

    await this.auditLogService.create({
      actorId: userId,
      action: 'account.reactivate',
      resourceType: 'profile',
      resourceId: userId,
      metadata: {},
    });

    return updated;
  }
}
