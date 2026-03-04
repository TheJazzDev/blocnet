"use client";

import { Brain, CheckCircle2, Loader2, Sparkles } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { MetricCell, actionBadge, urgencyBadge } from "../../_components/edge-ui";
import { formatDateTime } from "../../_lib/edge-admin";
import type { useEdgeAdminData } from "../../_hooks/use-edge-admin-data";

type EdgeOverview = ReturnType<typeof useEdgeAdminData>["overview"];
type Decision = NonNullable<EdgeOverview>["topDecisions"][number];
type FeedbackAction = "act" | "watch" | "ignore";

type DecisionSelectionPanelsProps = {
  overview: EdgeOverview;
  selectedDecision: Decision | null;
  feedbackLoadingAction: FeedbackAction | null;
  feedbackStatus: string | null;
  onSelectDecisionId: (decisionId: string) => void;
  onSubmitFeedback: (action: FeedbackAction) => Promise<void>;
  clearFeedbackStatus: () => void;
};

export function DecisionSelectionPanels({
  overview,
  selectedDecision,
  feedbackLoadingAction,
  feedbackStatus,
  onSelectDecisionId,
  onSubmitFeedback,
  clearFeedbackStatus,
}: DecisionSelectionPanelsProps) {
  const topDecisions = overview?.topDecisions ?? [];

  return (
    <div className="grid gap-4 xl:grid-cols-3">
      <Card className="xl:col-span-2">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-base">
            <Sparkles className="h-4 w-4" />
            Global Top Decisions
          </CardTitle>
          <CardDescription>
            Cross-user highest ranked decisions in this window.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {topDecisions.length === 0 ? (
            <p className="text-sm text-muted-foreground">No decisions available.</p>
          ) : (
            <div className="space-y-2">
              {topDecisions.map((decision) => {
                const selected = decision.decisionId === (selectedDecision?.decisionId ?? null);
                return (
                  <button
                    key={decision.decisionId}
                    type="button"
                    onClick={() => {
                      onSelectDecisionId(decision.decisionId);
                      clearFeedbackStatus();
                    }}
                    className={`w-full rounded-lg border p-3 text-left transition ${
                      selected
                        ? "border-primary/40 bg-primary/5"
                        : "border-border hover:bg-muted/40"
                    }`}
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-semibold">{decision.update.title}</p>
                        <p className="mt-1 truncate text-xs text-muted-foreground">
                          {decision.project.name} ·{" "}
                          {decision.user.displayName ?? decision.user.email}
                        </p>
                      </div>
                      <div className="flex items-center gap-2">
                        {urgencyBadge(decision.update.urgency)}
                        {actionBadge(decision.recommendedAction)}
                      </div>
                    </div>
                    <div className="mt-2 flex items-center justify-between text-xs">
                      <span className="truncate text-muted-foreground">
                        {decision.explanationPreview}
                      </span>
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
          <CardDescription>
            Core component and reason audit for selected decision.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          {selectedDecision ? (
            <>
              <div className="rounded-lg border p-3">
                <p className="text-xs text-muted-foreground">Decision ID</p>
                <p className="truncate text-xs font-medium">
                  {selectedDecision.decisionId}
                </p>
              </div>
              <div className="rounded-lg border p-3">
                <p className="text-xs font-semibold">{selectedDecision.update.title}</p>
                <p className="mt-1 text-xs text-muted-foreground">
                  {selectedDecision.project.name} ·{" "}
                  {selectedDecision.user.displayName ?? selectedDecision.user.email}
                </p>
                <p className="text-xs text-muted-foreground">
                  Generated {formatDateTime(selectedDecision.generatedAt)}
                </p>
              </div>
              <div className="grid grid-cols-2 gap-2 text-xs">
                <MetricCell label="Edge Score" value={selectedDecision.edgeScore.toFixed(3)} />
                <MetricCell label="Recommended" value={selectedDecision.recommendedAction} />
                <MetricCell
                  label="Urgency"
                  value={selectedDecision.components.urgency.toFixed(3)}
                />
                <MetricCell
                  label="Recency"
                  value={selectedDecision.components.recency.toFixed(3)}
                />
                <MetricCell
                  label="Relevance"
                  value={selectedDecision.components.relevance.toFixed(3)}
                />
                <MetricCell
                  label="Novelty"
                  value={selectedDecision.components.novelty.toFixed(3)}
                />
                <MetricCell
                  label="Penalties"
                  value={selectedDecision.components.penalties.toFixed(3)}
                />
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
                  onClick={() => void onSubmitFeedback("act")}
                >
                  {feedbackLoadingAction === "act" ? (
                    <Loader2 className="h-3.5 w-3.5 animate-spin" />
                  ) : null}
                  Act
                </Button>
                <Button
                  size="sm"
                  className="bg-amber-600 hover:bg-amber-500 text-black"
                  disabled={!!feedbackLoadingAction}
                  onClick={() => void onSubmitFeedback("watch")}
                >
                  {feedbackLoadingAction === "watch" ? (
                    <Loader2 className="h-3.5 w-3.5 animate-spin" />
                  ) : null}
                  Watch
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  disabled={!!feedbackLoadingAction}
                  onClick={() => void onSubmitFeedback("ignore")}
                >
                  {feedbackLoadingAction === "ignore" ? (
                    <Loader2 className="h-3.5 w-3.5 animate-spin" />
                  ) : null}
                  Ignore
                </Button>
              </div>
              {feedbackStatus && (
                <p className="text-xs text-muted-foreground">{feedbackStatus}</p>
              )}
            </>
          ) : (
            <p className="text-sm text-muted-foreground">
              Select a decision to inspect full reasoning.
            </p>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
