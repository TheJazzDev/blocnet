"use client";

import Link from "next/link";
import {
  ArrowRight,
  Brain,
  CheckCircle2,
  GitMerge,
  RefreshCw,
  Settings2,
  Sparkles,
  Users,
} from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { useAdminSession } from "@/components/admin-shell";
import { canMutateWallet } from "@/lib/rbac";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { MetricCard, actionBadge, urgencyBadge } from "./edge-ui";
import { formatDateTime } from "../_lib/edge-admin";
import { useEdgeAdminData } from "../_hooks/use-edge-admin-data";

export default function EdgeEngineCommandCenterPage() {
  const session = useAdminSession();
  const canMutateConfig = canMutateWallet(session.effectiveRoles);

  const {
    windowDays,
    setWindowDays,
    overview,
    edgeConfig,
    loading,
    refreshing,
    error,
    refresh,
  } = useEdgeAdminData(7);

  const decisions = overview?.totals.decisions ?? 0;
  const uniqueUsers = overview?.totals.uniqueUsers ?? 0;
  const avgEdgeScore = overview?.totals.avgEdgeScore ?? 0;
  const feedbackRate = overview?.feedback.feedbackRate ?? 0;
  const mlCoverageRate = overview?.ml.coverageRate ?? 0;
  const mlAnalyzed = overview?.ml.analyzedDecisions ?? 0;
  const mlAvgQuality = overview?.ml.avgQuality ?? 0;
  const mlAvgActionability = overview?.ml.avgActionability ?? 0;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Blocnet Edge Engine"
        description="Unified command center for Decision Engine, ML analysis, and runtime rollout."
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
            <RefreshCw className={`h-4 w-4 ${refreshing ? "animate-spin" : ""}`} />
            Refresh
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
                Read-only mode. Owner/Admin roles are required to mutate Edge Engine runtime config.
              </CardContent>
            </Card>
          )}

          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <MetricCard icon={Sparkles} title="Global Decisions" value={decisions.toLocaleString()} hint={`${windowDays}d window`} />
            <MetricCard icon={Users} title="Active Users" value={uniqueUsers.toLocaleString()} hint="Users receiving decisions" />
            <MetricCard icon={GitMerge} title="Avg Final Score" value={avgEdgeScore.toFixed(3)} hint="Current combined output" />
            <MetricCard icon={CheckCircle2} title="Feedback Rate" value={`${(feedbackRate * 100).toFixed(1)}%`} hint="Feedback / decisions" />
            <MetricCard icon={Brain} title="ML Coverage" value={`${(mlCoverageRate * 100).toFixed(1)}%`} hint={`${mlAnalyzed.toLocaleString()} analyzed decisions`} />
            <MetricCard icon={Brain} title="ML Avg Quality" value={mlAvgQuality.toFixed(3)} hint="Model quality estimate" />
            <MetricCard icon={Brain} title="ML Actionability" value={mlAvgActionability.toFixed(3)} hint="Model actionability estimate" />
            <MetricCard
              icon={Settings2}
              title="Runtime State"
              value={edgeConfig?.enabled ? "Enabled" : "Disabled"}
              hint={`ML ${edgeConfig?.mlEnabled ? "enabled" : "disabled"}`}
            />
          </div>

          <div className="grid gap-4 lg:grid-cols-3">
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Decision Engine</CardTitle>
                <CardDescription>
                  Inspect core Edge logic output, urgency/relevance components, and global decision ranking.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Button asChild className="w-full justify-between">
                  <Link href="/edge-engine/decision-engine">
                    Open Decision Engine
                    <ArrowRight className="h-4 w-4" />
                  </Link>
                </Button>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-base">ML Analysis</CardTitle>
                <CardDescription>
                  Review ML sentiment, topics, provider usage, and per-decision ML enrichments.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Button asChild className="w-full justify-between">
                  <Link href="/edge-engine/ml-analysis">
                    Open ML Analysis
                    <ArrowRight className="h-4 w-4" />
                  </Link>
                </Button>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-base">Settings</CardTitle>
                <CardDescription>
                  Configure runtime toggles, ML provider options, timeouts, and model defaults.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Button asChild className="w-full justify-between">
                  <Link href="/edge-engine/settings">
                    Open Settings
                    <ArrowRight className="h-4 w-4" />
                  </Link>
                </Button>
              </CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Combined Dispatch Preview</CardTitle>
              <CardDescription>
                Final scored decisions with both core decision signals and ML enrichment status.
              </CardDescription>
            </CardHeader>
            <CardContent>
              {!overview || overview.topDecisions.length === 0 ? (
                <p className="text-sm text-muted-foreground">No decisions available.</p>
              ) : (
                <div className="space-y-2">
                  {overview.topDecisions.slice(0, 8).map((decision) => (
                    <div key={decision.decisionId} className="rounded-lg border p-3">
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
                      <div className="mt-2 flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
                        <span>Final score: {decision.edgeScore.toFixed(3)}</span>
                        <span>Core urgency: {decision.components.urgency.toFixed(3)}</span>
                        <span>
                          ML: {decision.ml.quality !== null ? `quality ${decision.ml.quality.toFixed(3)}` : "not available"}
                        </span>
                        {decision.ml.provider ? <Badge variant="outline">{decision.ml.provider}</Badge> : null}
                        {decision.ml.sentiment ? <Badge variant="outline">{decision.ml.sentiment}</Badge> : null}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Runtime Snapshot</CardTitle>
              <CardDescription>Current rollout flags and last config update for Edge Engine.</CardDescription>
            </CardHeader>
            <CardContent className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
              <div className="rounded-md border p-3">
                <p className="text-xs text-muted-foreground">BEE Runtime</p>
                <p className="text-sm font-semibold">{edgeConfig?.enabled ? "Enabled" : "Disabled"}</p>
              </div>
              <div className="rounded-md border p-3">
                <p className="text-xs text-muted-foreground">ML Runtime</p>
                <p className="text-sm font-semibold">{edgeConfig?.mlEnabled ? "Enabled" : "Disabled"}</p>
              </div>
              <div className="rounded-md border p-3">
                <p className="text-xs text-muted-foreground">ML Provider</p>
                <p className="text-sm font-semibold">{edgeConfig?.mlProvider ?? "auto"}</p>
              </div>
              <div className="rounded-md border p-3">
                <p className="text-xs text-muted-foreground">Last Updated</p>
                <p className="text-sm font-semibold">{formatDateTime(edgeConfig?.updatedAt ?? null)}</p>
              </div>
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
}
