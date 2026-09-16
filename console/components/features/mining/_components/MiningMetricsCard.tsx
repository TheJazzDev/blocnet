"use client";

import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import type { AdminMiningMetrics } from "@/lib/api-client";
import { toMiningTotals, type MiningTotals } from "@/lib/api/mining-totals";

type MiningMetricsCardProps = {
  metrics: AdminMiningMetrics | null;
};

/** Which time window a metric covers, as computed by the backend. */
type MetricWindow = "Rolling 24h" | "Active window" | "All time" | "Lifetime";

type MetricRow = { title: string; value: string; window: MetricWindow };

function formatNumber(value: number) {
  return value.toLocaleString("en-US");
}

function formatPercent(ratio: number) {
  return `${(ratio * 100).toFixed(1)}%`;
}

function buildRows(metrics: AdminMiningMetrics, totals: MiningTotals): MetricRow[] {
  return [
    { title: "DAU Miners", value: formatNumber(metrics.dauMiners), window: "Rolling 24h" },
    { title: "Cycle Starts", value: formatNumber(metrics.startsDay), window: "Rolling 24h" },
    { title: "Claims", value: formatNumber(metrics.claimsDay), window: "Rolling 24h" },
    {
      title: "Avg Boost",
      value: `${formatNumber(metrics.averageBoostBps)} bps`,
      window: "Rolling 24h",
    },
    {
      title: "Referral Bind Rate",
      value: formatPercent(metrics.referralBindRate),
      window: "All time",
    },
    {
      title: "Active Referral Ratio",
      value: formatPercent(metrics.activeReferralRatio),
      window: "Active window",
    },
    {
      title: "Total Direct Referrals",
      value: formatNumber(metrics.totalDirectReferrals),
      window: "All time",
    },
    {
      title: "Active Direct Referrals",
      value: formatNumber(metrics.activeDirectReferrals),
      window: "Active window",
    },
    { title: "Lifetime Mined (BNP)", value: formatNumber(totals.lifetimeMinedBnp), window: "Lifetime" },
    { title: "Lifetime Claimed (BNP)", value: formatNumber(totals.lifetimeClaimedBnp), window: "Lifetime" },
    {
      title: "Lifetime Unclaimed (BNP)",
      value: formatNumber(totals.lifetimeUnclaimedBnp),
      window: "Lifetime",
    },
    { title: "Total Miners", value: formatNumber(totals.totalMiners), window: "Lifetime" },
  ];
}

const WINDOW_STYLES: Record<MetricWindow, string> = {
  "Rolling 24h": "text-sky-300",
  "Active window": "text-amber-300",
  "All time": "text-muted-foreground",
  Lifetime: "text-muted-foreground",
};

export function MiningMetricsCard({ metrics }: MiningMetricsCardProps) {
  const totals = toMiningTotals(metrics);

  return (
    <Card>
      <CardHeader className="p-4 sm:p-6">
        <CardTitle className="text-sm sm:text-base">Mining Metrics</CardTitle>
        <p className="text-xs text-muted-foreground sm:text-sm">
          Each tile shows its window. &ldquo;Active window&rdquo; is the configured active-referral
          window.
        </p>
      </CardHeader>
      <CardContent className="p-4 pt-0 sm:p-6 sm:pt-0">
        {!metrics || !totals ? (
          <p className="text-sm text-muted-foreground">No metrics available.</p>
        ) : (
          <div className="grid grid-cols-1 gap-2 sm:grid-cols-2 sm:gap-3 lg:grid-cols-4">
            {buildRows(metrics, totals).map((row) => (
              <Metric key={row.title} {...row} />
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function Metric({ title, value, window }: MetricRow) {
  return (
    <div className="rounded-lg border p-3">
      <p className="text-xs text-muted-foreground">{title}</p>
      <p className="mt-1 text-base font-semibold sm:text-lg">{value}</p>
      <Badge variant="outline" className={`mt-2 text-[10px] ${WINDOW_STYLES[window]}`}>
        {window}
      </Badge>
    </div>
  );
}
