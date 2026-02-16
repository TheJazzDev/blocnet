import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProjectDto } from './dto/create-project.dto';
import { UpdateProjectDto } from './dto/update-project.dto';
import { ListProjectsQuery } from './dto/list-projects.query';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { AppRole } from '../common/enums/role.enum';
import { AuditLogService } from '../audit-log/audit-log.service';

const projectInclude = {
  ownerAdmin: {
    select: {
      id: true,
      email: true,
      displayName: true,
      avatarUrl: true,
    },
  },
  _count: {
    select: {
      follows: true,
      posts: true,
    },
  },
} satisfies Prisma.ProjectInclude;

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
      include: projectInclude,
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
      include: projectInclude,
    });

    return projects.map((project) => this.toProjectResponse(project));
  }

  async getProject(id: string) {
    const project = await this.prisma.project.findUnique({
      where: { id },
      include: projectInclude,
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
      include: projectInclude,
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
    project: Prisma.ProjectGetPayload<{
      include: typeof projectInclude;
    }>,
  ) {
    const { _count, ownerAdmin, ...rest } = project;
    const rawUsername = ownerAdmin.email?.split('@')[0] ?? ownerAdmin.id;
    const normalized = rawUsername
      .toLowerCase()
      .replace(/[^a-z0-9._-]/g, '')
      .trim();
    const username = `@${normalized || ownerAdmin.id.slice(0, 6)}`;

    return {
      ...rest,
      followersCount: _count.follows,
      postsCount: _count.posts,
      admin: {
        id: ownerAdmin.id,
        name: ownerAdmin.displayName ?? ownerAdmin.email ?? 'Admin',
        username,
        imageUrl: ownerAdmin.avatarUrl ?? '',
        followers: _count.follows,
      },
    };
  }
}
