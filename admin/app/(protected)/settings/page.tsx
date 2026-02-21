"use client";

import { LogOut, Server, Database, Shield, Bell, Globe, Key } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import { PageHeader } from "@/components/page-header";
import { useAdminSession } from "@/components/admin-shell";
import { canMutateSettings } from "@/lib/rbac";

export default function SettingsPage() {
  const session = useAdminSession();
  const canMutate = canMutateSettings(session.effectiveRoles);

  return (
    <div className="space-y-6">
      <PageHeader title="Settings" description="Admin panel configuration and environment diagnostics.">
        <form action="/signout" method="post">
          <Button variant="destructive" type="submit">
            <LogOut className="h-4 w-4" />
            Sign Out
          </Button>
        </form>
      </PageHeader>

      {!canMutate && (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardContent className="pt-6 text-sm text-amber-200">
            Settings mutations are restricted to owner role.
          </CardContent>
        </Card>
      )}

      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base">
              <Server className="h-4 w-4" />
              Environment
            </CardTitle>
            <CardDescription>Current runtime configuration and connection status.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Globe className="h-4 w-4 text-muted-foreground" />
                <span className="text-sm">API Endpoint</span>
              </div>
              <code className="rounded bg-secondary px-2 py-0.5 text-xs">localhost:3080/api</code>
            </div>
            <Separator />
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Database className="h-4 w-4 text-muted-foreground" />
                <span className="text-sm">Database</span>
              </div>
              <Badge variant="outline" className="border-emerald-500/20 bg-emerald-500/10 text-emerald-500">
                Connected
              </Badge>
            </div>
            <Separator />
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Shield className="h-4 w-4 text-muted-foreground" />
                <span className="text-sm">Auth Provider</span>
              </div>
              <code className="rounded bg-secondary px-2 py-0.5 text-xs">Supabase</code>
            </div>
            <Separator />
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Key className="h-4 w-4 text-muted-foreground" />
                <span className="text-sm">Auth Mode</span>
              </div>
              <Badge variant="outline" className="border-yellow-500/20 bg-yellow-500/10 text-yellow-500">
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
            <CardDescription>Configure when and how notifications are sent to users.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium">Push Notifications</p>
                <p className="text-xs text-muted-foreground">Send push via FCM for new updates</p>
              </div>
              <Badge variant="outline" className="border-yellow-500/20 bg-yellow-500/10 text-yellow-500">
                Not Configured
              </Badge>
            </div>
            <Separator />
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium">High Urgency Alerts</p>
                <p className="text-xs text-muted-foreground">Immediate push for high-urgency updates</p>
              </div>
              <Badge variant="outline" className="border-emerald-500/20 bg-emerald-500/10 text-emerald-500">
                Enabled
              </Badge>
            </div>
            <Separator />
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium">Email Notifications</p>
                <p className="text-xs text-muted-foreground">Weekly digest emails for followers</p>
              </div>
              <Badge variant="outline" className="border-yellow-500/20 bg-yellow-500/10 text-yellow-500">
                Not Configured
              </Badge>
            </div>
          </CardContent>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="text-base">API Configuration</CardTitle>
            <CardDescription>Backend connection settings. Changes require restart.</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="api-url">Backend API URL</Label>
                <Input
                  id="api-url"
                  defaultValue="http://localhost:3080/api"
                  placeholder="https://api.blocnet.io/api"
                  disabled={!canMutate}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="supabase-url">Supabase URL</Label>
                <Input id="supabase-url" defaultValue="" placeholder="https://xxxx.supabase.co" disabled={!canMutate} />
              </div>
              <div className="space-y-2">
                <Label htmlFor="supabase-key">Supabase Anon Key</Label>
                <Input id="supabase-key" type="password" defaultValue="" placeholder="eyJhbGciOi..." disabled={!canMutate} />
              </div>
              <div className="space-y-2">
                <Label htmlFor="admin-port">Admin Panel Port</Label>
                <Input id="admin-port" defaultValue="3081" placeholder="3081" disabled={!canMutate} />
              </div>
            </div>
            <div className="mt-4 flex justify-end">
              <Button variant="secondary" disabled={!canMutate}>
                Save Configuration
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
