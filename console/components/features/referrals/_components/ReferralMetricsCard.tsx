"use client";

import { TrendingUp, Users, UserPlus, Award } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import type { AdminMiningMetrics } from "@/lib/api-client";

type ReferralMetricsCardProps = {
  metrics: AdminMiningMetrics | null;
  loading: boolean;
  error: string | null;
};

export function ReferralMetricsCard({
  metrics,
  loading,
  error,
}: ReferralMetricsCardProps) {
  if (loading) {
    return (
      <Card>
        <CardContent className="pt-6">
          <LoadingSpinner className="py-10" />
        </CardContent>
      </Card>
    );
  }

  if (error) {
    return (
      <Card>
        <CardContent className="pt-6 text-sm text-destructive">{error}</CardContent>
      </Card>
    );
  }

  if (!metrics) {
    return null;
  }

  const stats = [
    {
      label: "Total Users",
      value: metrics.totalUsers.toLocaleString(),
      icon: Users,
      color: "text-blue-400",
    },
    {
      label: "Users with Referrals",
      value: metrics.usersWithReferrals.toLocaleString(),
      icon: UserPlus,
      color: "text-emerald-400",
    },
    {
      label: "Active Referrers",
      value: metrics.activeReferrers.toLocaleString(),
      icon: Award,
      color: "text-amber-400",
    },
    {
      label: "Referral Rate",
      value: `${((metrics.usersWithReferrals / metrics.totalUsers) * 100).toFixed(1)}%`,
      icon: TrendingUp,
      color: "text-purple-400",
    },
  ];

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-sm sm:text-base">Referral Metrics</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {stats.map((stat) => (
            <div
              key={stat.label}
              className="rounded-md border p-3 sm:p-4 bg-muted/30"
            >
              <div className="flex items-center gap-2 mb-1">
                <stat.icon className={`h-4 w-4 ${stat.color}`} />
                <p className="text-xs text-muted-foreground">{stat.label}</p>
              </div>
              <p className="text-xl sm:text-2xl font-bold">{stat.value}</p>
            </div>
          ))}
        </div>

        {metrics.topReferrerIds && metrics.topReferrerIds.length > 0 && (
          <div className="mt-6 pt-6 border-t">
            <h4 className="text-xs sm:text-sm font-semibold mb-3">
              Top Referrers (by direct referrals)
            </h4>
            <div className="space-y-2">
              {metrics.topReferrerIds.slice(0, 5).map((referrerId, index) => (
                <div
                  key={referrerId}
                  className="flex items-center justify-between rounded-md border p-2 sm:p-3 bg-muted/30 text-xs sm:text-sm"
                >
                  <div className="flex items-center gap-2">
                    <span className="flex h-6 w-6 items-center justify-center rounded-full bg-primary/20 text-xs font-bold">
                      {index + 1}
                    </span>
                    <span className="font-mono text-xs text-muted-foreground">
                      {referrerId}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
