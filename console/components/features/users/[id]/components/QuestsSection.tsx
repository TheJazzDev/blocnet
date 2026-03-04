"use client";

import { Target, CheckCircle2, Clock, XCircle } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import type { AdminUserDetail } from "@/lib/api-client";

type QuestsSectionProps = {
  user: AdminUserDetail;
};

function fmtDate(value: string | null) {
  if (!value) return "—";
  try {
    return new Date(value).toLocaleString();
  } catch {
    return "—";
  }
}

function statusBadge(
  status:
    | "not_started"
    | "in_progress"
    | "pending_verification"
    | "completed"
    | "pending"
    | "approved"
    | "rejected",
) {
  if (status === "completed" || status === "approved") {
    return <Badge className="bg-emerald-500/15 text-emerald-300 text-xs">{status.replace("_", " ")}</Badge>;
  }
  if (status === "in_progress" || status === "pending_verification" || status === "pending") {
    return <Badge className="bg-amber-500/15 text-amber-300 text-xs">{status.replace("_", " ")}</Badge>;
  }
  return <Badge variant="secondary" className="text-xs">{status.replace("_", " ")}</Badge>;
}

export function QuestsSection({ user }: QuestsSectionProps) {
  const { quests } = user;
  const userQuestTotal =
    quests.userQuestCounts.notStarted +
    quests.userQuestCounts.inProgress +
    quests.userQuestCounts.pendingVerification +
    quests.userQuestCounts.completed;

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-sm sm:text-base flex items-center gap-2">
          <Target className="h-4 w-4 sm:h-5 sm:w-5" />
          Quests & Gamification
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Quest Stats */}
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <Target className="h-4 w-4 text-sky-400" />
              <p className="text-xs text-muted-foreground">Total Quests</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">{userQuestTotal.toLocaleString()}</p>
            <p className="text-[11px] text-muted-foreground mt-1">
              {quests.activeQuests.toLocaleString()} currently active
            </p>
          </div>
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <CheckCircle2 className="h-4 w-4 text-emerald-400" />
              <p className="text-xs text-muted-foreground">Completed</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">
              {quests.userQuestCounts.completed.toLocaleString()}
            </p>
          </div>
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <Clock className="h-4 w-4 text-amber-400" />
              <p className="text-xs text-muted-foreground">In Progress</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">
              {quests.userQuestCounts.inProgress.toLocaleString()}
            </p>
          </div>
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <XCircle className="h-4 w-4 text-red-400" />
              <p className="text-xs text-muted-foreground">Pending Verification</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">
              {quests.submissions.pending.toLocaleString()}
            </p>
            <p className="text-[11px] text-muted-foreground mt-1">
              Waiting admin review
            </p>
          </div>
        </div>

        <div className="border-t pt-4" />

        {/* Active Quests */}
        <div>
          <h4 className="text-xs sm:text-sm font-semibold mb-2">Recent Quest Progress</h4>
          {quests.recentProgress.length === 0 ? (
            <div className="text-center py-6 text-xs sm:text-sm text-muted-foreground">
              No quest progress found
            </div>
          ) : (
            <div className="space-y-2">
              {quests.recentProgress.map((entry) => (
                <div
                  key={entry.userQuestId}
                  className="rounded-md border p-3 bg-muted/30 text-xs sm:text-sm"
                >
                  <div className="flex items-center justify-between gap-2 mb-1">
                    <div className="font-medium">{entry.questTitle}</div>
                    {statusBadge(entry.status)}
                  </div>
                  <div className="grid gap-1 text-muted-foreground">
                    <div>
                      Progress: {entry.progress}% · Reward: {entry.rewardPoints.toLocaleString()} pts
                    </div>
                    <div>
                      Verification: {entry.verificationMethod} · Updated: {fmtDate(entry.updatedAt)}
                    </div>
                    {entry.lastSubmission ? (
                      <div className="flex items-center gap-2">
                        Submission: {statusBadge(entry.lastSubmission.verificationStatus)}
                        <span>
                          at {fmtDate(entry.lastSubmission.submittedAt)}
                        </span>
                      </div>
                    ) : null}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
