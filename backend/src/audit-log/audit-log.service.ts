import { ForbiddenException, Injectable, Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { NotificationEventsService } from '../notifications/notification-events.service';
import { AppRole } from '../common/enums/role.enum';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { PrismaService } from '../prisma/prisma.service';

type AuditInput = {
  actorId?: string;
  action: string;
  resourceType: string;
  resourceId?: string;
  metadata?: Record<string, unknown>;
};

const ADMIN_HIDDEN_ACTIONS = new Set<string>([
  'role.promote.owner',
  'role.demote.owner',
  'role.promote.admin',
  'role.demote.admin',
  'role.promote.core_team',
  'role.demote.core_team',
  'admin.user.reactivate',
  'admin.user.hard_delete',
  'admin_application.review',
]);

const MODERATOR_VISIBLE_ACTIONS = new Set<string>([
  'settings.runtime_features.view',
  'edge.admin.config.view',
]);

const MODERATOR_VISIBLE_ACTION_PREFIXES = [
  'project.moderate.',
  'update.moderate.',
  'comment.moderate.',
  'community_post.moderate.',
  'community_comment.moderate.',
  'project_proposal.review',
  'edge.feed.',
  'edge.brief.',
  'edge.explain.',
  'edge.admin.overview.',
];

@Injectable()
export class AuditLogService {
  private readonly logger = new Logger(AuditLogService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationEventsService: NotificationEventsService,
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
      await this.notificationEventsService.emitForAudit({
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

  async listForUser(user: AuthUser, limit = 100, offset = 0) {
    const safeLimit = Math.min(Math.max(limit, 1), 500);
    const safeOffset = Math.max(offset, 0);
    const visibilityWhere = this.buildVisibilityWhere(user);

    return this.prisma.auditLog.findMany({
      ...(visibilityWhere ? { where: visibilityWhere } : {}),
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

  private buildVisibilityWhere(
    user: Pick<AuthUser, 'roles'>,
  ): Prisma.AuditLogWhereInput | undefined {
    const role = this.resolveAuditViewRole(user);
    if (role === AppRole.OWNER) {
      return undefined;
    }

    if (role === AppRole.ADMIN) {
      return {
        NOT: {
          action: {
            in: [...ADMIN_HIDDEN_ACTIONS],
          },
        },
      };
    }

    const moderatorVisibility: Prisma.AuditLogWhereInput[] = [
      {
        action: {
          in: [...MODERATOR_VISIBLE_ACTIONS],
        },
      },
      ...MODERATOR_VISIBLE_ACTION_PREFIXES.map((prefix) => ({
        action: {
          startsWith: prefix,
        },
      })),
    ];

    return {
      OR: moderatorVisibility,
    };
  }

  private resolveAuditViewRole(user: Pick<AuthUser, 'roles'>): AppRole {
    if (user.roles.includes(AppRole.OWNER)) {
      return AppRole.OWNER;
    }
    if (user.roles.includes(AppRole.ADMIN)) {
      return AppRole.ADMIN;
    }
    if (user.roles.includes(AppRole.MODERATOR)) {
      return AppRole.MODERATOR;
    }
    throw new ForbiddenException('Role is not allowed to view audit logs');
  }
}
