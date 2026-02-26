import {
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { AuditLogService } from '../audit-log/audit-log.service';
import { PrismaService } from '../prisma/prisma.service';
import { BlockUserDto } from './dto/block-user.dto';

@Injectable()
export class BlocksService {
  private readonly logger = new Logger(BlocksService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async blockUser(blockerId: string, dto: BlockUserDto) {
    const { blockedId, reason } = dto;

    if (blockerId === blockedId) {
      throw new ConflictException('Cannot block yourself');
    }

    const blockedUser = await this.prisma.profile.findUnique({
      where: { id: blockedId },
      select: { id: true },
    });

    if (!blockedUser) {
      throw new NotFoundException('User not found');
    }

    const existing = await this.prisma.userBlock.findUnique({
      where: {
        blockerId_blockedId: {
          blockerId,
          blockedId,
        },
      },
    });

    if (existing) {
      return this.prisma.userBlock.findUnique({
        where: { id: existing.id },
        include: {
          blocked: {
            select: {
              id: true,
              username: true,
              displayName: true,
              avatarUrl: true,
            },
          },
        },
      });
    }

    const block = await this.prisma.userBlock.create({
      data: {
        blockerId,
        blockedId,
        reason,
      },
      include: {
        blocked: {
          select: {
            id: true,
            username: true,
            displayName: true,
            avatarUrl: true,
          },
        },
      },
    });

    await this.auditLogService.create({
      actorId: blockerId,
      action: 'user.block',
      resourceType: 'user_block',
      resourceId: block.id,
      metadata: { blockedId, reason },
    });

    return block;
  }

  async unblockUser(blockerId: string, blockedId: string) {
    const block = await this.prisma.userBlock.findUnique({
      where: {
        blockerId_blockedId: {
          blockerId,
          blockedId,
        },
      },
    });

    if (!block) {
      return { deleted: false };
    }

    await this.prisma.userBlock.delete({ where: { id: block.id } });

    await this.auditLogService.create({
      actorId: blockerId,
      action: 'user.unblock',
      resourceType: 'user_block',
      resourceId: block.id,
      metadata: { blockedId },
    });

    return { deleted: true };
  }

  async getBlockedUsers(userId: string) {
    const blocks = await this.prisma.userBlock.findMany({
      where: { blockerId: userId },
      include: {
        blocked: {
          select: {
            id: true,
            username: true,
            displayName: true,
            avatarUrl: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return blocks;
  }

  async isBlocked(blockerId: string, blockedId: string): Promise<boolean> {
    const block = await this.prisma.userBlock.findUnique({
      where: {
        blockerId_blockedId: {
          blockerId,
          blockedId,
        },
      },
      select: { id: true },
    });

    return !!block;
  }

  async getBlockedUserIds(userId: string): Promise<string[]> {
    const blocks = await this.prisma.userBlock.findMany({
      where: { blockerId: userId },
      select: { blockedId: true },
    });

    return blocks.map((b) => b.blockedId);
  }
}
