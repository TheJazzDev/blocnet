"use client";

import { Pickaxe, TrendingUp, Users, Zap } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import type { AdminUserDetail } from "@/lib/api-client";

type MiningSectionProps = {
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

function sessionStatusBadge(status: "running" | "claimable" | "claimed") {
  if (status === "running") {
    return <Badge className="bg-sky-500/15 text-sky-300 text-xs">Running</Badge>;
  }
  if (status === "claimable") {
    return <Badge className="bg-amber-500/15 text-amber-300 text-xs">Claimable</Badge>;
  }
  return <Badge className="bg-emerald-500/15 text-emerald-300 text-xs">Claimed</Badge>;
}

export function MiningSection({ user }: MiningSectionProps) {
  const { mining } = user;

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
            <p className="text-xl sm:text-2xl font-bold">
              {mining.lifetimeEarnedPoints.toLocaleString()}
            </p>
            <p className="text-[11px] text-muted-foreground mt-1">
              Claimed {mining.claimedTotalPoints.toLocaleString()} · Unclaimed{" "}
              {mining.maturedUnclaimedPoints.toLocaleString()}
            </p>
          </div>
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <TrendingUp className="h-4 w-4 text-emerald-400" />
              <p className="text-xs text-muted-foreground">Hourly Rate</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">
              {mining.hourlyRateNow.toLocaleString(undefined, {
                minimumFractionDigits: 0,
                maximumFractionDigits: 4,
              })}
            </p>
            <p className="text-[11px] text-muted-foreground mt-1">MCR/hour</p>
          </div>
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <Users className="h-4 w-4 text-sky-400" />
              <p className="text-xs text-muted-foreground">Referral Bonus</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">
              {mining.activeDirectReferrals.toLocaleString()}
            </p>
            <p className="text-[11px] text-muted-foreground mt-1">Active direct referrals</p>
          </div>
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <Pickaxe className="h-4 w-4 text-purple-400" />
              <p className="text-xs text-muted-foreground">Active Session</p>
            </div>
            {mining.activeSession ? (
              <div className="space-y-1">
                {sessionStatusBadge(mining.activeSession.status)}
                <p className="text-[11px] text-muted-foreground">
                  {mining.activeSession.progressPct.toFixed(1)}% progress
                </p>
              </div>
            ) : (
              <Badge variant="secondary" className="text-xs mt-1">
                No active session
              </Badge>
            )}
          </div>
        </div>

        <div className="border-t pt-4" />

        {/* Mining Sessions */}
        <div>
          <h4 className="text-xs sm:text-sm font-semibold mb-2">Recent Mining Sessions</h4>
          {mining.recentSessions.length === 0 ? (
            <div className="text-center py-6 text-xs sm:text-sm text-muted-foreground">
              No mining sessions found
            </div>
          ) : (
            <div className="space-y-2">
              {mining.recentSessions.map((session) => (
                <div
                  key={session.id}
                  className="rounded-md border p-3 bg-muted/30 text-xs sm:text-sm"
                >
                  <div className="flex items-center justify-between gap-2 mb-1">
                    <div className="font-medium">
                      {session.effectivePointsPerCycle.toLocaleString()} pts/cycle
                    </div>
                    {sessionStatusBadge(session.status)}
                  </div>
                  <div className="grid gap-1 text-muted-foreground">
                    <div>Start: {fmtDate(session.startsAt)}</div>
                    <div>End: {fmtDate(session.endsAt)}</div>
                    <div>
                      Claimed points: {session.claimedPoints.toLocaleString()} · Boost:{" "}
                      {(session.boostBpsSnapshot / 100).toFixed(2)}%
                    </div>
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
