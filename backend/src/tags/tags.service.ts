import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditLogService } from '../audit-log/audit-log.service';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePrimaryTagDto } from './dto/create-primary-tag.dto';
import { CreateSecondaryTagDto } from './dto/create-secondary-tag.dto';
import { UpdatePrimaryTagDto } from './dto/update-primary-tag.dto';
import { UpdateSecondaryTagDto } from './dto/update-secondary-tag.dto';

@Injectable()
export class TagsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async listPrimaryTags() {
    return this.prisma.primaryTag.findMany({
      orderBy: { name: 'asc' },
    });
  }

  async listSecondaryTags() {
    return this.prisma.secondaryTag.findMany({
      orderBy: { name: 'asc' },
    });
  }

  async createPrimaryTag(actorId: string, dto: CreatePrimaryTagDto) {
    const name = dto.name.trim();
    const slug = this.toSlug(name);

    try {
      const created = await this.prisma.primaryTag.create({
        data: { name, slug },
      });
      await this.auditLogService.create({
        actorId,
        action: 'tag.primary.create',
        resourceType: 'primary_tag',
        resourceId: created.id,
        metadata: {
          name: created.name,
          slug: created.slug,
        },
      });
      return created;
    } catch {
      throw new ConflictException('Primary tag with this name already exists');
    }
  }

  async createSecondaryTag(actorId: string, dto: CreateSecondaryTagDto) {
    const name = dto.name.trim();
    const slug = this.toSlug(name);

    try {
      const created = await this.prisma.secondaryTag.create({
        data: { name, slug },
      });
      await this.auditLogService.create({
        actorId,
        action: 'tag.secondary.create',
        resourceType: 'secondary_tag',
        resourceId: created.id,
        metadata: {
          name: created.name,
          slug: created.slug,
        },
      });
      return created;
    } catch {
      throw new ConflictException(
        'Secondary tag with this name already exists',
      );
    }
  }

  async updatePrimaryTag(
    actorId: string,
    id: string,
    dto: UpdatePrimaryTagDto,
  ) {
    const current = await this.prisma.primaryTag.findUnique({
      where: { id },
      select: { id: true, name: true, slug: true },
    });

    if (!current) {
      throw new NotFoundException('Primary tag not found');
    }

    const name = dto.name.trim();
    const slug = this.toSlug(name);

    try {
      const updated = await this.prisma.primaryTag.update({
        where: { id },
        data: { name, slug },
      });
      await this.auditLogService.create({
        actorId,
        action: 'tag.primary.update',
        resourceType: 'primary_tag',
        resourceId: updated.id,
        metadata: {
          previousName: current.name,
          previousSlug: current.slug,
          name: updated.name,
          slug: updated.slug,
        },
      });
      return updated;
    } catch {
      throw new ConflictException('Primary tag with this name already exists');
    }
  }

  async updateSecondaryTag(
    actorId: string,
    id: string,
    dto: UpdateSecondaryTagDto,
  ) {
    const current = await this.prisma.secondaryTag.findUnique({
      where: { id },
      select: { id: true, name: true, slug: true },
    });

    if (!current) {
      throw new NotFoundException('Secondary tag not found');
    }

    const name = dto.name.trim();
    const slug = this.toSlug(name);

    try {
      const updated = await this.prisma.secondaryTag.update({
        where: { id },
        data: { name, slug },
      });
      await this.auditLogService.create({
        actorId,
        action: 'tag.secondary.update',
        resourceType: 'secondary_tag',
        resourceId: updated.id,
        metadata: {
          previousName: current.name,
          previousSlug: current.slug,
          name: updated.name,
          slug: updated.slug,
        },
      });
      return updated;
    } catch {
      throw new ConflictException(
        'Secondary tag with this name already exists',
      );
    }
  }

  private toSlug(value: string): string {
    return value
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-');
  }
}
