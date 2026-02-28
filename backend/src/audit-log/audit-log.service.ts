import { ForbiddenException, Injectable, Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { NotificationEventsService } from '../notifications/notification-events.service';
import { AppRole } from '../common/enums/role.enum';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { PrismaService } from '../prisma/prisma.service';
import {
  type ListOpsEventsQuery,
  type OpsEventProvider,
  type OpsEventSource,
  type OpsEventStatus,
} from './dto/list-ops-events.query';

type AuditInput = {
  actorId?: string;
  action: string;
  resourceType: string;
  resourceId?: string;
  metadata?: Record<string, unknown>;
};

type OpsEvent = {
  id: string;
  action: string;
  source: OpsEventSource;
  provider: OpsEventProvider;
  status: OpsEventStatus;
  resourceType: string;
  resourceId: string | null;
  summary: string;
  actor: {
    id: string;
    email: string;
    displayName: string | null;
  } | null;
  metadata: Record<string, unknown>;
  createdAt: Date;
};

const OPS_ACTION_PREFIXES = [
  'ops.',
  'wallet.',
  'tip.',
  'auth.',
  'session.',
  'notification.broadcast.',
];

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

  async listOpsEvents(user: AuthUser, query: ListOpsEventsQuery) {
    if (!user.roles.includes(AppRole.OWNER)) {
      throw new ForbiddenException('Role is not allowed to view ops events');
    }

    const limit = Math.min(Math.max(query.limit ?? 100, 1), 200);
    const offset = Math.max(query.offset ?? 0, 0);
    const q = query.q?.trim();
    const from = query.from ? new Date(query.from) : null;
    const to = query.to ? new Date(query.to) : null;

    const sourcePrefixes = this.actionPrefixesForSource(query.source);
    const providerPrefixes = this.actionPrefixesForProvider(query.provider);

    const where: Prisma.AuditLogWhereInput = {
      AND: [
        {
          OR: OPS_ACTION_PREFIXES.map((prefix) => ({
            action: { startsWith: prefix },
          })),
        },
        ...(sourcePrefixes
          ? [
              {
                OR: sourcePrefixes.map((prefix) => ({
                  action: { startsWith: prefix },
                })),
              },
            ]
          : []),
        ...(providerPrefixes
          ? [
              {
                OR: providerPrefixes.map((prefix) => ({
                  action: { startsWith: prefix },
                })),
              },
            ]
          : []),
        ...(q && q.length > 0
          ? [
              {
                OR: [
                  { action: { contains: q } },
                  { resourceType: { contains: q } },
                  { resourceId: { contains: q } },
                  {
                    actor: {
                      is: {
                        OR: [
                          { email: { contains: q } },
                          { displayName: { contains: q } },
                        ],
                      },
                    },
                  },
                ],
              },
            ]
          : []),
        ...(from
          ? [
              {
                createdAt: { gte: from },
              },
            ]
          : []),
        ...(to
          ? [
              {
                createdAt: { lte: to },
              },
            ]
          : []),
      ],
    };

    const scanBatchSize = 200;
    const targetCount = offset + limit;
    const filtered: OpsEvent[] = [];
    let scanOffset = 0;

    while (filtered.length < targetCount) {
      const rows = await this.prisma.auditLog.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: scanOffset,
        take: scanBatchSize,
        include: {
          actor: {
            select: { id: true, email: true, displayName: true },
          },
        },
      });
      if (rows.length === 0) {
        break;
      }

      const normalized = rows
        .map((row) => this.toOpsEvent(row))
        .filter((row) =>
          this.matchesOpsFilters({
            row,
            source: query.source,
            provider: query.provider,
            status: query.status,
          }),
        );

      filtered.push(...normalized);
      scanOffset += rows.length;
    }

    return filtered.slice(offset, offset + limit);
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

  private toOpsEvent(
    row: Prisma.AuditLogGetPayload<{
      include: {
        actor: {
          select: { id: true; email: true; displayName: true };
        };
      };
    }>,
  ): OpsEvent {
    const metadata = this.toMetadataRecord(row.metadata);
    const action = row.action.toLowerCase();
    const { source, provider } = this.resolveSourceAndProvider(action);
    const status = this.resolveStatus(action, metadata);
    const summary = this.resolveSummary(action, metadata, row.resourceType);

    return {
      id: row.id,
      action: row.action,
      source,
      provider,
      status,
      resourceType: row.resourceType,
      resourceId: row.resourceId,
      summary,
      actor: row.actor
        ? {
            id: row.actor.id,
            email: row.actor.email,
            displayName: row.actor.displayName,
          }
        : null,
      metadata,
      createdAt: row.createdAt,
    };
  }

  private toMetadataRecord(metadata: Prisma.JsonValue | null) {
    if (!metadata || typeof metadata !== 'object' || Array.isArray(metadata)) {
      return {} as Record<string, unknown>;
    }
    return metadata as Record<string, unknown>;
  }

  private resolveSourceAndProvider(action: string): {
    source: OpsEventSource;
    provider: OpsEventProvider;
  } {
    if (action.startsWith('ops.social.')) {
      const providerToken = action.split('.')[2]?.trim().toLowerCase();
      switch (providerToken) {
        case 'x':
        case 'instagram':
        case 'tiktok':
        case 'youtube':
        case 'linkedin':
        case 'discord':
        case 'telegram':
          return { source: 'social', provider: providerToken };
        default:
          return { source: 'social', provider: 'unknown' };
      }
    }

    if (action.startsWith('ops.email.resend.') || action.startsWith('notification.broadcast.email.')) {
      return { source: 'email', provider: 'resend' };
    }

    if (action.startsWith('wallet.')) {
      if (action.startsWith('wallet.provision.')) {
        return { source: 'wallet', provider: 'turnkey' };
      }
      if (action.startsWith('wallet.deposit.') || action.startsWith('wallet.withdrawal.')) {
        return { source: 'wallet', provider: 'bsc' };
      }
      return { source: 'wallet', provider: 'internal' };
    }

    if (action.startsWith('tip.')) {
      return { source: 'tips', provider: 'internal' };
    }

    if (action.startsWith('auth.') || action.startsWith('session.')) {
      return { source: 'auth', provider: 'supabase' };
    }

    if (action.startsWith('notification.broadcast.')) {
      return { source: 'notifications', provider: 'internal' };
    }

    if (action.startsWith('ops.')) {
      return { source: 'system', provider: 'internal' };
    }

    return { source: 'system', provider: 'unknown' };
  }

  private resolveStatus(action: string, metadata: Record<string, unknown>): OpsEventStatus {
    const explicit = `${metadata.status ?? ''}`.trim().toLowerCase();
    if (explicit === 'success') return 'success';
    if (explicit === 'warning') return 'warning';
    if (explicit === 'error' || explicit === 'failed') return 'error';
    if (explicit === 'info') return 'info';

    if (
      action.endsWith('.failed') ||
      action.includes('.error') ||
      action.includes('.reverted')
    ) {
      return 'error';
    }

    if (
      action.includes('.rejected') ||
      action.includes('.disabled') ||
      action.includes('.pending') ||
      action.includes('.queued') ||
      action.includes('.requested')
    ) {
      return 'warning';
    }

    if (
      action.includes('.sent') ||
      action.includes('.ready') ||
      action.includes('.approved') ||
      action.includes('.credited') ||
      action.includes('.swept') ||
      action.includes('.confirmed') ||
      action.includes('.updated') ||
      action.includes('.enabled') ||
      action.includes('.broadcasted')
    ) {
      return 'success';
    }

    return 'info';
  }

  private resolveSummary(
    action: string,
    metadata: Record<string, unknown>,
    resourceType: string,
  ) {
    const common = (metadata.message ?? metadata.reason ?? metadata.error) as
      | string
      | undefined;
    if (common && common.trim().length > 0) {
      return common.trim();
    }

    if (action === 'ops.email.resend.sent') {
      const to = `${metadata.to ?? ''}`.trim();
      return to ? `Email sent to ${to}` : 'Email sent via Resend';
    }
    if (action === 'ops.email.resend.failed') {
      const to = `${metadata.to ?? ''}`.trim();
      return to ? `Email delivery failed for ${to}` : 'Email delivery failed';
    }
    if (action === 'notification.broadcast.email.send') {
      const delivered = Number(metadata.delivered ?? 0);
      const failed = Number(metadata.failed ?? 0);
      return `Broadcast email delivered=${delivered}, failed=${failed}`;
    }
    if (action === 'wallet.deposit.detected') {
      const asset = `${metadata.asset ?? ''}`.trim();
      const amount = `${metadata.amount ?? ''}`.trim();
      if (asset && amount) return `Detected ${amount} ${asset} deposit`;
    }
    if (action === 'wallet.deposit.credited') {
      const asset = `${metadata.asset ?? ''}`.trim();
      const amount = `${metadata.amount ?? ''}`.trim();
      if (asset && amount) return `Credited ${amount} ${asset} deposit`;
    }
    if (action.startsWith('ops.social.')) {
      const provider = `${metadata.provider ?? ''}`.trim();
      const accountHandle = `${metadata.accountHandle ?? ''}`.trim();
      const metrics =
        metadata.metrics && typeof metadata.metrics === 'object' && !Array.isArray(metadata.metrics)
          ? (metadata.metrics as Record<string, unknown>)
          : null;
      if (metrics) {
        const followers = metrics.followers;
        const following = metrics.following;
        const posts = metrics.posts;
        const metricBits = [
          followers !== undefined ? `followers=${String(followers)}` : null,
          following !== undefined ? `following=${String(following)}` : null,
          posts !== undefined ? `posts=${String(posts)}` : null,
        ].filter((entry): entry is string => !!entry);
        if (metricBits.length > 0) {
          return `${provider || 'social'} snapshot${
            accountHandle ? ` (${accountHandle})` : ''
          }: ${metricBits.join(' · ')}`;
        }
      }
      return `${provider || 'social'} webhook event received`;
    }

    return `${resourceType.replaceAll('_', ' ')} event`;
  }

  private matchesOpsFilters(input: {
    row: OpsEvent;
    source?: 'all' | OpsEventSource;
    provider?: 'all' | OpsEventProvider;
    status?: 'all' | OpsEventStatus;
  }) {
    if (
      input.source &&
      input.source !== 'all' &&
      input.row.source !== input.source
    ) {
      return false;
    }
    if (
      input.provider &&
      input.provider !== 'all' &&
      input.row.provider !== input.provider
    ) {
      return false;
    }
    if (
      input.status &&
      input.status !== 'all' &&
      input.row.status !== input.status
    ) {
      return false;
    }
    return true;
  }

  private actionPrefixesForSource(source?: 'all' | OpsEventSource) {
    if (!source || source === 'all') return null;

    switch (source) {
      case 'email':
        return ['ops.email.resend.', 'notification.broadcast.email.'];
      case 'wallet':
        return ['wallet.'];
      case 'tips':
        return ['tip.'];
      case 'social':
        return ['ops.social.'];
      case 'auth':
        return ['auth.', 'session.'];
      case 'notifications':
        return ['notification.broadcast.'];
      case 'system':
        return ['ops.'];
      default:
        return null;
    }
  }

  private actionPrefixesForProvider(provider?: 'all' | OpsEventProvider) {
    if (!provider || provider === 'all') return null;

    switch (provider) {
      case 'resend':
        return ['ops.email.resend.', 'notification.broadcast.email.'];
      case 'supabase':
        return ['auth.', 'session.'];
      case 'turnkey':
        return ['wallet.provision.'];
      case 'bsc':
        return ['wallet.deposit.', 'wallet.withdrawal.'];
      case 'x':
        return ['ops.social.x.'];
      case 'instagram':
        return ['ops.social.instagram.'];
      case 'tiktok':
        return ['ops.social.tiktok.'];
      case 'youtube':
        return ['ops.social.youtube.'];
      case 'linkedin':
        return ['ops.social.linkedin.'];
      case 'discord':
        return ['ops.social.discord.'];
      case 'telegram':
        return ['ops.social.telegram.'];
      case 'internal':
        return ['tip.', 'notification.broadcast.', 'ops.', 'wallet.', 'auth.', 'session.'];
      case 'unknown':
        return null;
      default:
        return null;
    }
  }
}
