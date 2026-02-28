"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import {
  BarChart3,
  Brain,
  Loader2,
  RefreshCw,
  Sparkles,
  Tags,
  Workflow,
} from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { MetricCard, MetricCell, actionBadge } from "../_components/edge-ui";
import { formatDateTime } from "../_lib/edge-admin";
import { useEdgeAdminData } from "../_hooks/use-edge-admin-data";

function isMlEnriched(decision: {
  ml: {
    quality: number | null;
    actionability: number | null;
    sentiment: string | null;
    topics: string[];
    insights: string[];
    provider: string | null;
  };
}) {
  return (
    decision.ml.quality !== null ||
    decision.ml.actionability !== null ||
    !!decision.ml.sentiment ||
    decision.ml.topics.length > 0 ||
    decision.ml.insights.length > 0 ||
    !!decision.ml.provider
  );
}

export default function EdgeMlAnalysisPage() {
  const {
    windowDays,
    setWindowDays,
    overview,
    loading,
    refreshing,
    error,
    refresh,
  } = useEdgeAdminData(7);

  const mlDecisions = useMemo(
    () => (overview?.topDecisions ?? []).filter((decision) => isMlEnriched(decision)),
    [overview],
  );
  const [selectedDecisionId, setSelectedDecisionId] = useState<string | null>(null);

  const selectedDecision = useMemo(
    () =>
      mlDecisions.find((decision) => decision.decisionId === selectedDecisionId) ??
      mlDecisions[0] ??
      null,
    [mlDecisions, selectedDecisionId],
  );

  return (
    <div className="space-y-6">
      <PageHeader
        title="Edge Engine · ML Analysis"
        description="Machine learning contributions, provider behavior, and enrichment quality across decisions."
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
            <Link href="/edge-engine/settings">Open ML Settings</Link>
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
            <MetricCard
              icon={Workflow}
              title="ML Runtime"
              value={overview?.ml.enabled ? "Enabled" : "Disabled"}
              hint="Config state"
            />
            <MetricCard
              icon={Brain}
              title="ML Coverage"
              value={`${((overview?.ml.coverageRate ?? 0) * 100).toFixed(1)}%`}
              hint={`${overview?.ml.analyzedDecisions ?? 0} analyzed decisions`}
            />
            <MetricCard
              icon={BarChart3}
              title="Avg Quality"
              value={(overview?.ml.avgQuality ?? 0).toFixed(3)}
              hint="Model quality output"
            />
            <MetricCard
              icon={BarChart3}
              title="Avg Actionability"
              value={(overview?.ml.avgActionability ?? 0).toFixed(3)}
              hint="Model actionability output"
            />
            <MetricCard
              icon={Sparkles}
              title="Positive Sentiment"
              value={`${overview?.ml.sentiments.positive ?? 0}`}
              hint="Window total"
            />
            <MetricCard
              icon={Sparkles}
              title="Negative Sentiment"
              value={`${overview?.ml.sentiments.negative ?? 0}`}
              hint="Window total"
            />
          </div>

          <div className="grid gap-4 lg:grid-cols-3">
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Sentiment Distribution</CardTitle>
                <CardDescription>Grouped sentiment labels from ML analysis output.</CardDescription>
              </CardHeader>
              <CardContent className="grid grid-cols-2 gap-2">
                <MetricCell label="Positive" value={`${overview?.ml.sentiments.positive ?? 0}`} />
                <MetricCell label="Neutral" value={`${overview?.ml.sentiments.neutral ?? 0}`} />
                <MetricCell label="Negative" value={`${overview?.ml.sentiments.negative ?? 0}`} />
                <MetricCell label="Other" value={`${overview?.ml.sentiments.other ?? 0}`} />
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-base">Provider Usage</CardTitle>
                <CardDescription>Which ML provider is producing enrichments.</CardDescription>
              </CardHeader>
              <CardContent>
                {overview?.ml.providers.length ? (
                  <div className="space-y-2">
                    {overview.ml.providers.map((provider) => (
                      <div key={provider.provider} className="flex items-center justify-between rounded-md border px-3 py-2">
                        <p className="text-xs font-medium">{provider.provider}</p>
                        <Badge variant="outline">{provider.count}</Badge>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-sm text-muted-foreground">No provider usage captured.</p>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-base">
                  <Tags className="h-4 w-4" />
                  Top ML Topics
                </CardTitle>
                <CardDescription>Most common ML topics in analyzed updates.</CardDescription>
              </CardHeader>
              <CardContent>
                {overview?.ml.topTopics.length ? (
                  <div className="flex flex-wrap gap-2">
                    {overview.ml.topTopics.slice(0, 16).map((topic) => (
                      <Badge key={topic.topic} variant="outline">
                        {topic.topic} ({topic.count})
                      </Badge>
                    ))}
                  </div>
                ) : (
                  <p className="text-sm text-muted-foreground">No topics captured yet.</p>
                )}
              </CardContent>
            </Card>
          </div>

          <div className="grid gap-4 xl:grid-cols-3">
            <Card className="xl:col-span-2">
              <CardHeader>
                <CardTitle className="text-base">ML-Enriched Decisions</CardTitle>
                <CardDescription>
                  Decisions where ML contributed quality, sentiment, actionability, topics, or insights.
                </CardDescription>
              </CardHeader>
              <CardContent>
                {mlDecisions.length === 0 ? (
                  <p className="text-sm text-muted-foreground">No ML-enriched decisions in this window.</p>
                ) : (
                  <div className="space-y-2">
                    {mlDecisions.map((decision) => {
                      const selected = decision.decisionId === selectedDecision?.decisionId;
                      return (
                        <button
                          key={decision.decisionId}
                          type="button"
                          onClick={() => setSelectedDecisionId(decision.decisionId)}
                          className={`w-full rounded-lg border p-3 text-left transition ${
                            selected ? "border-primary/40 bg-primary/5" : "border-border hover:bg-muted/40"
                          }`}
                        >
                          <div className="flex items-start justify-between gap-2">
                            <div className="min-w-0 flex-1">
                              <p className="truncate text-sm font-semibold">{decision.update.title}</p>
                              <p className="truncate text-xs text-muted-foreground">
                                {decision.project.name} · {decision.user.displayName ?? decision.user.email}
                              </p>
                            </div>
                            {actionBadge(decision.recommendedAction)}
                          </div>
                          <div className="mt-2 flex flex-wrap gap-2 text-xs text-muted-foreground">
                            <span>Edge {decision.edgeScore.toFixed(3)}</span>
                            <span>
                              Quality {decision.ml.quality !== null ? decision.ml.quality.toFixed(3) : "—"}
                            </span>
                            <span>
                              Actionability {decision.ml.actionability !== null ? decision.ml.actionability.toFixed(3) : "—"}
                            </span>
                            {decision.ml.provider ? <Badge variant="outline">{decision.ml.provider}</Badge> : null}
                            {decision.ml.sentiment ? <Badge variant="outline">{decision.ml.sentiment}</Badge> : null}
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
                <CardTitle className="text-base">ML Inspector</CardTitle>
                <CardDescription>Detailed ML payload for selected decision.</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                {selectedDecision ? (
                  <>
                    <div className="rounded-lg border p-3">
                      <p className="text-xs text-muted-foreground">Decision</p>
                      <p className="text-xs font-semibold">{selectedDecision.update.title}</p>
                      <p className="text-xs text-muted-foreground">
                        Generated {formatDateTime(selectedDecision.generatedAt)}
                      </p>
                    </div>
                    <div className="grid grid-cols-2 gap-2">
                      <MetricCell
                        label="ML Quality"
                        value={
                          selectedDecision.ml.quality !== null
                            ? selectedDecision.ml.quality.toFixed(3)
                            : "—"
                        }
                      />
                      <MetricCell
                        label="Actionability"
                        value={
                          selectedDecision.ml.actionability !== null
                            ? selectedDecision.ml.actionability.toFixed(3)
                            : "—"
                        }
                      />
                      <MetricCell label="Sentiment" value={selectedDecision.ml.sentiment ?? "—"} />
                      <MetricCell label="Provider" value={selectedDecision.ml.provider ?? "—"} />
                    </div>

                    <div className="rounded-lg border p-3">
                      <p className="text-xs text-muted-foreground">Topics</p>
                      {selectedDecision.ml.topics.length ? (
                        <div className="mt-2 flex flex-wrap gap-1.5">
                          {selectedDecision.ml.topics.map((topic) => (
                            <Badge key={topic} variant="outline" className="text-[10px]">
                              {topic}
                            </Badge>
                          ))}
                        </div>
                      ) : (
                        <p className="mt-1 text-xs text-muted-foreground">No ML topics attached.</p>
                      )}
                    </div>

                    <div className="rounded-lg border p-3">
                      <p className="text-xs text-muted-foreground">Insights</p>
                      {selectedDecision.ml.insights.length ? (
                        <ul className="mt-2 space-y-1">
                          {selectedDecision.ml.insights.map((insight) => (
                            <li key={insight} className="text-xs text-muted-foreground">
                              • {insight}
                            </li>
                          ))}
                        </ul>
                      ) : (
                        <p className="mt-1 text-xs text-muted-foreground">No ML insights attached.</p>
                      )}
                    </div>
                  </>
                ) : (
                  <p className="text-sm text-muted-foreground">Select an ML-enriched decision to inspect details.</p>
                )}
              </CardContent>
            </Card>
          </div>
        </>
      )}
    </div>
  );
}
