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
      label: "Total Miners",
      value: metrics.totalMiners.toLocaleString(),
      icon: Users,
      color: "text-blue-400",
    },
    {
      label: "Total Referrals",
      value: metrics.totalDirectReferrals.toLocaleString(),
      icon: UserPlus,
      color: "text-emerald-400",
    },
    {
      label: "Active Referrals",
      value: metrics.activeDirectReferrals.toLocaleString(),
      icon: Award,
      color: "text-amber-400",
    },
    {
      label: "Referral Bind Rate",
      value: `${(metrics.referralBindRate * 100).toFixed(1)}%`,
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
      </CardContent>
    </Card>
  );
}
