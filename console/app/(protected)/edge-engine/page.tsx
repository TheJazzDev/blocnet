"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import {
  Activity,
  AlertTriangle,
  ArrowUpRight,
  Brain,
  CheckCircle2,
  Loader2,
  RefreshCw,
  Sparkles,
  Users,
} from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import {
  clientApi,
  type AdminEdgeConfig,
  type AdminEdgeOverviewResponse,
  type AuditLog,
} from "@/lib/api-client";
import { useAdminSession } from "@/components/admin-shell";
import { canMutateWallet } from "@/lib/rbac";

type FeedbackAction = "act" | "watch" | "ignore";

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

function actionBadge(action: string) {
  if (action === "act") return <Badge className="bg-emerald-500/15 text-emerald-300">Act</Badge>;
  if (action === "watch") return <Badge className="bg-amber-500/15 text-amber-300">Watch</Badge>;
  return <Badge variant="secondary">Ignore</Badge>;
}

function urgencyBadge(urgency: string) {
  if (urgency === "high") {
    return <Badge className="bg-red-500/15 text-red-300">High</Badge>;
  }
  if (urgency === "medium") {
    return <Badge className="bg-amber-500/15 text-amber-300">Medium</Badge>;
  }
  return <Badge className="bg-slate-500/15 text-slate-300">Low</Badge>;
}

export default function EdgeEnginePage() {
  const session = useAdminSession();
  const canMutateConfig = canMutateWallet(session.effectiveRoles);

  const [windowDays, setWindowDays] = useState(7);
  const [overview, setOverview] = useState<AdminEdgeOverviewResponse | null>(null);
  const [edgeConfig, setEdgeConfig] = useState<AdminEdgeConfig | null>(null);
  const [auditLog, setAuditLog] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [configSaving, setConfigSaving] = useState(false);
  const [configStatus, setConfigStatus] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const [selectedDecisionId, setSelectedDecisionId] = useState<string | null>(null);
  const [feedbackLoadingAction, setFeedbackLoadingAction] = useState<FeedbackAction | null>(null);
  const [feedbackStatus, setFeedbackStatus] = useState<string | null>(null);

  async function loadData({
    withSpinner,
    nextWindowDays,
  }: {
    withSpinner: boolean;
    nextWindowDays: number;
  }) {
    if (withSpinner) {
      setLoading(true);
    } else {
      setRefreshing(true);
    }
    setError(null);

    try {
      const [overviewRes, configRes, logsRes] = await Promise.all([
        clientApi.getAdminEdgeOverview(nextWindowDays, 24, 8, 12),
        clientApi.getAdminEdgeConfig(),
        clientApi.listAuditLog(250),
      ]);

      setOverview(overviewRes);
      setEdgeConfig(configRes);
      setAuditLog(logsRes);

      if (
        !selectedDecisionId ||
        !overviewRes.topDecisions.some((decision) => decision.decisionId === selectedDecisionId)
      ) {
        setSelectedDecisionId(overviewRes.topDecisions[0]?.decisionId ?? null);
      }
    } catch (e: unknown) {
      setOverview(null);
      setEdgeConfig(null);
      setAuditLog([]);
      setSelectedDecisionId(null);
      setError(e instanceof Error ? e.message : "Failed to load Edge Engine data");
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }

  useEffect(() => {
    void loadData({ withSpinner: true, nextWindowDays: windowDays });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (!loading) {
      void loadData({ withSpinner: false, nextWindowDays: windowDays });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [windowDays]);

  async function submitFeedback(action: FeedbackAction) {
    if (!selectedDecisionId) return;
    setFeedbackLoadingAction(action);
    setFeedbackStatus(null);
    try {
      const result = await clientApi.sendMyEdgeFeedback({
        decisionId: selectedDecisionId,
        action,
        context: { surface: "admin_edge_engine_global_v2" },
      });
      setFeedbackStatus(
        result.ok
          ? `Feedback captured: ${result.action.toUpperCase()} (${result.persisted ? "persisted" : "audit-only"})`
          : "Feedback request was not accepted",
      );
      await loadData({ withSpinner: false, nextWindowDays: windowDays });
    } catch (e: unknown) {
      setFeedbackStatus(e instanceof Error ? e.message : "Failed to submit feedback");
    } finally {
      setFeedbackLoadingAction(null);
    }
  }

  async function saveEdgeConfig() {
    if (!edgeConfig) return;
    setConfigSaving(true);
    setConfigStatus(null);
    try {
      const next = await clientApi.updateAdminEdgeConfig({
        enabled: edgeConfig.enabled,
      });
      setEdgeConfig(next);
      setConfigStatus(`BEE is now ${next.enabled ? "enabled" : "disabled"} and applied immediately.`);
      await loadData({ withSpinner: false, nextWindowDays: windowDays });
    } catch (e: unknown) {
      setConfigStatus(e instanceof Error ? e.message : "Failed to update BEE config");
    } finally {
      setConfigSaving(false);
    }
  }

  const edgeAuditEvents = useMemo(
    () => auditLog.filter((event) => event.action.startsWith("edge.")),
    [auditLog],
  );

  const selectedDecision = useMemo(
    () =>
      overview?.topDecisions.find(
        (decision) => decision.decisionId === selectedDecisionId,
      ) ?? null,
    [overview, selectedDecisionId],
  );

  const decisions = overview?.totals.decisions ?? 0;
  const uniqueUsers = overview?.totals.uniqueUsers ?? 0;
  const uniqueProjects = overview?.totals.uniqueProjects ?? 0;
  const avgEdgeScore = overview?.totals.avgEdgeScore ?? 0;
  const feedbackRate = overview?.feedback.feedbackRate ?? 0;
  const explainViews = overview?.telemetry.explainViews ?? 0;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Blocnet Edge Engine"
        description="V2 Sprint 1 global analytics console for BEE across users and projects."
      >
        <div className="flex items-center gap-2">
          <label htmlFor="windowDays" className="text-xs text-muted-foreground">
            Window
          </label>
          <select
            id="windowDays"
            className="h-9 rounded-md border bg-background px-2 text-xs"
            value={windowDays}
            onChange={(event) => setWindowDays(Number(event.target.value))}
            disabled={loading || refreshing}
          >
            <option value={7}>7 days</option>
            <option value={14}>14 days</option>
            <option value={30}>30 days</option>
          </select>
          <Button
            variant="outline"
            onClick={() => void loadData({ withSpinner: false, nextWindowDays: windowDays })}
            disabled={loading || refreshing}
          >
            {refreshing ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
            Refresh
          </Button>
          <Button variant="outline" asChild>
            <Link href="/audit-log">Open Audit Log</Link>
          </Button>
        </div>
      </PageHeader>

      {error && (
        <Card className="border-destructive/30">
          <CardContent className="pt-6 text-sm text-destructive">{error}</CardContent>
        </Card>
      )}

      {loading ? (
        <Card>
          <CardContent className="pt-6">
            <LoadingSpinner className="py-10" />
          </CardContent>
        </Card>
      ) : (
        <>
          {!canMutateConfig && (
            <Card className="border-amber-500/30 bg-amber-500/5">
              <CardContent className="pt-6 text-sm text-amber-200">
                Read-only mode. Owner/Admin roles are required to toggle BEE.
              </CardContent>
            </Card>
          )}

          <Card>
            <CardHeader>
              <CardTitle className="text-base">BEE Runtime Config</CardTitle>
              <CardDescription>
                Toggle Blocnet Edge Engine instantly from admin without restarting backend.
              </CardDescription>
            </CardHeader>
            <CardContent className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <label htmlFor="beeEnabled" className="text-sm font-medium">
                  BEE Status
                </label>
                <select
                  id="beeEnabled"
                  className="h-10 w-full rounded-md border bg-background px-3 text-sm"
                  value={edgeConfig?.enabled ? "true" : "false"}
                  onChange={(event) =>
                    setEdgeConfig((prev) =>
                      prev ? { ...prev, enabled: event.target.value === "true" } : prev,
                    )
                  }
                  disabled={!canMutateConfig || !edgeConfig || configSaving}
                >
                  <option value="true">Enabled</option>
                  <option value="false">Disabled</option>
                </select>
              </div>
              <div className="space-y-2">
                <p className="text-sm font-medium">Last Updated</p>
                <p className="rounded-md border px-3 py-2 text-sm text-muted-foreground">
                  {formatDateTime(edgeConfig?.updatedAt ?? null)}
                </p>
              </div>
              <div className="md:col-span-2 flex items-center justify-between gap-3">
                <p className="text-xs text-muted-foreground">
                  Current runtime state: {overview?.enabled ? "enabled" : "disabled"}.
                </p>
                <Button
                  onClick={() => void saveEdgeConfig()}
                  disabled={!canMutateConfig || !edgeConfig || configSaving}
                >
                  {configSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
                  Save BEE Config
                </Button>
              </div>
              {configStatus ? (
                <p className="md:col-span-2 text-xs text-muted-foreground">{configStatus}</p>
              ) : null}
            </CardContent>
          </Card>

          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-6">
            <MetricCard icon={Sparkles} title="Global Decisions" value={decisions.toLocaleString()} hint={`${windowDays}d window`} />
            <MetricCard icon={Users} title="Active Users" value={uniqueUsers.toLocaleString()} hint="Users with BEE decisions" />
            <MetricCard icon={AlertTriangle} title="Projects Impacted" value={uniqueProjects.toLocaleString()} hint="Projects in rank output" />
            <MetricCard icon={ArrowUpRight} title="Avg Edge Score" value={avgEdgeScore.toFixed(3)} hint="Aggregate decision quality" />
            <MetricCard icon={CheckCircle2} title="Feedback Rate" value={`${(feedbackRate * 100).toFixed(1)}%`} hint="Feedback / decisions" />
            <MetricCard icon={Brain} title="Explain Views" value={explainViews.toLocaleString()} hint="Drilldown engagement" />
          </div>

          <div className="grid gap-4 xl:grid-cols-3">
            <Card className="xl:col-span-2">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-base">
                  <Sparkles className="h-4 w-4" />
                  Global Top Decisions
                </CardTitle>
                <CardDescription>Cross-user highest ranked BEE decisions in this window.</CardDescription>
              </CardHeader>
              <CardContent>
                {!overview || overview.topDecisions.length === 0 ? (
                  <p className="text-sm text-muted-foreground">No decisions available.</p>
                ) : (
                  <div className="space-y-2">
                    {overview.topDecisions.map((decision) => {
                      const selected = decision.decisionId === selectedDecisionId;
                      return (
                        <button
                          key={decision.decisionId}
                          type="button"
                          onClick={() => {
                            setSelectedDecisionId(decision.decisionId);
                            setFeedbackStatus(null);
                          }}
                          className={`w-full rounded-lg border p-3 text-left transition ${
                            selected ? "border-primary/40 bg-primary/5" : "border-border hover:bg-muted/40"
                          }`}
                        >
                          <div className="flex items-start justify-between gap-3">
                            <div className="min-w-0 flex-1">
                              <p className="truncate text-sm font-semibold">{decision.update.title}</p>
                              <p className="mt-1 truncate text-xs text-muted-foreground">
                                {decision.project.name} · {decision.user.displayName ?? decision.user.email}
                              </p>
                            </div>
                            <div className="flex items-center gap-2">
                              {urgencyBadge(decision.update.urgency)}
                              {actionBadge(decision.recommendedAction)}
                            </div>
                          </div>
                          <div className="mt-2 flex items-center justify-between text-xs">
                            <span className="truncate text-muted-foreground">{decision.explanationPreview}</span>
                            <span className="font-semibold text-foreground">
                              Score {decision.edgeScore.toFixed(3)}
                            </span>
                          </div>
                        </button>
                      );
                    })}
                  </div>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-base">
                  <Brain className="h-4 w-4" />
                  Decision Inspector
                </CardTitle>
                <CardDescription>Component and reason audit for selected global decision.</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                {selectedDecision ? (
                  <>
                    <div className="rounded-lg border p-3">
                      <p className="text-xs text-muted-foreground">Decision ID</p>
                      <p className="truncate text-xs font-medium">{selectedDecision.decisionId}</p>
                    </div>
                    <div className="rounded-lg border p-3">
                      <p className="text-xs font-semibold">{selectedDecision.update.title}</p>
                      <p className="mt-1 text-xs text-muted-foreground">
                        {selectedDecision.project.name} · {selectedDecision.user.displayName ?? selectedDecision.user.email}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        Generated {formatDateTime(selectedDecision.generatedAt)}
                      </p>
                    </div>
                    <div className="grid grid-cols-2 gap-2 text-xs">
                      <MetricCell label="Edge Score" value={selectedDecision.edgeScore.toFixed(3)} />
                      <MetricCell label="Recommended" value={selectedDecision.recommendedAction} />
                      <MetricCell label="Urgency" value={selectedDecision.components.urgency.toFixed(3)} />
                      <MetricCell label="Recency" value={selectedDecision.components.recency.toFixed(3)} />
                      <MetricCell label="Relevance" value={selectedDecision.components.relevance.toFixed(3)} />
                      <MetricCell label="Novelty" value={selectedDecision.components.novelty.toFixed(3)} />
                      <MetricCell label="Penalties" value={selectedDecision.components.penalties.toFixed(3)} />
                    </div>
                    <div className="rounded-lg border p-3">
                      <p className="text-xs text-muted-foreground">Preview</p>
                      <p className="mt-1 text-xs">{selectedDecision.explanationPreview}</p>
                    </div>
                    <div className="flex flex-wrap gap-1.5">
                      {selectedDecision.reasonCodes.map((reason) => (
                        <Badge key={reason} variant="outline" className="text-[10px]">
                          {reason}
                        </Badge>
                      ))}
                    </div>
                    <div className="grid grid-cols-3 gap-2">
                      <Button
                        size="sm"
                        className="bg-emerald-600 hover:bg-emerald-500"
                        disabled={!!feedbackLoadingAction}
                        onClick={() => void submitFeedback("act")}
                      >
                        {feedbackLoadingAction === "act" ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : null}
                        Act
                      </Button>
                      <Button
                        size="sm"
                        className="bg-amber-600 hover:bg-amber-500 text-black"
                        disabled={!!feedbackLoadingAction}
                        onClick={() => void submitFeedback("watch")}
                      >
                        {feedbackLoadingAction === "watch" ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : null}
                        Watch
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        disabled={!!feedbackLoadingAction}
                        onClick={() => void submitFeedback("ignore")}
                      >
                        {feedbackLoadingAction === "ignore" ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : null}
                        Ignore
                      </Button>
                    </div>
                    {feedbackStatus && <p className="text-xs text-muted-foreground">{feedbackStatus}</p>}
                  </>
                ) : (
                  <p className="text-sm text-muted-foreground">Select a decision to inspect full reasoning.</p>
                )}
              </CardContent>
            </Card>
          </div>

          <div className="grid gap-4 lg:grid-cols-3">
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Top Projects Under Pressure</CardTitle>
                <CardDescription>Projects with highest decision concentration.</CardDescription>
              </CardHeader>
              <CardContent>
                {!overview || overview.topProjects.length === 0 ? (
                  <p className="text-sm text-muted-foreground">No project-level pressure data available.</p>
                ) : (
                  <div className="space-y-2">
                    {overview.topProjects.map((project) => (
                      <div key={project.projectId} className="rounded-lg border p-3">
                        <div className="flex items-center justify-between gap-2">
                          <p className="text-sm font-semibold">{project.projectName}</p>
                          <Badge variant="outline">{project.avgEdgeScore.toFixed(3)} avg</Badge>
                        </div>
                        <div className="mt-2 flex flex-wrap gap-2 text-xs text-muted-foreground">
                          <span>{project.decisionCount} decisions</span>
                          <span>{project.highUrgencyCount} high urgency</span>
                          <span>Last: {formatDateTime(project.lastDecisionAt)}</span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-base">Top Reason Codes</CardTitle>
                <CardDescription>
                  Extracted from {overview?.topReasons.sampledDecisions ?? 0} sampled decisions.
                </CardDescription>
              </CardHeader>
              <CardContent>
                {!overview || overview.topReasons.items.length === 0 ? (
                  <p className="text-sm text-muted-foreground">No reason-code data available.</p>
                ) : (
                  <div className="space-y-2">
                    {overview.topReasons.items.map((reason) => (
                      <div key={reason.reasonCode} className="flex items-center justify-between rounded-lg border px-3 py-2">
                        <p className="truncate text-xs font-medium">{reason.reasonCode}</p>
                        <Badge variant="outline">{reason.count}</Badge>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-base">
                  <Activity className="h-4 w-4" />
                  Edge Telemetry
                </CardTitle>
                <CardDescription>Global event telemetry from audit logs and BEE counters.</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="grid grid-cols-2 gap-2">
                  <MetricCell label="Feed Views" value={`${overview?.telemetry.feedViews ?? 0}`} />
                  <MetricCell label="Brief Views" value={`${overview?.telemetry.briefViews ?? 0}`} />
                  <MetricCell label="Explain Views" value={`${overview?.telemetry.explainViews ?? 0}`} />
                  <MetricCell label="Feedback Events" value={`${overview?.telemetry.feedbackEvents ?? 0}`} />
                </div>
                <div className="rounded-lg border p-3">
                  <p className="text-xs text-muted-foreground">Last feedback event</p>
                  <p className="mt-1 text-xs font-medium">
                    {overview?.feedback.lastFeedbackAt
                      ? formatDateTime(overview.feedback.lastFeedbackAt)
                      : "No feedback yet"}
                  </p>
                </div>
                <div className="space-y-2">
                  {edgeAuditEvents.slice(0, 10).map((event) => (
                    <div
                      key={event.id}
                      className="flex items-start justify-between gap-2 rounded-md border px-2.5 py-2"
                    >
                      <div className="min-w-0">
                        <p className="truncate text-xs font-medium">{event.action}</p>
                        <p className="truncate text-[11px] text-muted-foreground">
                          {event.resourceType} · {event.resourceId ?? "—"}
                        </p>
                      </div>
                      <p className="shrink-0 text-[11px] text-muted-foreground">{formatRelativeTime(event.createdAt)}</p>
                    </div>
                  ))}
                  {edgeAuditEvents.length === 0 && (
                    <p className="text-sm text-muted-foreground">No edge events found in recent audit log entries.</p>
                  )}
                </div>
              </CardContent>
            </Card>
          </div>
        </>
      )}
    </div>
  );
}

function MetricCard({
  title,
  value,
  hint,
  icon: Icon,
}: {
  title: string;
  value: string;
  hint: string;
  icon: React.ComponentType<{ className?: string }>;
}) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">{title}</CardTitle>
        <Icon className="h-4 w-4 text-muted-foreground" />
      </CardHeader>
      <CardContent>
        <p className="text-2xl font-bold">{value}</p>
        <p className="mt-1 text-xs text-muted-foreground">{hint}</p>
      </CardContent>
    </Card>
  );
}

function MetricCell({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-lg border p-2">
      <p className="text-[10px] text-muted-foreground">{label}</p>
      <p className="text-xs font-semibold">{value}</p>
    </div>
  );
}
