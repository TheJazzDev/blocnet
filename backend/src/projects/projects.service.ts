import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProjectDto } from './dto/create-project.dto';
import { UpdateProjectDto } from './dto/update-project.dto';
import { ListProjectsQuery } from './dto/list-projects.query';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { AppRole } from '../common/enums/role.enum';
import { AuditLogService } from '../audit-log/audit-log.service';
import {
  normalizeName,
  normalizeSymbol,
  toSlug,
  toWebsiteDomain,
} from './projects.canonical';
import { projectInclude, toProjectResponse } from './projects.mapper';

@Injectable()
export class ProjectsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async createProject(actor: AuthUser, dto: CreateProjectDto) {
    const normalizedName = normalizeName(dto.name);
    const symbol = normalizeSymbol(dto.symbol);
    const websiteDomain = toWebsiteDomain(dto.websiteUrl);

    await this.assertNoCanonicalConflict({
      normalizedName,
      symbol,
      websiteDomain,
    });

    await this.assertTagsExist({
      primaryTagId: dto.primaryTagId,
      secondaryTagIds: dto.secondaryTagIds,
    });

    const project = await this.prisma.project.create({
      data: {
        name: dto.name,
        slug: toSlug(dto.name),
        normalizedName,
        symbol,
        websiteUrl: dto.websiteUrl?.trim(),
        websiteDomain,
        description: dto.description,
        primaryTagId: dto.primaryTagId,
        secondaryTags: dto.secondaryTagIds?.length
          ? {
              createMany: {
                data: dto.secondaryTagIds.map((secondaryTagId) => ({
                  secondaryTagId,
                })),
                skipDuplicates: true,
              },
            }
          : undefined,
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

    return toProjectResponse(project);
  }

  async createProjectForUser(input: {
    actorId: string;
    ownerUserId: string;
    dto: CreateProjectDto;
    auditAction?: string;
    auditMetadata?: Record<string, unknown>;
  }) {
    const normalizedName = normalizeName(input.dto.name);
    const symbol = normalizeSymbol(input.dto.symbol);
    const websiteDomain = toWebsiteDomain(input.dto.websiteUrl);

    await this.assertNoCanonicalConflict({
      normalizedName,
      symbol,
      websiteDomain,
    });

    await this.assertTagsExist({
      primaryTagId: input.dto.primaryTagId,
      secondaryTagIds: input.dto.secondaryTagIds,
    });

    const project = await this.prisma.project.create({
      data: {
        name: input.dto.name,
        slug: toSlug(input.dto.name),
        normalizedName,
        symbol,
        websiteUrl: input.dto.websiteUrl?.trim(),
        websiteDomain,
        description: input.dto.description,
        primaryTagId: input.dto.primaryTagId,
        secondaryTags: input.dto.secondaryTagIds?.length
          ? {
              createMany: {
                data: input.dto.secondaryTagIds.map((secondaryTagId) => ({
                  secondaryTagId,
                })),
                skipDuplicates: true,
              },
            }
          : undefined,
        ownerAdminId: input.ownerUserId,
      },
      include: projectInclude,
    });

    await this.auditLogService.create({
      actorId: input.actorId,
      action: input.auditAction ?? 'project.create',
      resourceType: 'project',
      resourceId: project.id,
      metadata: input.auditMetadata,
    });

    return toProjectResponse(project);
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

    return projects.map((project) => toProjectResponse(project));
  }

  async getProject(id: string) {
    const project = await this.prisma.project.findUnique({
      where: { id },
      include: projectInclude,
    });

    if (!project) {
      throw new NotFoundException('Project not found');
    }

    return toProjectResponse(project);
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

    const nextName = dto.name ?? project.name;
    const normalizedName = normalizeName(nextName);
    const symbol = normalizeSymbol(dto.symbol ?? project.symbol ?? undefined);
    const websiteUrl = dto.websiteUrl ?? project.websiteUrl ?? undefined;
    const websiteDomain = toWebsiteDomain(websiteUrl);

    await this.assertNoCanonicalConflict({
      normalizedName,
      symbol,
      websiteDomain,
      excludeProjectId: id,
    });

    if (dto.primaryTagId || dto.secondaryTagIds) {
      await this.assertTagsExist({
        primaryTagId: dto.primaryTagId ?? project.primaryTagId,
        secondaryTagIds: dto.secondaryTagIds,
      });
    }

    const updated = await this.prisma.project.update({
      where: { id },
      data: {
        name: dto.name,
        normalizedName,
        symbol,
        websiteUrl: dto.websiteUrl,
        websiteDomain,
        description: dto.description,
        primaryTagId: dto.primaryTagId,
        status: dto.status,
        slug: dto.name ? toSlug(dto.name) : undefined,
        secondaryTags: dto.secondaryTagIds
          ? {
              deleteMany: {},
              createMany: {
                data: dto.secondaryTagIds.map((secondaryTagId) => ({
                  secondaryTagId,
                })),
                skipDuplicates: true,
              },
            }
          : undefined,
      },
      include: projectInclude,
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'project.update',
      resourceType: 'project',
      resourceId: updated.id,
    });

    return toProjectResponse(updated);
  }

  normalizeName(value: string): string {
    return normalizeName(value);
  }

  normalizeSymbol(symbol?: string): string | undefined {
    return normalizeSymbol(symbol);
  }

  toWebsiteDomain(rawUrl?: string): string | undefined {
    return toWebsiteDomain(rawUrl);
  }

  toSlug(value: string): string {
    return toSlug(value);
  }

  async assertNoCanonicalConflict(input: {
    normalizedName: string;
    symbol?: string;
    websiteDomain?: string;
    excludeProjectId?: string;
  }) {
    const existing = await this.prisma.project.findFirst({
      where: {
        ...(input.excludeProjectId
          ? {
              id: {
                not: input.excludeProjectId,
              },
            }
          : {}),
        OR: [
          { normalizedName: input.normalizedName },
          ...(input.symbol ? [{ symbol: input.symbol }] : []),
          ...(input.websiteDomain
            ? [{ websiteDomain: input.websiteDomain }]
            : []),
        ],
      },
      select: {
        id: true,
        name: true,
        normalizedName: true,
        symbol: true,
        websiteDomain: true,
      },
    });

    if (!existing) return;

    if (existing.normalizedName === input.normalizedName) {
      throw new ConflictException('Project already exists with this name');
    }

    if (input.symbol && existing.symbol === input.symbol) {
      throw new ConflictException('Project already exists with this symbol');
    }

    if (input.websiteDomain && existing.websiteDomain === input.websiteDomain) {
      throw new ConflictException(
        'Project already exists with this website domain',
      );
    }

    throw new ConflictException('Project canonical data conflicts');
  }

  private async assertTagsExist(input: {
    primaryTagId: string;
    secondaryTagIds?: string[];
  }) {
    const primaryTag = await this.prisma.primaryTag.findUnique({
      where: { id: input.primaryTagId },
      select: { id: true },
    });

    if (!primaryTag) {
      throw new BadRequestException('Invalid primaryTagId');
    }

    const secondaryTagIds = [...new Set(input.secondaryTagIds ?? [])];
    if (secondaryTagIds.length === 0) {
      return;
    }

    const count = await this.prisma.secondaryTag.count({
      where: { id: { in: secondaryTagIds } },
    });

    if (count !== secondaryTagIds.length) {
      throw new BadRequestException('One or more secondaryTagIds are invalid');
    }
  }
}
