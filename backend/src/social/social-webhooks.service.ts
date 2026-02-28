import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AuditLogService } from '../audit-log/audit-log.service';

type NormalizedSocialPayload = {
  provider: string;
  action: string;
  resourceType: string;
  resourceId: string | null;
  summary: string;
  metadata: Record<string, unknown>;
};

@Injectable()
export class SocialWebhooksService {
  constructor(
    private readonly configService: ConfigService,
    private readonly auditLogService: AuditLogService,
  ) {}

  isConfigured() {
    return (
      (this.configService.get<string>('SOCIAL_WEBHOOK_SECRET') ?? '')
        .trim()
        .length > 0
    );
  }

  verifySecret(input: string | null | undefined) {
    const expected =
      this.configService.get<string>('SOCIAL_WEBHOOK_SECRET')?.trim() ?? '';
    if (!expected) return false;
    return (input ?? '').trim() === expected;
  }

  async processWebhook(input: {
    provider: string;
    payload: Record<string, unknown>;
    requestId?: string | null;
    sourceIp?: string | null;
  }) {
    const normalized = this.normalizePayload(input);

    await this.auditLogService.create({
      action: normalized.action,
      resourceType: normalized.resourceType,
      resourceId: normalized.resourceId ?? undefined,
      metadata: normalized.metadata,
    });

    return {
      accepted: true,
      provider: normalized.provider,
      action: normalized.action,
      summary: normalized.summary,
    };
  }

  private normalizePayload(input: {
    provider: string;
    payload: Record<string, unknown>;
    requestId?: string | null;
    sourceIp?: string | null;
  }): NormalizedSocialPayload {
    const provider = normalizeProvider(input.provider);
    const payload = input.payload;
    const metricsPayload = pickMetricsObject(payload);

    const followers = toNumber(
      readFirst(metricsPayload, [
        'followers',
        'followerCount',
        'followersCount',
        'subscribers',
        'subscriberCount',
      ]),
    );
    const following = toNumber(
      readFirst(metricsPayload, [
        'following',
        'followingCount',
        'friends',
        'friendsCount',
      ]),
    );
    const posts = toNumber(
      readFirst(metricsPayload, [
        'posts',
        'postCount',
        'mediaCount',
        'tweetCount',
        'videoCount',
      ]),
    );
    const impressions = toNumber(
      readFirst(metricsPayload, ['impressions', 'impressionCount']),
    );
    const reach = toNumber(readFirst(metricsPayload, ['reach', 'reachCount']));
    const engagement = toNumber(
      readFirst(metricsPayload, [
        'engagement',
        'engagementCount',
        'engagementRate',
      ]),
    );
    const likes = toNumber(readFirst(metricsPayload, ['likes', 'likeCount']));
    const comments = toNumber(
      readFirst(metricsPayload, ['comments', 'commentCount']),
    );
    const shares = toNumber(
      readFirst(metricsPayload, ['shares', 'shareCount', 'retweets']),
    );

    const accountId = toStringValue(
      readFirst(payload, ['accountId', 'userId', 'channelId', 'profileId']),
    );
    const accountHandle = toStringValue(
      readFirst(payload, ['accountHandle', 'username', 'handle']),
    );
    const eventType = toStringValue(
      readFirst(payload, ['eventType', 'type', 'event']),
    );
    const providerEventId = toStringValue(
      readFirst(payload, ['eventId', 'id', 'messageId']),
    );
    const occurredAt = toStringValue(
      readFirst(payload, ['occurredAt', 'timestamp', 'createdAt']),
    );

    const metrics = {
      ...(followers !== null ? { followers } : {}),
      ...(following !== null ? { following } : {}),
      ...(posts !== null ? { posts } : {}),
      ...(impressions !== null ? { impressions } : {}),
      ...(reach !== null ? { reach } : {}),
      ...(engagement !== null ? { engagement } : {}),
      ...(likes !== null ? { likes } : {}),
      ...(comments !== null ? { comments } : {}),
      ...(shares !== null ? { shares } : {}),
    };

    const hasMetrics = Object.keys(metrics).length > 0;
    const summary = hasMetrics
      ? this.composeSummary({ provider, followers, following, posts })
      : `Received ${provider} webhook event`;

    return {
      provider,
      action: hasMetrics
        ? `ops.social.${provider}.metrics.snapshot`
        : `ops.social.${provider}.event.received`,
      resourceType: hasMetrics ? 'social_metric_snapshot' : 'social_event',
      resourceId: providerEventId ?? accountId ?? null,
      summary,
      metadata: {
        status: 'success',
        source: 'social',
        provider,
        eventType,
        occurredAt,
        accountId,
        accountHandle,
        providerEventId,
        metrics,
        summary,
        requestId: input.requestId ?? null,
        sourceIp: input.sourceIp ?? null,
      },
    };
  }

  private composeSummary(input: {
    provider: string;
    followers: number | null;
    following: number | null;
    posts: number | null;
  }) {
    const bits: string[] = [];
    if (input.followers !== null) bits.push(`followers=${input.followers}`);
    if (input.following !== null) bits.push(`following=${input.following}`);
    if (input.posts !== null) bits.push(`posts=${input.posts}`);

    if (bits.length === 0) {
      return `${input.provider} metrics snapshot received`;
    }
    return `${input.provider} snapshot: ${bits.join(' · ')}`;
  }
}

function normalizeProvider(value: string) {
  const normalized = value.trim().toLowerCase().replace(/[^a-z0-9_-]/g, '');
  if (normalized.length === 0) return 'unknown';
  return normalized.slice(0, 40);
}

function toStringValue(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function toNumber(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string') {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return null;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return !!value && typeof value === 'object' && !Array.isArray(value);
}

function pickMetricsObject(
  payload: Record<string, unknown>,
): Record<string, unknown> {
  const metrics = payload.metrics;
  if (isRecord(metrics)) return metrics;
  const data = payload.data;
  if (isRecord(data)) return data;
  return payload;
}

function readFirst(
  payload: Record<string, unknown>,
  keys: string[],
): unknown | null {
  for (const key of keys) {
    const value = payload[key];
    if (value !== undefined && value !== null) {
      return value;
    }
  }
  return null;
}
