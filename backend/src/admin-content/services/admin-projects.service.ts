import { Prisma, ProjectStatus } from '@prisma/client';
import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditLogService } from '../../audit-log/audit-log.service';
import { AppRole } from '../../common/enums/role.enum';
import type { AuthUser } from '../../common/interfaces/auth-user.interface';
import { normalizePagination } from '../../common/utils/pagination.util';
import { PrismaService } from '../../prisma/prisma.service';
import { ListAdminProjectsQuery } from '../dto/list-admin-projects.query';
import { ModerateProjectStatusDto } from '../dto/moderate-project-status.dto';

@Injectable()
export class AdminProjectsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async listProjects(query: ListAdminProjectsQuery) {
    const { offset, limit } = normalizePagination(query.offset, query.limit);

    const where: Prisma.ProjectWhereInput = {
      status: query.status,
      ...(query.q
        ? {
            OR: [
              { name: { contains: query.q, mode: 'insensitive' } },
              { slug: { contains: query.q.toLowerCase() } },
              { symbol: { contains: query.q.toUpperCase() } },
              { description: { contains: query.q, mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const projects = await this.prisma.project.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      skip: offset,
      take: limit,
      include: {
        ownerAdmin: {
          select: {
            id: true,
            email: true,
            displayName: true,
          },
        },
        moderator: {
          select: {
            id: true,
            email: true,
            displayName: true,
          },
        },
        primaryTag: {
          select: {
            id: true,
            name: true,
          },
        },
        _count: {
          select: {
            updates: true,
            follows: true,
          },
        },
      },
    });

    return projects.map((project) => ({
      id: project.id,
      name: project.name,
      symbol: project.symbol,
      status: project.status,
      description: project.description,
      slug: project.slug,
      primaryTag: project.primaryTag,
      owner: project.ownerAdmin,
      moderation: {
        moderatedBy: project.moderator,
        moderatedAt: project.moderatedAt,
        moderationReason: project.moderationReason,
      },
      counts: {
        updates: project._count.updates,
        followers: project._count.follows,
      },
      createdAt: project.createdAt,
      updatedAt: project.updatedAt,
    }));
  }

  async moderateProjectStatus(
    actor: AuthUser,
    projectId: string,
    dto: ModerateProjectStatusDto,
  ) {
    if (dto.status === ProjectStatus.paused && this.isModeratorOnly(actor)) {
      throw new ForbiddenException(
        'Moderators can only set project status to active, hidden, or archived',
      );
    }

    const existing = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { id: true, status: true },
    });

    if (!existing) {
      throw new NotFoundException('Project not found');
    }

    const updated = await this.prisma.project.update({
      where: { id: projectId },
      data: {
        status: dto.status,
        moderatedBy: actor.id,
        moderatedAt: new Date(),
        moderationReason: dto.reason,
      },
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'project.moderate.status',
      resourceType: 'project',
      resourceId: updated.id,
      metadata: {
        fromStatus: existing.status,
        toStatus: updated.status,
        reason: dto.reason,
      },
    });

    return updated;
  }

  private isModeratorOnly(actor: AuthUser) {
    const isOwner = actor.roles.includes(AppRole.OWNER);
    const isAdmin = actor.roles.includes(AppRole.ADMIN);
    const isModerator = actor.roles.includes(AppRole.MODERATOR);
    return !isOwner && !isAdmin && isModerator;
  }
}
