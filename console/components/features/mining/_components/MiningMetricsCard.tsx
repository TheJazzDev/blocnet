"use client";

import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import type { AdminMiningMetrics } from "@/lib/api-client";

type MiningMetricsCardProps = {
  metrics: AdminMiningMetrics | null;
};

export function MiningMetricsCard({ metrics }: MiningMetricsCardProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Mining Metrics (24h)</CardTitle>
      </CardHeader>
      <CardContent>
        {!metrics ? (
          <p className="text-sm text-muted-foreground">No metrics available.</p>
        ) : (
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            <Metric title="DAU Miners" value={formatNumber(metrics.dauMiners)} />
            <Metric title="Cycle Starts" value={formatNumber(metrics.startsDay)} />
            <Metric title="Claims" value={formatNumber(metrics.claimsDay)} />
            <Metric title="Avg Boost" value={`${formatNumber(metrics.averageBoostBps)} bps`} />
            <Metric
              title="Referral Bind Rate"
              value={`${(metrics.referralBindRate * 100).toFixed(1)}%`}
            />
            <Metric
              title="Active Referral Ratio"
              value={`${(metrics.activeReferralRatio * 100).toFixed(1)}%`}
            />
            <Metric
              title="Total Direct Referrals"
              value={formatNumber(metrics.totalDirectReferrals)}
            />
            <Metric
              title="Active Direct Referrals"
              value={formatNumber(metrics.activeDirectReferrals)}
            />
            <Metric title="Lifetime Mined (BNP)" value={formatNumber(metrics.lifetimeMinedMcr)} />
            <Metric
              title="Lifetime Claimed (BNP)"
              value={formatNumber(metrics.lifetimeClaimedMcr)}
            />
            <Metric title="Unclaimed (BNP)" value={formatNumber(metrics.lifetimeUnclaimedMcr)} />
            <Metric title="Total Miners" value={formatNumber(metrics.totalMiners)} />
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function Metric({ title, value }: { title: string; value: string }) {
  return (
    <div className="rounded-lg border p-3">
      <p className="text-xs text-muted-foreground">{title}</p>
      <p className="mt-1 text-lg font-semibold">{value}</p>
      <Badge variant="outline" className="mt-2 text-[10px]">
        Rolling 24h
      </Badge>
    </div>
  );
}

function formatNumber(value: number) {
  return value.toLocaleString("en-US");
}
