import { Injectable } from '@nestjs/common';
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
