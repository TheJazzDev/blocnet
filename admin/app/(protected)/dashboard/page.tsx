"use client";

import { useEffect, useState } from "react";
import {
  FolderKanban,
  Users,
  FileCheck,
  TrendingUp,
  ArrowUpRight,
  Activity,
  Clock,
  Bell,
} from "lucide-react";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { PageHeader } from "@/components/page-header";
import { clientApi, type AdminStats, type AuditLog } from "@/lib/api-client";
import { DashboardHealthCard } from "./dashboard-health-card";

function formatRelativeTime(dateStr: string) {
  const diff = Date.now() - new Date(dateStr).getTime();
  const minutes = Math.floor(diff / 60_000);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  return `${Math.floor(hours / 24)}d ago`;
}

function getActionBadgeVariant(action: string) {
  if (action.includes("create") || action.includes("promote")) return "default";
  if (action.includes("review") || action.includes("approve")) return "secondary";
  if (action.includes("delete") || action.includes("archive")) return "destructive";
  return "outline" as const;
}

function StatCardSkeleton() {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <Skeleton className="h-4 w-28" />
        <Skeleton className="h-4 w-4" />
      </CardHeader>
      <CardContent>
        <Skeleton className="h-8 w-16" />
        <Skeleton className="mt-2 h-3 w-32" />
      </CardContent>
    </Card>
  );
}

function ActivitySkeleton() {
  return (
    <div className="space-y-4">
      {Array.from({ length: 5 }).map((_, i) => (
        <div key={i} className="flex items-start justify-between gap-4 border-b pb-4 last:border-0 last:pb-0">
          <div className="flex-1 space-y-2">
            <Skeleton className="h-4 w-24" />
            <Skeleton className="h-4 w-40" />
            <Skeleton className="h-3 w-32" />
          </div>
          <div className="space-y-2 text-right">
            <Skeleton className="ml-auto h-3 w-28" />
            <Skeleton className="ml-auto h-3 w-16" />
          </div>
        </div>
      ))}
    </div>
  );
}

export default function DashboardPage() {
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      clientApi.getStats().catch(() => null),
      clientApi.listAuditLog(10).catch(() => [] as AuditLog[]),
    ]).then(([s, l]) => {
      setStats(s);
      setLogs(l);
      setLoading(false);
    });
  }, []);

  const statCards = stats
    ? [
        {
          title: "Total Projects",
          value: stats.totalProjects.toLocaleString(),
          change: `${stats.totalUpdates} updates total`,
          icon: FolderKanban,
        },
        {
          title: "Total Users",
          value: stats.totalUsers.toLocaleString(),
          change: `${stats.activeHunters} active hunters`,
          icon: Users,
        },
        {
          title: "Pending Applications",
          value: (stats.pendingAdminApps + stats.pendingProposals).toString(),
          change: `${stats.pendingAdminApps} role · ${stats.pendingProposals} proposals`,
          icon: FileCheck,
        },
        {
          title: "Updates Published",
          value: stats.totalUpdates.toLocaleString(),
          change: `${stats.totalComments} comments`,
          icon: TrendingUp,
        },
      ]
    : [];

  return (
    <div className="space-y-6">
      <PageHeader
        title="Dashboard"
        description="Overview of your Blocnet admin operations."
      />

      {/* Stats grid */}
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {loading
          ? Array.from({ length: 4 }).map((_, i) => <StatCardSkeleton key={i} />)
          : statCards.map((stat) => (
              <Card key={stat.title}>
                <CardHeader className="flex flex-row items-center justify-between pb-2">
                  <CardTitle className="text-sm font-medium text-muted-foreground">
                    {stat.title}
                  </CardTitle>
                  <stat.icon className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{stat.value}</div>
                  <div className="mt-1 flex items-center gap-1 text-xs text-muted-foreground">
                    <ArrowUpRight className="h-3 w-3 text-emerald-500" />
                    {stat.change}
                  </div>
                </CardContent>
              </Card>
            ))}
      </div>

      {/* Recent activity + Platform health */}
      <div className="grid gap-4 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base">
              <Activity className="h-4 w-4" />
              Recent Activity
            </CardTitle>
            <CardDescription>Latest actions across the platform.</CardDescription>
          </CardHeader>
          <CardContent>
            {loading ? (
              <ActivitySkeleton />
            ) : logs.length === 0 ? (
              <p className="text-sm text-muted-foreground">No audit events found.</p>
            ) : (
              <div className="space-y-4">
                {logs.map((event) => (
                  <div
                    key={event.id}
                    className="flex items-start justify-between gap-4 border-b pb-4 last:border-0 last:pb-0"
                  >
                    <div className="min-w-0 flex-1">
                      <Badge
                        variant={getActionBadgeVariant(event.action)}
                        className="shrink-0 text-[10px]"
                      >
                        {event.action.replace(".", " ")}
                      </Badge>
                      <p className="mt-1.5 text-sm font-medium">{event.action}</p>
                      <p className="text-xs text-muted-foreground">
                        {event.resourceType} · {event.resourceId ?? "—"}
                      </p>
                    </div>
                    <div className="shrink-0 text-right">
                      <p className="text-xs text-muted-foreground">
                        {event.actor?.email ?? "System"}
                      </p>
                      <p className="mt-0.5 flex items-center justify-end gap-1 text-[11px] text-muted-foreground">
                        <Clock className="h-3 w-3" />
                        {formatRelativeTime(event.createdAt)}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        <div className="space-y-4">
          <DashboardHealthCard />
          {(loading || stats) && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Quick Stats</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                {loading ? (
                  Array.from({ length: 5 }).map((_, i) => (
                    <div key={i} className="flex items-center justify-between">
                      <Skeleton className="h-4 w-28" />
                      <Skeleton className="h-4 w-10" />
                    </div>
                  ))
                ) : stats ? (
                  <>
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-muted-foreground">Total Comments</span>
                      <span className="text-sm font-medium">{stats.totalComments.toLocaleString()}</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-muted-foreground">Active Hunters</span>
                      <span className="text-sm font-medium">{stats.activeHunters}</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-muted-foreground">Project Proposals</span>
                      <span className="text-sm font-medium">{stats.pendingProposals} pending</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-muted-foreground">Primary Tags</span>
                      <span className="text-sm font-medium">{stats.totalTags} total</span>
                    </div>
                    <div className="flex items-center justify-between border-t pt-3">
                      <span className="flex items-center gap-1.5 text-sm text-muted-foreground">
                        <Bell className="h-3.5 w-3.5" />
                        Push Enabled
                      </span>
                      <span className="text-sm font-medium">{stats.usersWithPushEnabled} users</span>
                    </div>
                  </>
                ) : null}
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}
