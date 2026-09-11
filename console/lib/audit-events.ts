/**
 * Read-only audit actions (`*.view`) are recorded for telemetry but drown out
 * the mutations admins actually care about. Both the dashboard activity feed
 * and the audit log hide them by default (F-13).
 */
export function isViewAuditEvent(action: string): boolean {
  return action.endsWith(".view");
}

export type AuditEventFilterResult<T> = {
  visible: T[];
  hiddenViewCount: number;
};

export function filterViewAuditEvents<T extends { action: string }>(
  events: T[],
  includeViews: boolean,
): AuditEventFilterResult<T> {
  if (includeViews) {
    return { visible: events, hiddenViewCount: 0 };
  }
  const visible = events.filter((event) => !isViewAuditEvent(event.action));
  return { visible, hiddenViewCount: events.length - visible.length };
}
