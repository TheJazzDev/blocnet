"use client";

import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { MetricCell, actionBadge } from "../../_components/edge-ui";
import { formatDateTime } from "../../_lib/edge-admin";
import type { useEdgeAdminData } from "../../_hooks/use-edge-admin-data";

type EdgeOverview = ReturnType<typeof useEdgeAdminData>["overview"];
type MlDecision = NonNullable<EdgeOverview>["topDecisions"][number];

type MlDecisionPanelsProps = {
  mlDecisions: MlDecision[];
  selectedDecision: MlDecision | null;
  selectedDecisionId: string | null;
  onSelectDecisionId: (decisionId: string) => void;
};

export function MlDecisionPanels({
  mlDecisions,
  selectedDecision,
  selectedDecisionId,
  onSelectDecisionId,
}: MlDecisionPanelsProps) {
  return (
    <div className="grid gap-4 xl:grid-cols-3">
      <Card className="xl:col-span-2">
        <CardHeader>
          <CardTitle className="text-base">ML-Enriched Decisions</CardTitle>
          <CardDescription>
            Decisions where ML contributed quality, sentiment, actionability,
            topics, or insights.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {mlDecisions.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              No ML-enriched decisions in this window.
            </p>
          ) : (
            <div className="space-y-2">
              {mlDecisions.map((decision) => {
                const selected = decision.decisionId === (selectedDecisionId ?? selectedDecision?.decisionId);
                return (
                  <button
                    key={decision.decisionId}
                    type="button"
                    onClick={() => onSelectDecisionId(decision.decisionId)}
                    className={`w-full rounded-lg border p-3 text-left transition ${
                      selected
                        ? "border-primary/40 bg-primary/5"
                        : "border-border hover:bg-muted/40"
                    }`}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-semibold">
                          {decision.update.title}
                        </p>
                        <p className="truncate text-xs text-muted-foreground">
                          {decision.project.name} ·{" "}
                          {decision.user.displayName ?? decision.user.email}
                        </p>
                      </div>
                      {actionBadge(decision.recommendedAction)}
                    </div>
                    <div className="mt-2 flex flex-wrap gap-2 text-xs text-muted-foreground">
                      <span>Edge {decision.edgeScore.toFixed(3)}</span>
                      <span>
                        Quality{" "}
                        {decision.ml.quality !== null
                          ? decision.ml.quality.toFixed(3)
                          : "—"}
                      </span>
                      <span>
                        Actionability{" "}
                        {decision.ml.actionability !== null
                          ? decision.ml.actionability.toFixed(3)
                          : "—"}
                      </span>
                      {decision.ml.provider ? (
                        <Badge variant="outline">{decision.ml.provider}</Badge>
                      ) : null}
                      {decision.ml.sentiment ? (
                        <Badge variant="outline">{decision.ml.sentiment}</Badge>
                      ) : null}
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
          <CardDescription>
            Detailed ML payload for selected decision.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          {selectedDecision ? (
            <>
              <div className="rounded-lg border p-3">
                <p className="text-xs text-muted-foreground">Decision</p>
                <p className="text-xs font-semibold">
                  {selectedDecision.update.title}
                </p>
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
                <MetricCell
                  label="Sentiment"
                  value={selectedDecision.ml.sentiment ?? "—"}
                />
                <MetricCell
                  label="Provider"
                  value={selectedDecision.ml.provider ?? "—"}
                />
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
                  <p className="mt-1 text-xs text-muted-foreground">
                    No ML topics attached.
                  </p>
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
                  <p className="mt-1 text-xs text-muted-foreground">
                    No ML insights attached.
                  </p>
                )}
              </div>
            </>
          ) : (
            <p className="text-sm text-muted-foreground">
              Select an ML-enriched decision to inspect details.
            </p>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
