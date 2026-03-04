import type { AuditLog } from '@/lib/api-client';

export const ACTIVITY_PAGE_SIZE = 10;
export const TELEMETRY_LOG_LIMIT = 160;

export function formatRelativeTime(dateStr: string) {
  const diff = Date.now() - new Date(dateStr).getTime();
  const minutes = Math.floor(diff / 60_000);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  return `${Math.floor(hours / 24)}d ago`;
}

export function formatDateTime(dateStr: string | null) {
  if (!dateStr) return '—';
  return new Date(dateStr).toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export function getActionBadgeVariant(action: string) {
  if (action.includes('create') || action.includes('promote')) return 'default';
  if (action.includes('review') || action.includes('approve')) return 'secondary';
  if (action.includes('delete') || action.includes('archive')) return 'destructive';
  return 'outline' as const;
}

export function parseAuditNumber(value: unknown) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string') {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return 0;
}

export function formatTokenAmount(
  value: string | null | undefined,
  maxDecimals = 2,
) {
  if (!value) return '0';
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return value;
  return parsed.toLocaleString('en-US', { maximumFractionDigits: maxDecimals });
}

export type EdgeTelemetry = {
  feedItemsServed: number;
  briefViews: number;
  explainViews: number;
  feedbackAct: number;
  feedbackWatch: number;
  feedbackIgnore: number;
  feedbackTotal: number;
};

export function buildEdgeTelemetry(events: AuditLog[]): EdgeTelemetry {
  const counters: EdgeTelemetry = {
    feedItemsServed: 0,
    briefViews: 0,
    explainViews: 0,
    feedbackAct: 0,
    feedbackWatch: 0,
    feedbackIgnore: 0,
    feedbackTotal: 0,
  };

  for (const event of events) {
    if (event.action === 'edge.feed.view') {
      const returned = parseAuditNumber(event.metadata?.returned);
      counters.feedItemsServed += returned > 0 ? returned : 1;
    } else if (event.action === 'edge.brief.view') {
      counters.briefViews += 1;
    } else if (event.action === 'edge.explain.view') {
      counters.explainViews += 1;
    } else if (event.action === 'edge.feedback.act') {
      counters.feedbackAct += 1;
    } else if (event.action === 'edge.feedback.watch') {
      counters.feedbackWatch += 1;
    } else if (event.action === 'edge.feedback.ignore') {
      counters.feedbackIgnore += 1;
    }
  }

  counters.feedbackTotal =
    counters.feedbackAct + counters.feedbackWatch + counters.feedbackIgnore;

  return counters;
}
