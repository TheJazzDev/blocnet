"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import {
  Activity,
  AlertTriangle,
  ArrowUpRight,
  Bell,
  Brain,
  Clock,
  FileCheck,
  FolderKanban,
  Loader2,
  RefreshCw,
  Sparkles,
  TrendingUp,
  Users,
} from "lucide-react";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { PageHeader } from "@/components/page-header";
import {
  clientApi,
  type AdminStats,
  type AuditLog,
  type EdgeBriefResponse,
  type EdgeExplainResponse,
} from "@/lib/api-client";
import { DashboardHealthCard } from "./dashboard-health-card";

function formatRelativeTime(dateStr: string) {
  const diff = Date.now() - new Date(dateStr).getTime();
  const minutes = Math.floor(diff / 60_000);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  return `${Math.floor(hours / 24)}d ago`;
}

function formatDateTime(dateStr: string | null) {
  if (!dateStr) return "—";
  return new Date(dateStr).toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function getActionBadgeVariant(action: string) {
  if (action.includes("create") || action.includes("promote")) return "default";
  if (action.includes("review") || action.includes("approve")) return "secondary";
  if (action.includes("delete") || action.includes("archive")) return "destructive";
  return "outline" as const;
}

function parseAuditNumber(value: unknown) {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return 0;
}

const ACTIVITY_PAGE_SIZE = 10;
const TELEMETRY_LOG_LIMIT = 160;

export default function DashboardPage() {
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [activityLogs, setActivityLogs] = useState<AuditLog[]>([]);
  const [telemetryLogs, setTelemetryLogs] = useState<AuditLog[]>([]);
  const [edgeBrief, setEdgeBrief] = useState<EdgeBriefResponse | null>(null);
  const [edgeExplain, setEdgeExplain] = useState<EdgeExplainResponse | null>(null);
  const [edgeExplainLoading, setEdgeExplainLoading] = useState(false);
  const [selectedDecisionId, setSelectedDecisionId] = useState<string | null>(null);
  const [activityPage, setActivityPage] = useState(0);
  const [activityHasNext, setActivityHasNext] = useState(false);
  const [activityLoading, setActivityLoading] = useState(false);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);

  async function loadDashboard(withSpinner: boolean) {
    if (withSpinner) {
      setLoading(true);
    } else {
      setRefreshing(true);
    }
    setLoadError(null);

    try {
      const [s, firstLogs, telemetry, edge] = await Promise.all([
        clientApi.getStats(),
        clientApi.listAuditLog(ACTIVITY_PAGE_SIZE, 0),
        clientApi.listAuditLog(TELEMETRY_LOG_LIMIT, 0),
        clientApi.getMyEdgeBrief(7),
      ]);
      setStats(s);
      setActivityLogs(firstLogs);
      setTelemetryLogs(telemetry);
      setActivityPage(0);
      setActivityHasNext(firstLogs.length === ACTIVITY_PAGE_SIZE);
      setEdgeBrief(edge);
    } catch (e: unknown) {
      setStats(null);
      setActivityLogs([]);
      setTelemetryLogs([]);
      setActivityPage(0);
      setActivityHasNext(false);
      setEdgeBrief(null);
      setLoadError(e instanceof Error ? e.message : "Failed to load dashboard data");
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }

  useEffect(() => {
    void loadDashboard(true);
  }, []);

  useEffect(() => {
    if (!edgeBrief || selectedDecisionId || edgeBrief.topDecisions.length === 0) return;
    void handleOpenEdgeDecision(edgeBrief.topDecisions[0].decisionId);
  }, [edgeBrief, selectedDecisionId]);

  async function handleOpenEdgeDecision(decisionId: string) {
    setSelectedDecisionId(decisionId);
    setEdgeExplainLoading(true);
    try {
      const explain = await clientApi.getMyEdgeExplain(decisionId);
      setEdgeExplain(explain);
    } catch {
      setEdgeExplain(null);
    } finally {
      setEdgeExplainLoading(false);
    }
  }

  async function loadActivityPage(nextPage: number) {
    if (nextPage < 0 || loading || activityLoading) return;

    setActivityLoading(true);
    setLoadError(null);
    try {
      const offset = nextPage * ACTIVITY_PAGE_SIZE;
      const nextLogs = await clientApi.listAuditLog(ACTIVITY_PAGE_SIZE, offset);
      setActivityLogs(nextLogs);
      setActivityPage(nextPage);
      setActivityHasNext(nextLogs.length === ACTIVITY_PAGE_SIZE);
    } catch (e: unknown) {
      setLoadError(e instanceof Error ? e.message : "Failed to load activity page");
    } finally {
      setActivityLoading(false);
    }
  }

  const edgeAuditEvents = useMemo(
    () => telemetryLogs.filter((event) => event.action.startsWith("edge.")),
    [telemetryLogs],
  );

  const edgeTelemetry = useMemo(() => {
    const counters = {
      feedItemsServed: 0,
      briefViews: 0,
      explainViews: 0,
      feedbackAct: 0,
      feedbackWatch: 0,
      feedbackIgnore: 0,
      feedbackTotal: 0,
    };

    for (const event of edgeAuditEvents) {
      if (event.action === "edge.feed.view") {
        const returned = parseAuditNumber(event.metadata?.returned);
        counters.feedItemsServed += returned > 0 ? returned : 1;
      } else if (event.action === "edge.brief.view") {
        counters.briefViews += 1;
      } else if (event.action === "edge.explain.view") {
        counters.explainViews += 1;
      } else if (event.action === "edge.feedback.act") {
        counters.feedbackAct += 1;
      } else if (event.action === "edge.feedback.watch") {
        counters.feedbackWatch += 1;
      } else if (event.action === "edge.feedback.ignore") {
        counters.feedbackIgnore += 1;
      }
    }

    counters.feedbackTotal = counters.feedbackAct + counters.feedbackWatch + counters.feedbackIgnore;
    return counters;
  }, [edgeAuditEvents]);

  const statCards = stats
    ? [
        {
          title: "Total Projects",
          value: stats.totalProjects.toLocaleString(),
          change: `${stats.totalUpdates} updates published`,
          icon: FolderKanban,
        },
        {
          title: "Total Users",
          value: stats.totalUsers.toLocaleString(),
          change: `${stats.activeUsers.toLocaleString()} active`,
          icon: Users,
        },
        {
          title: "Pending Queue",
          value: (stats.pendingAdminApps + stats.pendingProposals).toString(),
          change: `${stats.pendingAdminApps} role apps · ${stats.pendingProposals} proposals`,
          icon: FileCheck,
        },
        {
          title: "Total Content",
          value: (stats.totalUpdates + stats.totalComments).toLocaleString(),
          change: `${stats.totalComments} comments`,
          icon: TrendingUp,
        },
      ]
    : [];

  const activeRate = stats && stats.totalUsers > 0 ? (stats.activeUsers / stats.totalUsers) * 100 : 0;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Dashboard"
        description="Operations command center for content, governance, health, and Edge intelligence."
      >
        <Button variant="outline" asChild>
          <Link href="/edge-engine">
            <Sparkles className="h-4 w-4" />
            Open Edge Engine
          </Link>
        </Button>
        <Button variant="outline" onClick={() => void loadDashboard(false)} disabled={loading || refreshing}>
          {refreshing ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
          Refresh
        </Button>
      </PageHeader>

      {loadError && (
        <Card className="border-destructive/30">
          <CardContent className="pt-6 text-sm text-destructive">{loadError}</CardContent>
        </Card>
      )}

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {loading
          ? <LoadingSpinner className="py-10 sm:col-span-2 xl:col-span-4" />
          : statCards.map((stat) => (
              <Card key={stat.title}>
                <CardHeader className="flex flex-row items-center justify-between pb-2">
                  <CardTitle className="text-sm font-medium text-muted-foreground">
                    {stat.title}
                  </CardTitle>
                  <stat.icon className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{stat.value}</div>
                  <div className="mt-1 flex items-center gap-1 text-xs text-muted-foreground">
                    <ArrowUpRight className="h-3 w-3 text-emerald-500" />
                    {stat.change}
                  </div>
                </CardContent>
              </Card>
            ))}
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base">
              <AlertTriangle className="h-4 w-4" />
              Operational Queue
            </CardTitle>
            <CardDescription>Pending governance, user status pressure, and delivery posture.</CardDescription>
          </CardHeader>
          <CardContent>
            {loading || !stats ? (
              <LoadingSpinner className="py-8" />
            ) : (
              <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
                <MetricCell
                  label="Pending Role Apps"
                  value={stats.pendingAdminApps.toLocaleString()}
                  hint="Awaiting review"
                />
                <MetricCell
                  label="Pending Proposals"
                  value={stats.pendingProposals.toLocaleString()}
                  hint="Project approvals"
                />
                <MetricCell
                  label="Deactivated Users"
                  value={stats.deactivatedUsers.toLocaleString()}
                  hint="Needs follow-up"
                />
                <MetricCell
                  label="Active User Rate"
                  value={`${activeRate.toFixed(1)}%`}
                  hint={`${stats.activeUsers.toLocaleString()} / ${stats.totalUsers.toLocaleString()}`}
                />
              </div>
            )}
          </CardContent>
        </Card>

        <DashboardHealthCard />
      </div>

      <div className="grid gap-4 xl:grid-cols-3">
        <Card className="xl:col-span-2">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base">
              <Brain className="h-4 w-4" />
              BEE Snapshot
            </CardTitle>
            <CardDescription>Signal volume, quality pressure, and recent usage telemetry.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            {loading ? (
              <LoadingSpinner className="py-8" />
            ) : edgeBrief ? (
              <>
                <p className="text-sm text-muted-foreground">{edgeBrief.headline}</p>
                <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-4">
                  <MetricCell label="Signals" value={edgeBrief.totalSignals.toString()} hint="7d window" />
                  <MetricCell label="Act Now" value={edgeBrief.recommendedNowCount.toString()} hint="Critical items" />
                  <MetricCell label="Watch" value={edgeBrief.watchCount.toString()} hint="Monitor queue" />
                  <MetricCell label="High Urgency" value={edgeBrief.highUrgencyCount.toString()} hint="Priority pressure" />
                </div>
                <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-4">
                  <MetricCell
                    label="Feedback"
                    value={edgeTelemetry.feedbackTotal.toString()}
                    hint={`${edgeTelemetry.feedbackAct} act · ${edgeTelemetry.feedbackWatch} watch · ${edgeTelemetry.feedbackIgnore} ignore`}
                  />
                  <MetricCell label="Explain Opens" value={edgeTelemetry.explainViews.toString()} hint="Inspector usage" />
                  <MetricCell label="Brief Views" value={edgeTelemetry.briefViews.toString()} hint="Read frequency" />
                  <MetricCell label="Feed Items Served" value={edgeTelemetry.feedItemsServed.toString()} hint="Recent logs" />
                </div>
                {edgeBrief.topProjects.length > 0 && (
                  <div className="rounded-lg border p-3">
                    <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                      Top Projects Under Pressure
                    </p>
                    <div className="space-y-2">
                      {edgeBrief.topProjects.slice(0, 3).map((project) => (
                        <div key={project.projectId} className="flex items-center justify-between gap-2 text-xs">
                          <div className="min-w-0">
                            <p className="truncate font-medium text-foreground">{project.projectName}</p>
                            <p className="text-muted-foreground">
                              {project.count} decisions · {project.highUrgencyCount} high urgency
                            </p>
                          </div>
                          <Badge variant="outline">{project.avgEdgeScore.toFixed(3)}</Badge>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </>
            ) : (
              <p className="text-sm text-muted-foreground">Edge brief unavailable for this account yet.</p>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base">
              <Sparkles className="h-4 w-4" />
              Decision Drilldown
            </CardTitle>
            <CardDescription>Reason codes and component scores for top Edge decisions.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            {loading ? (
              <LoadingSpinner className="py-6" />
            ) : edgeBrief?.topDecisions.length ? (
              <>
                <div className="space-y-2">
                  {edgeBrief.topDecisions.slice(0, 4).map((decision) => (
                    <button
                      key={decision.decisionId}
                      type="button"
                      onClick={() => void handleOpenEdgeDecision(decision.decisionId)}
                      className="w-full rounded-md border p-2 text-left transition hover:bg-muted/40"
                    >
                      <p className="truncate text-xs font-medium">{decision.title}</p>
                      <div className="mt-1 flex items-center justify-between gap-2 text-[11px] text-muted-foreground">
                        <span className="truncate">{decision.projectName}</span>
                        <Badge variant="outline" className="text-[10px]">
                          {decision.recommendedAction}
                        </Badge>
                      </div>
                    </button>
                  ))}
                </div>
                {(selectedDecisionId || edgeExplainLoading) && (
                  <div className="rounded-md border p-2">
                    <div className="mb-2 flex items-center justify-between">
                      <p className="text-xs font-semibold">Inspector</p>
                      {selectedDecisionId && (
                        <span className="truncate text-[10px] text-muted-foreground">
                          {selectedDecisionId}
                        </span>
                      )}
                    </div>
                    {edgeExplainLoading ? (
                      <LoadingSpinner className="py-2" />
                    ) : edgeExplain?.explanation ? (
                      <div className="space-y-2 text-[11px]">
                        <p className="text-muted-foreground">{edgeExplain.explanation.narrative}</p>
                        <div className="grid grid-cols-2 gap-2">
                          <MetricCell label="Score" value={edgeExplain.explanation.edgeScore.toFixed(3)} hint="" />
                          <MetricCell label="Action" value={edgeExplain.explanation.recommendedAction} hint="" />
                          <MetricCell label="Urgency" value={edgeExplain.explanation.components.urgency.toFixed(3)} hint="" />
                          <MetricCell label="Recency" value={edgeExplain.explanation.components.recency.toFixed(3)} hint="" />
                          <MetricCell label="Relevance" value={edgeExplain.explanation.components.relevance.toFixed(3)} hint="" />
                          <MetricCell label="Novelty" value={edgeExplain.explanation.components.novelty.toFixed(3)} hint="" />
                          <MetricCell label="Penalties" value={edgeExplain.explanation.components.penalties.toFixed(3)} hint="" />
                        </div>
                        <div className="flex flex-wrap gap-1.5">
                          {edgeExplain.explanation.reasonCodes.map((reason) => (
                            <Badge key={reason} variant="outline" className="text-[10px]">
                              {reason}
                            </Badge>
                          ))}
                        </div>
                      </div>
                    ) : (
                      <p className="text-[11px] text-muted-foreground">Explanation unavailable.</p>
                    )}
                  </div>
                )}
                <Button variant="outline" className="w-full" asChild>
                  <Link href="/edge-engine">Open Full Edge Console</Link>
                </Button>
              </>
            ) : (
              <p className="text-sm text-muted-foreground">No top decisions available yet.</p>
            )}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-base">
            <Activity className="h-4 w-4" />
            Recent Activity
          </CardTitle>
          <CardDescription>Latest operations across moderation, governance, and BEE events.</CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <LoadingSpinner className="py-10" />
          ) : activityLogs.length === 0 ? (
            <p className="text-sm text-muted-foreground">No audit events found.</p>
          ) : (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <p className="text-xs text-muted-foreground">
                  Page {activityPage + 1} · {ACTIVITY_PAGE_SIZE} events
                </p>
                <div className="flex items-center gap-2">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => void loadActivityPage(activityPage - 1)}
                    disabled={activityPage === 0 || activityLoading}
                  >
                    Prev
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => void loadActivityPage(activityPage + 1)}
                    disabled={!activityHasNext || activityLoading}
                  >
                    Next
                  </Button>
                </div>
              </div>

              {activityLoading ? (
                <LoadingSpinner className="py-4" />
              ) : (
                activityLogs.map((event) => (
                  <div
                    key={event.id}
                    className="flex items-start justify-between gap-4 border-b pb-4 last:border-0 last:pb-0"
                  >
                    <div className="min-w-0 flex-1">
                      <Badge
                        variant={getActionBadgeVariant(event.action)}
                        className="shrink-0 text-[10px]"
                      >
                        {event.action.replace(".", " ")}
                      </Badge>
                      <p className="mt-1.5 text-sm font-medium">{event.action}</p>
                      <p className="text-xs text-muted-foreground">
                        {event.resourceType} · {event.resourceId ?? "—"}
                      </p>
                    </div>
                    <div className="shrink-0 text-right">
                      <p className="text-xs text-muted-foreground">
                        {event.actor?.email ?? "System"}
                      </p>
                      <p className="mt-0.5 flex items-center justify-end gap-1 text-[11px] text-muted-foreground">
                        <Clock className="h-3 w-3" />
                        {formatRelativeTime(event.createdAt)}
                      </p>
                      <p className="text-[10px] text-muted-foreground">{formatDateTime(event.createdAt)}</p>
                    </div>
                  </div>
                ))
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {(loading || stats) && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Quick Stats</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {loading ? (
              <LoadingSpinner className="py-6" />
            ) : stats ? (
              <>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Total Comments</span>
                  <span className="text-sm font-medium">{stats.totalComments.toLocaleString()}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Active Hunters</span>
                  <span className="text-sm font-medium">{stats.activeHunters}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Primary Tags</span>
                  <span className="text-sm font-medium">{stats.totalTags} total</span>
                </div>
                <div className="flex items-center justify-between border-t pt-3">
                  <span className="flex items-center gap-1.5 text-sm text-muted-foreground">
                    <Bell className="h-3.5 w-3.5" />
                    Push Enabled
                  </span>
                  <span className="text-sm font-medium">{stats.usersWithPushEnabled} users</span>
                </div>
              </>
            ) : null}
          </CardContent>
        </Card>
      )}
    </div>
  );
}

function MetricCell({
  label,
  value,
  hint,
}: {
  label: string;
  value: string;
  hint: string;
}) {
  return (
    <div className="rounded-lg border p-2">
      <p className="text-[10px] text-muted-foreground">{label}</p>
      <p className="text-sm font-semibold">{value}</p>
      {hint ? <p className="text-[10px] text-muted-foreground">{hint}</p> : null}
    </div>
  );
}
