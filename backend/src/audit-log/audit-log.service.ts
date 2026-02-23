import { Injectable, Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';

type AuditInput = {
  actorId?: string;
  action: string;
  resourceType: string;
  resourceId?: string;
  metadata?: Record<string, unknown>;
};

@Injectable()
export class AuditLogService {
  private readonly logger = new Logger(AuditLogService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  async create(input: AuditInput) {
    const entry = await this.prisma.auditLog.create({
      data: {
        actorId: input.actorId,
        action: input.action,
        resourceType: input.resourceType,
        resourceId: input.resourceId,
        metadata: input.metadata as Prisma.InputJsonValue | undefined,
      },
    });

    try {
      await this.notificationsService.emitForAudit({
        action: entry.action,
        actorId: entry.actorId,
        resourceId: entry.resourceId,
        metadata: entry.metadata,
      });
    } catch (error) {
      this.logger.warn(
        `Failed to emit notification events for audit entry ${entry.id}: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    }

    return entry;
  }

  async list(limit = 100, offset = 0) {
    const safeLimit = Math.min(Math.max(limit, 1), 500);
    const safeOffset = Math.max(offset, 0);

    return this.prisma.auditLog.findMany({
      orderBy: { createdAt: 'desc' },
      skip: safeOffset,
      take: safeLimit,
      include: {
        actor: {
          select: { id: true, email: true, displayName: true },
        },
      },
    });
  }
}
