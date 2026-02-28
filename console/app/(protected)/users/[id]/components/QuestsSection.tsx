"use client";

import { Target, CheckCircle2, Clock, XCircle } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

type QuestsSectionProps = {
  userId: string;
};

/**
 * QuestsSection - Displays quest progress and submissions
 * TODO: Integrate with backend quests API endpoints
 */
export function QuestsSection({ userId }: QuestsSectionProps) {
  void userId;
  // TODO: Fetch quests data from API
  // const questsData = await clientApi.getUserQuestMetrics(userId)

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
            <p className="text-xl sm:text-2xl font-bold">—</p>
          </div>
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <CheckCircle2 className="h-4 w-4 text-emerald-400" />
              <p className="text-xs text-muted-foreground">Completed</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">—</p>
          </div>
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <Clock className="h-4 w-4 text-amber-400" />
              <p className="text-xs text-muted-foreground">In Progress</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">—</p>
          </div>
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <XCircle className="h-4 w-4 text-red-400" />
              <p className="text-xs text-muted-foreground">Pending Verification</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">—</p>
          </div>
        </div>

        <div className="border-t pt-4" />

        {/* Active Quests */}
        <div>
          <h4 className="text-xs sm:text-sm font-semibold mb-2">Active Quests</h4>
          <div className="text-center py-6 text-xs sm:text-sm text-muted-foreground">
            Quest data will be available here
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
