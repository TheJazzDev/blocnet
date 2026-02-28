"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import {
  Activity,
  ArrowUpRight,
  Brain,
  CheckCircle2,
  Loader2,
  RefreshCw,
  Sparkles,
  Users,
  AlertTriangle,
} from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { clientApi } from "@/lib/api-client";
import { MetricCard, MetricCell, actionBadge, urgencyBadge } from "../_components/edge-ui";
import { formatDateTime, formatRelativeTime } from "../_lib/edge-admin";
import { useEdgeAdminData } from "../_hooks/use-edge-admin-data";

type FeedbackAction = "act" | "watch" | "ignore";

export default function EdgeDecisionEnginePage() {
  const {
    windowDays,
    setWindowDays,
    overview,
    auditLog,
    loading,
    refreshing,
    error,
    refresh,
  } = useEdgeAdminData(7);

  const [selectedDecisionId, setSelectedDecisionId] = useState<string | null>(null);
  const [feedbackLoadingAction, setFeedbackLoadingAction] = useState<FeedbackAction | null>(null);
  const [feedbackStatus, setFeedbackStatus] = useState<string | null>(null);

  const edgeAuditEvents = useMemo(
    () => auditLog.filter((event) => event.action.startsWith("edge.")),
    [auditLog],
  );

  const selectedDecision = useMemo(
    () =>
      overview?.topDecisions.find(
        (decision) => decision.decisionId === selectedDecisionId,
      ) ?? overview?.topDecisions[0] ?? null,
    [overview, selectedDecisionId],
  );

  async function submitFeedback(action: FeedbackAction) {
    if (!selectedDecision) return;
    setFeedbackLoadingAction(action);
    setFeedbackStatus(null);
    try {
      const result = await clientApi.sendMyEdgeFeedback({
        decisionId: selectedDecision.decisionId,
        action,
        context: { surface: "admin_edge_engine_decision_engine" },
      });
      setFeedbackStatus(
        result.ok
          ? `Feedback captured: ${result.action.toUpperCase()} (${result.persisted ? "persisted" : "audit-only"})`
          : "Feedback request was not accepted",
      );
      await refresh();
    } catch (e: unknown) {
      setFeedbackStatus(e instanceof Error ? e.message : "Failed to submit feedback");
    } finally {
      setFeedbackLoadingAction(null);
    }
  }

  const decisions = overview?.totals.decisions ?? 0;
  const uniqueUsers = overview?.totals.uniqueUsers ?? 0;
  const uniqueProjects = overview?.totals.uniqueProjects ?? 0;
  const avgEdgeScore = overview?.totals.avgEdgeScore ?? 0;
  const feedbackRate = overview?.feedback.feedbackRate ?? 0;
  const explainViews = overview?.telemetry.explainViews ?? 0;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Edge Engine · Decision Engine"
        description="Core decision output, component scoring, and global decision inspection."
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
          <Button variant="outline" onClick={() => void refresh()} disabled={loading || refreshing}>
            {refreshing ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
            Refresh
          </Button>
          <Button variant="outline" asChild>
            <Link href="/edge-engine/settings">Open Runtime Settings</Link>
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
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-6">
            <MetricCard icon={Sparkles} title="Global Decisions" value={decisions.toLocaleString()} hint={`${windowDays}d window`} />
            <MetricCard icon={Users} title="Active Users" value={uniqueUsers.toLocaleString()} hint="Users with decisions" />
            <MetricCard icon={AlertTriangle} title="Projects Impacted" value={uniqueProjects.toLocaleString()} hint="Projects in ranking output" />
            <MetricCard icon={ArrowUpRight} title="Avg Edge Score" value={avgEdgeScore.toFixed(3)} hint="Core decision quality" />
            <MetricCard icon={CheckCircle2} title="Feedback Rate" value={`${(feedbackRate * 100).toFixed(1)}%`} hint="Feedback / decisions" />
            <MetricCard icon={Brain} title="Explain Views" value={explainViews.toLocaleString()} hint="Inspector engagement" />
          </div>

          <div className="grid gap-4 xl:grid-cols-3">
            <Card className="xl:col-span-2">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-base">
                  <Sparkles className="h-4 w-4" />
                  Global Top Decisions
                </CardTitle>
                <CardDescription>Cross-user highest ranked decisions in this window.</CardDescription>
              </CardHeader>
              <CardContent>
                {!overview || overview.topDecisions.length === 0 ? (
                  <p className="text-sm text-muted-foreground">No decisions available.</p>
                ) : (
                  <div className="space-y-2">
                    {overview.topDecisions.map((decision) => {
                      const selected = decision.decisionId === (selectedDecision?.decisionId ?? null);
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
                <CardDescription>Core component and reason audit for selected decision.</CardDescription>
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
                <CardDescription>Global event telemetry from audit logs and counters.</CardDescription>
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
