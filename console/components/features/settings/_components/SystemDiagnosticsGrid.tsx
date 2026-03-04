"use client";

import { Bell, Database, Globe, Key, Server, Shield } from "lucide-react";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";

export function SystemDiagnosticsGrid() {
  return (
    <div className="grid gap-6 lg:grid-cols-2">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-base">
            <Server className="h-4 w-4" />
            Environment
          </CardTitle>
          <CardDescription>
            Current runtime configuration and connection status.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Globe className="h-4 w-4 text-muted-foreground" />
              <span className="text-sm">API Endpoint</span>
            </div>
            <code className="rounded bg-secondary px-2 py-0.5 text-xs">
              localhost:3080/api
            </code>
          </div>
          <Separator />
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Database className="h-4 w-4 text-muted-foreground" />
              <span className="text-sm">Database</span>
            </div>
            <Badge
              variant="outline"
              className="border-emerald-500/20 bg-emerald-500/10 text-emerald-500"
            >
              Connected
            </Badge>
          </div>
          <Separator />
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Shield className="h-4 w-4 text-muted-foreground" />
              <span className="text-sm">Auth Provider</span>
            </div>
            <code className="rounded bg-secondary px-2 py-0.5 text-xs">
              Supabase
            </code>
          </div>
          <Separator />
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Key className="h-4 w-4 text-muted-foreground" />
              <span className="text-sm">Auth Mode</span>
            </div>
            <Badge
              variant="outline"
              className="border-yellow-500/20 bg-yellow-500/10 text-yellow-500"
            >
              Shell (Mock)
            </Badge>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-base">
            <Bell className="h-4 w-4" />
            Notification Policies
          </CardTitle>
          <CardDescription>
            Configure when and how notifications are sent to users.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium">Push Notifications</p>
              <p className="text-xs text-muted-foreground">
                Send push via FCM for new updates
              </p>
            </div>
            <Badge
              variant="outline"
              className="border-yellow-500/20 bg-yellow-500/10 text-yellow-500"
            >
              Not Configured
            </Badge>
          </div>
          <Separator />
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium">High Urgency Alerts</p>
              <p className="text-xs text-muted-foreground">
                Immediate push for high-urgency updates
              </p>
            </div>
            <Badge
              variant="outline"
              className="border-emerald-500/20 bg-emerald-500/10 text-emerald-500"
            >
              Enabled
            </Badge>
          </div>
          <Separator />
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium">Email Notifications</p>
              <p className="text-xs text-muted-foreground">
                Weekly digest emails for followers
              </p>
            </div>
            <Badge
              variant="outline"
              className="border-yellow-500/20 bg-yellow-500/10 text-yellow-500"
            >
              Not Configured
            </Badge>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
