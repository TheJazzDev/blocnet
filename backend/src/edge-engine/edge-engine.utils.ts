import { EdgeAction, Prisma, UpdateUrgency } from '@prisma/client';
import { EdgeFeedbackAction } from './dto/edge-feedback.dto';

export const EDGE_DECISION_PREFIX = 'edge:update:';
export const EDGE_CONFIG_ID = 'default';

export const EDGE_WEIGHTS = {
  urgency: 0.35,
  recency: 0.3,
  relevance: 0.2,
  novelty: 0.15,
} as const;

export type FollowPreference = {
  projectId: string;
  alertMinUrgency: UpdateUrgency;
};

export type EdgeFeedCursor = {
  createdAt: Date;
  id: string | null;
};

export const parseEdgeFeedCursor = (
  cursorRaw: string,
): EdgeFeedCursor | null => {
  const normalized = cursorRaw.trim();
  if (!normalized) return null;

  const [createdAtRaw, idRaw] = normalized.split('|', 2);
  const createdAt = new Date(createdAtRaw);
  if (Number.isNaN(createdAt.getTime())) {
    return null;
  }

  const id = idRaw?.trim();
  return {
    createdAt,
    id: id && id.length > 0 ? id : null,
  };
};

export const toEdgeFeedCursor = (createdAt: Date, updateId: string): string => {
  return `${createdAt.toISOString()}|${updateId}`;
};

export const parseDecisionId = (decisionId: string): string | null => {
  const normalized = decisionId.trim();
  if (!normalized.startsWith(EDGE_DECISION_PREFIX)) {
    return null;
  }

  const updateId = normalized.slice(EDGE_DECISION_PREFIX.length).trim();
  if (!updateId) return null;
  return updateId;
};

export const clamp01 = (value: number) => Math.max(0, Math.min(1, value));

export const roundScore = (value: number) => Number(value.toFixed(4));

export const urgencyScore = (urgency: UpdateUrgency) => {
  switch (urgency) {
    case UpdateUrgency.high:
      return 1;
    case UpdateUrgency.medium:
      return 0.65;
    case UpdateUrgency.low:
    default:
      return 0.35;
  }
};

export const urgencyRank = (urgency: UpdateUrgency) => {
  switch (urgency) {
    case UpdateUrgency.high:
      return 3;
    case UpdateUrgency.medium:
      return 2;
    case UpdateUrgency.low:
    default:
      return 1;
  }
};

export const recencyScore = (createdAt: Date, asOf: Date) => {
  const hours = Math.max(0, (asOf.getTime() - createdAt.getTime()) / 3_600_000);
  return roundScore(clamp01(Math.exp(-hours / 72)));
};

export const noveltyScore = (createdAt: Date, asOf: Date) => {
  const hours = Math.max(0, (asOf.getTime() - createdAt.getTime()) / 3_600_000);
  if (hours <= 24) return 1;
  if (hours <= 72) return 0.75;
  if (hours <= 168) return 0.55;
  return 0.35;
};

export const relevanceScore = (
  urgency: UpdateUrgency,
  followPreference: FollowPreference | undefined,
) => {
  if (!followPreference) {
    return 0.7;
  }

  const meetsMinUrgency =
    urgencyRank(urgency) >= urgencyRank(followPreference.alertMinUrgency);
  return meetsMinUrgency ? 1 : 0.65;
};

export const penaltyScore = (
  urgency: UpdateUrgency,
  followPreference: FollowPreference | undefined,
) => {
  if (!followPreference) return 0;
  const meetsMinUrgency =
    urgencyRank(urgency) >= urgencyRank(followPreference.alertMinUrgency);
  return meetsMinUrgency ? 0 : 0.12;
};

export const toRecommendedAction = (
  edgeScore: number,
  urgency: UpdateUrgency,
  recency: number,
): EdgeFeedbackAction => {
  if (
    edgeScore >= 0.72 ||
    (urgency === UpdateUrgency.high && recency >= 0.55)
  ) {
    return EdgeFeedbackAction.act;
  }
  if (edgeScore >= 0.46) {
    return EdgeFeedbackAction.watch;
  }
  return EdgeFeedbackAction.ignore;
};

export const toReasonCodes = (
  urgency: UpdateUrgency,
  recency: number,
  followPreference: FollowPreference | undefined,
  edgeScore: number,
  hasTags: boolean,
) => {
  const reasons: string[] = [`urgency.${urgency}`];

  if (recency >= 0.75) {
    reasons.push('recency.fresh');
  } else if (recency <= 0.3) {
    reasons.push('recency.stale');
  }

  if (followPreference) {
    const meetsMinUrgency =
      urgencyRank(urgency) >= urgencyRank(followPreference.alertMinUrgency);
    reasons.push(
      meetsMinUrgency ? 'prefs.meets_min_urgency' : 'prefs.below_min_urgency',
    );
  }

  if (edgeScore >= 0.72) {
    reasons.push('edge.top_signal');
  } else if (edgeScore >= 0.46) {
    reasons.push('edge.watchlist');
  } else {
    reasons.push('edge.low_priority');
  }

  if (hasTags) {
    reasons.push('tags.present');
  }

  return reasons;
};

export const toExplanationPreview = (action: EdgeFeedbackAction) => {
  switch (action) {
    case EdgeFeedbackAction.act:
      return 'High-value signal with strong urgency and freshness.';
    case EdgeFeedbackAction.watch:
      return 'Relevant signal worth monitoring.';
    case EdgeFeedbackAction.ignore:
    default:
      return 'Lower-priority signal for now.';
  }
};

export const toPrismaEdgeAction = (action: EdgeFeedbackAction): EdgeAction => {
  switch (action) {
    case EdgeFeedbackAction.act:
      return EdgeAction.act;
    case EdgeFeedbackAction.watch:
      return EdgeAction.watch;
    case EdgeFeedbackAction.ignore:
    default:
      return EdgeAction.ignore;
  }
};

export const toFeedbackAction = (action: EdgeAction): EdgeFeedbackAction => {
  switch (action) {
    case EdgeAction.act:
      return EdgeFeedbackAction.act;
    case EdgeAction.watch:
      return EdgeFeedbackAction.watch;
    case EdgeAction.ignore:
    default:
      return EdgeFeedbackAction.ignore;
  }
};

export const normalizeReasonCodes = (value: Prisma.JsonValue | null) => {
  if (!Array.isArray(value)) return [];
  return value
    .map((entry) =>
      typeof entry === 'string' || typeof entry === 'number'
        ? String(entry)
        : '',
    )
    .filter((entry) => entry.trim().length > 0);
};
