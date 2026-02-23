import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  ContentModerationStatus,
  NotificationType,
  Prisma,
  ProjectStatus,
  RoleName,
  UpdateStatus,
  UpdateUrgency,
} from '@prisma/client';
import { randomUUID } from 'crypto';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { AuditLogService } from '../audit-log/audit-log.service';
import { AppRole } from '../common/enums/role.enum';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import {
  buildCommunityPostInclude,
  toCommunityPostResponse,
} from '../community-posts/community-posts.mapper';
import { projectInclude, toProjectResponse } from '../projects/projects.mapper';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { AdminDeleteUserDto } from './dto/admin-delete-user.dto';
import { AdminHardDeleteUserDto } from './dto/admin-hard-delete-user.dto';
import { AdminReactivateUserDto } from './dto/admin-reactivate-user.dto';
import { AdminUpdateUserDto } from './dto/admin-update-user.dto';
import { UpdateMeDto } from './dto/update-me.dto';

type PaginationInput = {
  limit?: number;
  offset?: number;
};

type UploadedAvatarFile = {
  buffer: Buffer;
  mimetype: string;
  size: number;
};

const AVATAR_MAX_BYTES = 5 * 1024 * 1024;
const ALLOWED_AVATAR_MIME_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
]);

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

const DIGEST_VIEW_AUDIT_COOLDOWN_MS = 60 * 60 * 1000;

@Injectable()
export class UsersService {
  private readonly supabaseUrl: string;
  private readonly supabaseAvatarsBucket: string;
  private readonly supabaseStorageClient: SupabaseClient | null;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    private readonly auditLogService: AuditLogService,
    private readonly notificationsService: NotificationsService,
  ) {
    this.supabaseUrl = this.configService.get<string>('SUPABASE_URL') ?? '';
    this.supabaseAvatarsBucket =
      this.configService.get<string>('SUPABASE_AVATARS_BUCKET') || 'avatars';
    const serviceRoleKey =
      this.configService.get<string>('SUPABASE_SECRET_KEY') ||
      this.configService.get<string>('SUPABASE_SERVICE_ROLE_KEY');

    if (this.supabaseUrl && serviceRoleKey) {
      this.supabaseStorageClient = createClient(
        this.supabaseUrl,
        serviceRoleKey,
        {
          auth: {
            autoRefreshToken: false,
            persistSession: false,
          },
        },
      );
    } else {
      this.supabaseStorageClient = null;
    }
  }

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

    return {
      id: profile.id,
      email: profile.email,
      username: profile.username,
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
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

    return this.prisma.profile.update({
      where: { id: userId },
      data: {
        displayName: dto.displayName,
        avatarUrl: dto.avatarUrl,
        bio: dto.bio,
      },
    });
  }

  async uploadMyAvatar(userId: string, file: UploadedAvatarFile) {
    if (!file) {
      throw new BadRequestException('Avatar file is required');
    }
    if (!ALLOWED_AVATAR_MIME_TYPES.has(file.mimetype)) {
      throw new BadRequestException(
        'Unsupported avatar format. Use JPEG, PNG, or WEBP.',
      );
    }
    if (file.size > AVATAR_MAX_BYTES) {
      throw new BadRequestException('Avatar must be 5MB or smaller');
    }

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

    const storageClient = this.requireSupabaseStorageClient();
    const extension = this.fileExtensionForMimeType(file.mimetype);
    const objectPath = `${userId}/${Date.now()}-${randomUUID()}.${extension}`;
    const bucket = storageClient.storage.from(this.supabaseAvatarsBucket);

    const { error: uploadError } = await bucket.upload(
      objectPath,
      file.buffer,
      {
        contentType: file.mimetype,
        upsert: false,
      },
    );

    if (uploadError) {
      throw new BadRequestException('Failed to upload avatar image');
    }

    const {
      data: { publicUrl },
    } = bucket.getPublicUrl(objectPath);

    await this.prisma.profile.update({
      where: { id: userId },
      data: { avatarUrl: publicUrl },
    });

    await this.deletePreviousAvatarIfManaged(profile.avatarUrl, objectPath);

    return { avatarUrl: publicUrl };
  }

  async getAdminStats() {
    const [
      totalProjects,
      totalUsers,
      activeUsers,
      deactivatedUsers,
      pendingAdminApps,
      totalUpdates,
      totalComments,
      activeHunters,
      pendingProposals,
      totalTags,
      usersWithPushEnabled,
    ] = await Promise.all([
      this.prisma.project.count(),
      this.prisma.profile.count(),
      this.prisma.profile.count({
        where: { isDeactivated: false },
      }),
      this.prisma.profile.count({
        where: { isDeactivated: true },
      }),
      this.prisma.adminApplication.count({ where: { status: 'pending' } }),
      this.prisma.update.count(),
      this.prisma.comment.count(),
      this.prisma.userRole.count({
        where: {
          role: 'hunter',
          user: {
            isDeactivated: false,
          },
        },
      }),
      this.prisma.projectProposal.count({ where: { status: 'pending' } }),
      this.prisma.primaryTag.count(),
      // Count distinct users who have at least one device token registered
      this.prisma.deviceToken
        .findMany({ select: { userId: true }, distinct: ['userId'] })
        .then((rows) => rows.length),
    ]);

    return {
      totalProjects,
      totalUsers,
      activeUsers,
      deactivatedUsers,
      pendingAdminApps,
      totalUpdates,
      totalComments,
      activeHunters,
      pendingProposals,
      totalTags,
      usersWithPushEnabled,
    };
  }

  async listAllUsers(opts: {
    limit?: number;
    offset?: number;
    role?: string;
    q?: string;
    status?: string;
  }) {
    const { limit = 50, offset = 0, role, q, status } = opts;

    const validRoles = Object.values(RoleName);
    const roleFilter =
      role && validRoles.includes(role as RoleName)
        ? (role as RoleName)
        : undefined;
    const statusFilter =
      status === 'active' ? false : status === 'deactivated' ? true : undefined;

    // Only include UUID filter if q looks like a valid UUID to avoid Postgres cast errors
    const uuidRegex =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const isUuid = q ? uuidRegex.test(q.trim()) : false;

    const where = {
      ...(roleFilter ? { roles: { some: { role: roleFilter } } } : {}),
      ...(statusFilter !== undefined
        ? {
            isDeactivated: statusFilter,
          }
        : {}),
      ...(q
        ? {
            OR: [
              { email: { contains: q, mode: 'insensitive' as const } },
              { displayName: { contains: q, mode: 'insensitive' as const } },
              { username: { contains: q, mode: 'insensitive' as const } },
              ...(isUuid ? [{ id: { equals: q } }] : []),
            ],
          }
        : {}),
    };

    const [users, total] = await Promise.all([
      this.prisma.profile.findMany({
        where,
        skip: offset,
        take: limit,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        include: {
          roles: { select: { role: true } },
          _count: {
            select: {
              hunterAssignments: true,
              authoredUpdates: true,
            },
          },
        },
      }),
      this.prisma.profile.count({ where }),
    ]);

    return {
      data: users.map((u) => ({
        id: u.id,
        email: u.email,
        username: u.username,
        displayName: u.displayName,
        avatarUrl: u.avatarUrl,
        isDeactivated: u.isDeactivated,
        deactivatedAt: u.deactivatedAt,
        roles: u.roles.map((r) => r.role),
        projectsAssigned: u._count.hunterAssignments,
        updatesPosted: u._count.authoredUpdates,
        createdAt: u.createdAt,
      })),
      total,
      limit,
      offset,
    };
  }

  async getAdminUserById(userId: string) {
    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      include: {
        roles: { select: { role: true } },
        wallet: true,
        kycProfile: true,
        _count: {
          select: {
            followerLinks: true,
            followingLinks: true,
            follows: true,
            bookmarks: true,
            authoredUpdates: true,
            authoredComments: true,
            communityPosts: true,
            communityPostComments: true,
            withdrawalRequests: true,
            deviceTokens: true,
          },
        },
      },
    });

    if (!profile) {
      throw new NotFoundException('User not found');
    }

    return {
      id: profile.id,
      email: profile.email,
      username: profile.username,
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
      bio: profile.bio,
      isDeactivated: profile.isDeactivated,
      deactivatedAt: profile.deactivatedAt,
      deactivatedBy: profile.deactivatedBy,
      deactivationReason: profile.deactivationReason,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
      roles: profile.roles.map((row) => row.role),
      wallet: profile.wallet
        ? {
            id: profile.wallet.id,
            status: profile.wallet.status,
            address: profile.wallet.address,
            providerWalletId: profile.wallet.providerWalletId,
            chainEnvironment: profile.wallet.chainEnvironment,
            chainId: profile.wallet.chainId,
            createdAt: profile.wallet.createdAt,
            updatedAt: profile.wallet.updatedAt,
          }
        : null,
      kyc: profile.kycProfile
        ? {
            status: profile.kycProfile.status,
            tier: profile.kycProfile.tier,
            submittedAt: profile.kycProfile.submittedAt,
            reviewedAt: profile.kycProfile.reviewedAt,
            reviewNote: profile.kycProfile.reviewNote,
          }
        : null,
      counts: {
        followers: profile._count.followerLinks,
        following: profile._count.followingLinks,
        watchedProjects: profile._count.follows,
        bookmarks: profile._count.bookmarks,
        updates: profile._count.authoredUpdates,
        comments: profile._count.authoredComments,
        communityPosts: profile._count.communityPosts,
        communityComments: profile._count.communityPostComments,
        withdrawals: profile._count.withdrawalRequests,
        deviceTokens: profile._count.deviceTokens,
      },
    };
  }

  async updateUserByAdmin(
    actor: AuthUser,
    userId: string,
    dto: AdminUpdateUserDto,
  ) {
    const target = await this.prisma.profile.findUnique({
      where: { id: userId },
      include: {
        roles: { select: { role: true } },
      },
    });

    if (!target) {
      throw new NotFoundException('User not found');
    }

    const targetRoles = target.roles.map((row) => row.role);
    this.assertAdminCanManageTarget(actor, target.id, targetRoles);

    if (target.isDeactivated) {
      throw new BadRequestException('Cannot edit a deactivated user account');
    }

    if (dto.username !== undefined && dto.username !== null) {
      const taken = await this.isUsernameTaken(dto.username, target.id);
      if (taken) {
        throw new BadRequestException('Username is already taken');
      }
    }

    const data: {
      displayName?: string | null;
      username?: string | null;
      avatarUrl?: string | null;
      bio?: string | null;
    } = {};

    if (dto.displayName !== undefined) {
      data.displayName = dto.displayName;
    }
    if (dto.username !== undefined) {
      data.username = dto.username;
    }
    if (dto.avatarUrl !== undefined) {
      data.avatarUrl = dto.avatarUrl;
    }
    if (dto.bio !== undefined) {
      data.bio = dto.bio;
    }

    if (Object.keys(data).length === 0) {
      throw new BadRequestException('No editable fields were provided');
    }

    await this.prisma.profile.update({
      where: { id: target.id },
      data,
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'admin.user.update',
      resourceType: 'profile',
      resourceId: target.id,
      metadata: {
        targetUserId: target.id,
        fields: Object.keys(data),
      },
    });

    return this.getAdminUserById(target.id);
  }

  async deleteUserByAdmin(
    actor: AuthUser,
    userId: string,
    dto: AdminDeleteUserDto,
  ) {
    const target = await this.prisma.profile.findUnique({
      where: { id: userId },
      include: {
        roles: { select: { role: true } },
      },
    });

    if (!target) {
      throw new NotFoundException('User not found');
    }

    if (actor.id === target.id) {
      throw new ForbiddenException('You cannot delete your own account');
    }

    const targetRoles = target.roles.map((row) => row.role);
    this.assertAdminCanManageTarget(actor, target.id, targetRoles);
    await this.assertNotDeletingLastActiveOwner(target.id, targetRoles);

    const ownedProjectsCount = await this.prisma.project.count({
      where: { ownerAdminId: target.id },
    });
    if (ownedProjectsCount > 0) {
      throw new BadRequestException(
        'Cannot delete user while they still own projects. Reassign project ownership first.',
      );
    }

    if (target.isDeactivated) {
      return {
        deleted: false,
        reason: 'already_deactivated',
      };
    }

    const deactivatedAt = new Date();
    try {
      await this.notificationsService.notifyMany(
        [
          {
            userId: target.id,
            type: NotificationType.system,
            actorUserId: actor.id,
            title: 'Account deactivated',
            body: 'Your account was deactivated by an administrator.',
            payload: {
              action: 'admin.user.delete',
              reason: dto.reason ?? null,
            } as Prisma.InputJsonValue,
            deeplink: '/profile',
          },
        ],
        { push: true },
      );
    } catch {
      // Best-effort only; deactivation must proceed.
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.profile.update({
        where: { id: target.id },
        data: {
          isDeactivated: true,
          deactivatedAt,
          deactivatedBy: actor.id,
          deactivationReason:
            dto.reason ?? 'Account deleted by admin user management',
          email: this.createDeletedEmail(target.id),
          previousUsername: target.username,
          previousDisplayName: target.displayName,
          previousAvatarUrl: target.avatarUrl,
          previousBio: target.bio,
          username: null,
          displayName: 'Deleted User',
          avatarUrl: null,
          bio: null,
          homeFeedLastSeenAt: null,
        },
      });

      await tx.userRole.deleteMany({
        where: {
          userId: target.id,
        },
      });

      await tx.deviceToken.deleteMany({
        where: {
          userId: target.id,
        },
      });
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'admin.user.delete',
      resourceType: 'profile',
      resourceId: target.id,
      metadata: {
        targetUserId: target.id,
        reason: dto.reason ?? null,
      },
    });

    return {
      deleted: true,
      userId: target.id,
      deactivatedAt,
    };
  }

  async reactivateUserByOwner(
    actor: AuthUser,
    userId: string,
    dto: AdminReactivateUserDto,
  ) {
    this.assertOwnerActor(actor, 'Only owner can reactivate users');

    const target = await this.prisma.profile.findUnique({
      where: { id: userId },
      include: {
        roles: { select: { role: true } },
      },
    });

    if (!target) {
      throw new NotFoundException('User not found');
    }

    if (!target.isDeactivated) {
      return {
        reactivated: false,
        reason: 'already_active',
      };
    }

    const reactivatedAt = new Date();
    let restoredUsername: string | null = target.previousUsername ?? null;

    if (restoredUsername) {
      const usernameTaken = await this.prisma.profile.findUnique({
        where: { username: restoredUsername },
        select: { id: true },
      });
      if (usernameTaken && usernameTaken.id !== target.id) {
        restoredUsername = null;
      }
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.profile.update({
        where: { id: target.id },
        data: {
          isDeactivated: false,
          deactivatedAt: null,
          deactivatedBy: null,
          deactivationReason: null,
          username: restoredUsername,
          displayName: target.previousDisplayName,
          avatarUrl: target.previousAvatarUrl,
          bio: target.previousBio,
          previousUsername: null,
          previousDisplayName: null,
          previousAvatarUrl: null,
          previousBio: null,
        },
      });

      await tx.userRole.upsert({
        where: {
          userId_role: {
            userId: target.id,
            role: RoleName.user,
          },
        },
        update: {},
        create: {
          userId: target.id,
          role: RoleName.user,
          grantedBy: actor.id,
        },
      });
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'admin.user.reactivate',
      resourceType: 'profile',
      resourceId: target.id,
      metadata: {
        targetUserId: target.id,
        reason: dto.reason ?? null,
      },
    });

    return {
      reactivated: true,
      userId: target.id,
      reactivatedAt,
      usernameResetRequired: restoredUsername == null,
    };
  }

  async hardDeleteUserByOwner(
    actor: AuthUser,
    userId: string,
    dto: AdminHardDeleteUserDto,
  ) {
    this.assertOwnerActor(actor, 'Only owner can hard delete users');

    const target = await this.prisma.profile.findUnique({
      where: { id: userId },
      include: {
        roles: { select: { role: true } },
      },
    });

    if (!target) {
      throw new NotFoundException('User not found');
    }

    if (actor.id === target.id) {
      throw new ForbiddenException('You cannot hard delete your own account');
    }

    if (!target.isDeactivated) {
      throw new BadRequestException(
        'Hard delete requires a deactivated user account first',
      );
    }

    const targetRoles = target.roles.map((row) => row.role);
    await this.assertNotDeletingLastActiveOwner(target.id, targetRoles);

    const ownedProjectsCount = await this.prisma.project.count({
      where: { ownerAdminId: target.id },
    });
    if (ownedProjectsCount > 0) {
      throw new BadRequestException(
        'Cannot hard delete user while they still own projects. Reassign project ownership first.',
      );
    }

    await this.prisma.profile.delete({
      where: { id: target.id },
    });

    const deletedAt = new Date();
    await this.auditLogService.create({
      actorId: actor.id,
      action: 'admin.user.hard_delete',
      resourceType: 'profile',
      resourceId: target.id,
      metadata: {
        targetUserId: target.id,
        reason: dto.reason ?? null,
      },
    });

    return {
      hardDeleted: true,
      userId: target.id,
      deletedAt,
    };
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
    const { limit, offset } = this.normalizePagination(opts);
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
    const { limit, offset } = this.normalizePagination(opts);

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
    const { limit, offset } = this.normalizePagination(opts);

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
    const { limit, offset } = this.normalizePagination(opts);

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

  async getDigestSummary(userId: string, windowDays = 7) {
    const digestEnabled = this.configService.get<boolean>(
      'ENABLE_WEEKLY_DIGEST',
      true,
    );
    const boundedWindow = Math.min(Math.max(windowDays, 1), 30);
    if (!digestEnabled) {
      return {
        windowDays: boundedWindow,
        missedHighUrgency: [],
        activeProjects: [],
        topCommunityPosts: [],
      };
    }

    const since = new Date(Date.now() - boundedWindow * 24 * 60 * 60 * 1000);

    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: {
        homeFeedLastSeenAt: true,
        follows: {
          select: {
            projectId: true,
          },
        },
      },
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    const followedProjectIds = profile.follows.map(
      (follow) => follow.projectId,
    );
    if (followedProjectIds.length === 0) {
      await this.logDigestViewAuditIfDue(userId, {
        windowDays: boundedWindow,
        emptyFollowSet: true,
      });

      return {
        windowDays: boundedWindow,
        missedHighUrgency: [],
        activeProjects: [],
        topCommunityPosts: [],
      };
    }

    const [missedHighUrgencyRows, activeProjectRows, communityRows] =
      await Promise.all([
        this.prisma.update.findMany({
          where: {
            projectId: { in: followedProjectIds },
            status: { not: UpdateStatus.hidden },
            urgency: UpdateUrgency.high,
            createdAt: {
              gte: since,
              ...(profile.homeFeedLastSeenAt
                ? { gt: profile.homeFeedLastSeenAt }
                : {}),
            },
          },
          orderBy: { createdAt: 'desc' },
          take: 20,
          select: {
            id: true,
            title: true,
            urgency: true,
            createdAt: true,
            projectId: true,
            project: {
              select: {
                name: true,
              },
            },
          },
        }),
        this.prisma.project.findMany({
          where: {
            id: { in: followedProjectIds },
            status: { not: ProjectStatus.hidden },
          },
          select: {
            id: true,
            name: true,
            updates: {
              where: {
                status: { not: UpdateStatus.hidden },
                createdAt: { gte: since },
              },
              select: {
                id: true,
                urgency: true,
                createdAt: true,
              },
            },
          },
        }),
        this.prisma.communityPost.findMany({
          where: {
            status: ContentModerationStatus.active,
            createdAt: { gte: since },
          },
          orderBy: { createdAt: 'desc' },
          take: 30,
          include: {
            author: {
              select: {
                id: true,
                email: true,
                displayName: true,
                avatarUrl: true,
              },
            },
            _count: {
              select: {
                comments: true,
                reactions: true,
              },
            },
          },
        }),
      ]);

    const activeProjects = activeProjectRows
      .map((project) => {
        const updates = project.updates;
        const highCount = updates.filter(
          (update) => update.urgency === UpdateUrgency.high,
        ).length;
        const lastUpdateAt = updates
          .map((update) => update.createdAt)
          .sort((a, b) => b.getTime() - a.getTime())[0];

        return {
          projectId: project.id,
          projectName: project.name,
          newCount: updates.length,
          highCount,
          lastUpdateAt: lastUpdateAt ?? null,
        };
      })
      .filter((project) => project.newCount > 0)
      .sort((a, b) => {
        const byNewCount = b.newCount - a.newCount;
        if (byNewCount !== 0) return byNewCount;
        return b.highCount - a.highCount;
      })
      .slice(0, 8);

    const topCommunityPosts = communityRows
      .map((post) => ({
        id: post.id,
        topic: post.topic,
        contentPreview:
          post.content.length > 160
            ? `${post.content.slice(0, 160)}...`
            : post.content,
        likesCount: post._count.reactions,
        commentsCount: post._count.comments,
        createdAt: post.createdAt,
        author: {
          id: post.author.id,
          name: post.author.displayName ?? post.author.email ?? 'User',
          imageUrl: post.author.avatarUrl ?? '',
        },
      }))
      .sort((a, b) => {
        const scoreA = a.likesCount * 2 + a.commentsCount * 3;
        const scoreB = b.likesCount * 2 + b.commentsCount * 3;
        if (scoreB !== scoreA) return scoreB - scoreA;
        return b.createdAt.getTime() - a.createdAt.getTime();
      })
      .slice(0, 5);

    await this.logDigestViewAuditIfDue(userId, {
      windowDays: boundedWindow,
    });

    return {
      windowDays: boundedWindow,
      missedHighUrgency: missedHighUrgencyRows.map((row) => ({
        updateId: row.id,
        title: row.title,
        urgency: row.urgency,
        createdAt: row.createdAt,
        projectId: row.projectId,
        projectName: row.project.name,
      })),
      activeProjects,
      topCommunityPosts,
    };
  }

  private async logDigestViewAuditIfDue(
    userId: string,
    metadata: Record<string, unknown>,
  ) {
    const lastDigestView = await this.prisma.auditLog.findFirst({
      where: {
        actorId: userId,
        action: 'digest.view',
        resourceType: 'digest',
      },
      orderBy: {
        createdAt: 'desc',
      },
      select: {
        createdAt: true,
      },
    });

    if (lastDigestView) {
      const elapsedMs = Date.now() - lastDigestView.createdAt.getTime();
      if (elapsedMs < DIGEST_VIEW_AUDIT_COOLDOWN_MS) {
        return;
      }
    }

    await this.auditLogService.create({
      actorId: userId,
      action: 'digest.view',
      resourceType: 'digest',
      metadata,
    });
  }

  private assertAdminCanManageTarget(
    actor: AuthUser,
    targetUserId: string,
    targetRoles: RoleName[],
  ) {
    const isOwner = actor.roles.includes(AppRole.OWNER);
    const isAdmin = actor.roles.includes(AppRole.ADMIN);

    if (!isOwner && !isAdmin) {
      throw new ForbiddenException('Only owner/admin can manage users');
    }

    if (isOwner) {
      return;
    }

    const targetIsOwner = targetRoles.includes(RoleName.owner);
    const targetIsAdmin = targetRoles.includes(RoleName.admin);
    if (targetIsOwner || targetIsAdmin) {
      throw new ForbiddenException(
        'Admin users cannot manage owner/admin accounts',
      );
    }

    if (actor.id === targetUserId && targetIsAdmin) {
      throw new ForbiddenException('Admin users cannot self-manage admin role');
    }
  }

  private assertOwnerActor(actor: AuthUser, message: string) {
    if (!actor.roles.includes(AppRole.OWNER)) {
      throw new ForbiddenException(message);
    }
  }

  private async assertNotDeletingLastActiveOwner(
    targetUserId: string,
    targetRoles: RoleName[],
  ) {
    if (!targetRoles.includes(RoleName.owner)) {
      return;
    }

    const activeOwnerCount = await this.prisma.userRole.count({
      where: {
        role: RoleName.owner,
        user: {
          isDeactivated: false,
        },
      },
    });

    if (activeOwnerCount <= 1) {
      throw new ForbiddenException('Cannot delete the last active owner');
    }

    const targetIsActiveOwner = await this.prisma.userRole.findFirst({
      where: {
        userId: targetUserId,
        role: RoleName.owner,
        user: {
          isDeactivated: false,
        },
      },
      select: { id: true },
    });

    if (!targetIsActiveOwner) {
      throw new ForbiddenException('Owner account is already inactive');
    }
  }

  private createDeletedEmail(userId: string): string {
    return `deleted+${userId}@deleted.local`;
  }

  private requireSupabaseStorageClient(): SupabaseClient {
    if (this.supabaseStorageClient) {
      return this.supabaseStorageClient;
    }

    throw new InternalServerErrorException(
      'Supabase storage is not configured. Set SUPABASE_SECRET_KEY.',
    );
  }

  private fileExtensionForMimeType(mimeType: string): string {
    switch (mimeType) {
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      default:
        return 'bin';
    }
  }

  private async deletePreviousAvatarIfManaged(
    previousAvatarUrl: string | null,
    currentObjectPath: string,
  ): Promise<void> {
    if (!previousAvatarUrl) {
      return;
    }

    const managedPrefix = `${this.supabaseUrl}/storage/v1/object/public/${this.supabaseAvatarsBucket}/`;
    if (!previousAvatarUrl.startsWith(managedPrefix)) {
      return;
    }

    const previousPath = decodeURIComponent(
      previousAvatarUrl.slice(managedPrefix.length),
    );
    if (!previousPath || previousPath === currentObjectPath) {
      return;
    }

    await this.requireSupabaseStorageClient()
      .storage.from(this.supabaseAvatarsBucket)
      .remove([previousPath]);
  }

  private normalizePagination(opts: PaginationInput) {
    const rawLimit = Number.isFinite(opts.limit) ? Number(opts.limit) : 30;
    const rawOffset = Number.isFinite(opts.offset) ? Number(opts.offset) : 0;

    return {
      limit: Math.min(Math.max(rawLimit, 1), 100),
      offset: Math.max(rawOffset, 0),
    };
  }
}
