import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { Project } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProjectDto } from './dto/create-project.dto';
import { UpdateProjectDto } from './dto/update-project.dto';
import { ListProjectsQuery } from './dto/list-projects.query';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { AppRole } from '../common/enums/role.enum';
import { AuditLogService } from '../audit-log/audit-log.service';

@Injectable()
export class ProjectsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async createProject(actor: AuthUser, dto: CreateProjectDto) {
    const project = await this.prisma.project.create({
      data: {
        name: dto.name,
        slug: this.toSlug(dto.name),
        description: dto.description,
        primaryTag: dto.primaryTag,
        ownerAdminId: actor.id,
      },
      include: {
        _count: {
          select: {
            follows: true,
            posts: true,
          },
        },
      },
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'project.create',
      resourceType: 'project',
      resourceId: project.id,
    });

    return this.toProjectResponse(project);
  }

  async listProjects(query: ListProjectsQuery) {
    const offset = query.offset ?? 0;
    const limit = Math.min(query.limit ?? 30, 100);

    const projects = await this.prisma.project.findMany({
      skip: offset,
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        _count: {
          select: {
            follows: true,
            posts: true,
          },
        },
      },
    });

    return projects.map((project) => this.toProjectResponse(project));
  }

  async getProject(id: string) {
    const project = await this.prisma.project.findUnique({
      where: { id },
      include: {
        _count: {
          select: {
            follows: true,
            posts: true,
          },
        },
      },
    });

    if (!project) {
      throw new NotFoundException('Project not found');
    }

    return this.toProjectResponse(project);
  }

  async updateProject(actor: AuthUser, id: string, dto: UpdateProjectDto) {
    const project = await this.prisma.project.findUnique({ where: { id } });

    if (!project) {
      throw new NotFoundException('Project not found');
    }

    const isOwner = actor.roles.includes(AppRole.OWNER);
    const canEdit = isOwner || project.ownerAdminId === actor.id;

    if (!canEdit) {
      throw new ForbiddenException('You can only manage your own projects');
    }

    const updated = await this.prisma.project.update({
      where: { id },
      data: {
        name: dto.name,
        description: dto.description,
        primaryTag: dto.primaryTag,
        status: dto.status,
        slug: dto.name ? this.toSlug(dto.name) : undefined,
      },
      include: {
        _count: {
          select: {
            follows: true,
            posts: true,
          },
        },
      },
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'project.update',
      resourceType: 'project',
      resourceId: updated.id,
    });

    return this.toProjectResponse(updated);
  }

  private toSlug(value: string): string {
    return value
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-');
  }

  private toProjectResponse(
    project: Project & {
      _count: {
        follows: number;
        posts: number;
      };
    },
  ) {
    const { _count, ...rest } = project;

    return {
      ...rest,
      followersCount: _count.follows,
      postsCount: _count.posts,
    };
  }
}
