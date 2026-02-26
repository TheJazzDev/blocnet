"use client";

import { Pickaxe, TrendingUp, Users, Zap } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

type MiningSectionProps = {
  userId: string;
};

/**
 * MiningSection - Displays mining statistics and history
 * TODO: Integrate with backend mining API endpoints
 */
export function MiningSection({ userId }: MiningSectionProps) {
  // TODO: Fetch mining data from API
  // const miningData = await fetch(`/admin/mining/users/${userId}`)

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-sm sm:text-base flex items-center gap-2">
          <Pickaxe className="h-4 w-4 sm:h-5 sm:w-5" />
          Mining System
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Mining Stats Grid */}
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <Zap className="h-4 w-4 text-amber-400" />
              <p className="text-xs text-muted-foreground">Total Points</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">—</p>
          </div>
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <TrendingUp className="h-4 w-4 text-emerald-400" />
              <p className="text-xs text-muted-foreground">Hourly Rate</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">—</p>
          </div>
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <Users className="h-4 w-4 text-sky-400" />
              <p className="text-xs text-muted-foreground">Referral Bonus</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">—</p>
          </div>
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <Pickaxe className="h-4 w-4 text-purple-400" />
              <p className="text-xs text-muted-foreground">Active Session</p>
            </div>
            <Badge variant="secondary" className="text-xs mt-1">
              Not Available
            </Badge>
          </div>
        </div>

        <div className="border-t pt-4" />

        {/* Mining Sessions */}
        <div>
          <h4 className="text-xs sm:text-sm font-semibold mb-2">Recent Mining Sessions</h4>
          <div className="text-center py-6 text-xs sm:text-sm text-muted-foreground">
            Mining data will be available here
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
