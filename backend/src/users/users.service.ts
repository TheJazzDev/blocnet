import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { RoleName } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import {
  buildCommunityPostInclude,
  toCommunityPostResponse,
} from '../community-posts/community-posts.mapper';
import { projectInclude, toProjectResponse } from '../projects/projects.mapper';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateMeDto } from './dto/update-me.dto';

type PaginationInput = {
  limit?: number;
  offset?: number;
};

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
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
      },
    });

    if (!profile) {
      return null;
    }

    return {
      id: profile.id,
      email: profile.email,
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
      createdAt: profile.createdAt,
      roles: profile.roles.map((row) => row.role),
      followedProjectIds: profile.follows.map((row) => row.projectId),
      followedProfileIds: profile.followingLinks.map((row) => row.followeeId),
      followersCount: profile._count.followerLinks,
      followingCount: profile._count.followingLinks,
      bookmarkCount: profile._count.bookmarks,
    };
  }

  async updateMe(userId: string, dto: UpdateMeDto) {
    return this.prisma.profile.update({
      where: { id: userId },
      data: {
        displayName: dto.displayName,
        avatarUrl: dto.avatarUrl,
      },
    });
  }

  async getAdminStats() {
    const [
      totalProjects,
      totalUsers,
      pendingAdminApps,
      totalUpdates,
      totalComments,
      activeHunters,
      pendingProposals,
      totalTags,
    ] = await Promise.all([
      this.prisma.project.count(),
      this.prisma.profile.count(),
      this.prisma.adminApplication.count({ where: { status: 'pending' } }),
      this.prisma.update.count(),
      this.prisma.comment.count(),
      this.prisma.userRole.count({ where: { role: 'hunter' } }),
      this.prisma.projectProposal.count({ where: { status: 'pending' } }),
      this.prisma.primaryTag.count(),
    ]);

    return {
      totalProjects,
      totalUsers,
      pendingAdminApps,
      totalUpdates,
      totalComments,
      activeHunters,
      pendingProposals,
      totalTags,
    };
  }

  async listAllUsers(opts: { limit?: number; offset?: number; role?: string }) {
    const { limit = 50, offset = 0, role } = opts;

    const validRoles = Object.values(RoleName);
    const roleFilter =
      role && validRoles.includes(role as RoleName)
        ? (role as RoleName)
        : undefined;
    const where = roleFilter
      ? { roles: { some: { role: roleFilter } } }
      : undefined;

    const [users, total] = await Promise.all([
      this.prisma.profile.findMany({
        where,
        skip: offset,
        take: limit,
        orderBy: { createdAt: 'desc' },
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
        displayName: u.displayName,
        avatarUrl: u.avatarUrl,
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

  async getPublicProfile(userId: string) {
    const profile = await this.prisma.profile.findUnique({
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
    });

    if (!profile) {
      return null;
    }

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
      createdAt: profile.createdAt,
    };
  }

  async followProfile(followerId: string, followeeId: string) {
    if (followerId === followeeId) {
      throw new BadRequestException('You cannot follow your own profile');
    }

    const followee = await this.prisma.profile.findUnique({
      where: { id: followeeId },
      select: { id: true },
    });

    if (!followee) {
      throw new NotFoundException('Profile not found');
    }

    const follow = await this.prisma.userFollow.upsert({
      where: {
        followerId_followeeId: {
          followerId,
          followeeId,
        },
      },
      update: {},
      create: {
        followerId,
        followeeId,
      },
    });

    await this.auditLogService.create({
      actorId: followerId,
      action: 'profile.follow',
      resourceType: 'user_follow',
      resourceId: follow.id,
      metadata: { followeeId },
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
      metadata: { followeeId },
    });

    return { deleted: true };
  }

  async listWatchlist(userId: string, opts: PaginationInput) {
    const { limit, offset } = this.normalizePagination(opts);

    const follows = await this.prisma.projectFollow.findMany({
      where: { userId },
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
      where: { userId },
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

  private normalizePagination(opts: PaginationInput) {
    const rawLimit = Number.isFinite(opts.limit) ? Number(opts.limit) : 30;
    const rawOffset = Number.isFinite(opts.offset) ? Number(opts.offset) : 0;

    return {
      limit: Math.min(Math.max(rawLimit, 1), 100),
      offset: Math.max(rawOffset, 0),
    };
  }
}
