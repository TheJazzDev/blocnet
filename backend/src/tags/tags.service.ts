import { ConflictException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePrimaryTagDto } from './dto/create-primary-tag.dto';
import { CreateSecondaryTagDto } from './dto/create-secondary-tag.dto';

@Injectable()
export class TagsService {
  constructor(private readonly prisma: PrismaService) {}

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

  async createPrimaryTag(dto: CreatePrimaryTagDto) {
    const name = dto.name.trim();
    const slug = this.toSlug(name);

    try {
      return await this.prisma.primaryTag.create({
        data: { name, slug },
      });
    } catch {
      throw new ConflictException('Primary tag with this name already exists');
    }
  }

  async createSecondaryTag(dto: CreateSecondaryTagDto) {
    const name = dto.name.trim();
    const slug = this.toSlug(name);

    try {
      return await this.prisma.secondaryTag.create({
        data: { name, slug },
      });
    } catch {
      throw new ConflictException('Secondary tag with this name already exists');
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
