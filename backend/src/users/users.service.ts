import { Injectable } from '@nestjs/common';
import { RoleName } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateMeDto } from './dto/update-me.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

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
      roles: profile.roles.map((row) => row.role),
      followedProjectIds: profile.follows.map((row) => row.projectId),
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
      },
      createdAt: profile.createdAt,
    };
  }
}
