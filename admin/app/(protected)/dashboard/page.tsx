import {
  FolderKanban,
  Users,
  FileCheck,
  TrendingUp,
  ArrowUpRight,
  Activity,
  Clock,
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { PageHeader } from "@/components/page-header";

const stats = [
  {
    title: "Total Projects",
    value: "24",
    change: "+3 this week",
    icon: FolderKanban,
    trend: "up" as const,
  },
  {
    title: "Active Users",
    value: "1,248",
    change: "+12% from last month",
    icon: Users,
    trend: "up" as const,
  },
  {
    title: "Pending Applications",
    value: "7",
    change: "3 need urgent review",
    icon: FileCheck,
    trend: "neutral" as const,
  },
  {
    title: "Updates Published",
    value: "142",
    change: "+18 this week",
    icon: TrendingUp,
    trend: "up" as const,
  },
];

const recentActivity = [
  {
    id: 1,
    action: "New project created",
    resource: "Solana Pay Integration",
    actor: "admin@blocnet.io",
    time: "2 minutes ago",
    type: "project.create",
  },
  {
    id: 2,
    action: "Application approved",
    resource: "poster role for jake@example.com",
    actor: "owner@blocnet.io",
    time: "15 minutes ago",
    type: "admin_application.review",
  },
  {
    id: 3,
    action: "Update published",
    resource: "Ethereum Merge — Post-upgrade Analysis",
    actor: "poster@blocnet.io",
    time: "1 hour ago",
    type: "update.create",
  },
  {
    id: 4,
    action: "User promoted to admin",
    resource: "sarah@example.com",
    actor: "owner@blocnet.io",
    time: "3 hours ago",
    type: "role.promote",
  },
  {
    id: 5,
    action: "Project proposal submitted",
    resource: "Chainlink CCIP",
    actor: "poster@blocnet.io",
    time: "5 hours ago",
    type: "project_proposal.create",
  },
  {
    id: 6,
    action: "Comment deleted",
    resource: "on Bitcoin Lightning Update #34",
    actor: "admin@blocnet.io",
    time: "6 hours ago",
    type: "comment.delete",
  },
];

function getActionBadgeVariant(type: string) {
  if (type.includes("create") || type.includes("promote")) return "default";
  if (type.includes("review") || type.includes("approve")) return "secondary";
  if (type.includes("delete")) return "destructive";
  return "outline";
}

export default function DashboardPage() {
  return (
    <div className="space-y-6">
      <PageHeader
        title="Dashboard"
        description="Overview of your Blocnet admin operations."
      />

      {/* Stats grid */}
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {stats.map((stat) => (
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
                {stat.trend === "up" && (
                  <ArrowUpRight className="h-3 w-3 text-emerald-500" />
                )}
                {stat.change}
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Recent activity + Quick actions */}
      <div className="grid gap-4 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base">
              <Activity className="h-4 w-4" />
              Recent Activity
            </CardTitle>
            <CardDescription>
              Latest actions across the platform.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {recentActivity.map((event) => (
                <div
                  key={event.id}
                  className="flex items-start justify-between gap-4 border-b pb-4 last:border-0 last:pb-0"
                >
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <Badge
                        variant={getActionBadgeVariant(event.type)}
                        className="shrink-0 text-[10px]"
                      >
                        {event.type.split(".").join(" ")}
                      </Badge>
                    </div>
                    <p className="mt-1.5 text-sm font-medium">{event.action}</p>
                    <p className="text-xs text-muted-foreground">{event.resource}</p>
                  </div>
                  <div className="shrink-0 text-right">
                    <p className="text-xs text-muted-foreground">{event.actor}</p>
                    <p className="mt-0.5 flex items-center justify-end gap-1 text-[11px] text-muted-foreground">
                      <Clock className="h-3 w-3" />
                      {event.time}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        <div className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Platform Health</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">API Status</span>
                <Badge variant="outline" className="bg-emerald-500/10 text-emerald-500 border-emerald-500/20">
                  Operational
                </Badge>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Database</span>
                <Badge variant="outline" className="bg-emerald-500/10 text-emerald-500 border-emerald-500/20">
                  Connected
                </Badge>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Auth Provider</span>
                <Badge variant="outline" className="bg-emerald-500/10 text-emerald-500 border-emerald-500/20">
                  Supabase OK
                </Badge>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Push Notifications</span>
                <Badge variant="outline" className="bg-yellow-500/10 text-yellow-500 border-yellow-500/20">
                  Not Configured
                </Badge>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Quick Stats</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Total Comments</span>
                <span className="text-sm font-medium">3,847</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Active Posters</span>
                <span className="text-sm font-medium">18</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Project Proposals</span>
                <span className="text-sm font-medium">5 pending</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Tags</span>
                <span className="text-sm font-medium">32 total</span>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
