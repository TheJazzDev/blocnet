import type { AdminEdgeOverviewResponse } from "@/lib/api-client";

export function formatRelativeTime(dateStr: string) {
  const diff = Date.now() - new Date(dateStr).getTime();
  const minutes = Math.floor(diff / 60_000);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  return `${Math.floor(hours / 24)}d ago`;
}

export function formatDateTime(dateStr: string | null) {
  if (!dateStr) return "—";
  return new Date(dateStr).toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function dedupeTopDecisions(
  overview: AdminEdgeOverviewResponse,
): AdminEdgeOverviewResponse {
  const seen = new Set<string>();
  const topDecisions = overview.topDecisions.filter((decision) => {
    if (seen.has(decision.decisionId)) {
      return false;
    }
    seen.add(decision.decisionId);
    return true;
  });

  return { ...overview, topDecisions };
}
