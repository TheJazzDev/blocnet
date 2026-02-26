"use client";

import { useEffect, useState } from "react";
import {
  LogOut,
  Server,
  Database,
  Shield,
  Bell,
  Globe,
  Key,
  Loader2,
  Save,
} from "lucide-react";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import { PageHeader } from "@/components/page-header";
import { useAdminSession } from "@/components/admin-shell";
import { canMutateSettings } from "@/lib/rbac";
import { clientApi, type RuntimeFeatureFlagsConfig } from "@/lib/api-client";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { LoadingSpinner } from "@/components/ui/loading-spinner";

export default function SettingsPage() {
  const session = useAdminSession();
  const canMutate = canMutateSettings(session.effectiveRoles);
  const [runtimeFlags, setRuntimeFlags] =
    useState<RuntimeFeatureFlagsConfig | null>(null);
  const [runtimeFlagsLoading, setRuntimeFlagsLoading] = useState(true);
  const [runtimeFlagsSaving, setRuntimeFlagsSaving] = useState(false);
  const [runtimeFlagsStatus, setRuntimeFlagsStatus] = useState<string | null>(
    null,
  );

  async function loadRuntimeFlags() {
    setRuntimeFlagsLoading(true);
    setRuntimeFlagsStatus(null);
    try {
      const config = await clientApi.getRuntimeFeatureFlags();
      setRuntimeFlags(config);
    } catch (error) {
      setRuntimeFlags(null);
      setRuntimeFlagsStatus(
        error instanceof Error
          ? error.message
          : "Failed to load runtime feature flags",
      );
    } finally {
      setRuntimeFlagsLoading(false);
    }
  }

  async function saveRuntimeFlags() {
    if (!runtimeFlags) return;
    setRuntimeFlagsSaving(true);
    setRuntimeFlagsStatus(null);
    try {
      const updated = await clientApi.updateRuntimeFeatureFlags({
        alphaRadarEnabled: runtimeFlags.alphaRadarEnabled,
        followPrefsEnabled: runtimeFlags.followPrefsEnabled,
        weeklyDigestEnabled: runtimeFlags.weeklyDigestEnabled,
        miningEnabled: runtimeFlags.miningEnabled,
        referralsEnabled: runtimeFlags.referralsEnabled,
      });
      setRuntimeFlags(updated);
      setRuntimeFlagsStatus("Runtime feature flags saved.");
    } catch (error) {
      setRuntimeFlagsStatus(
        error instanceof Error
          ? error.message
          : "Failed to save runtime feature flags",
      );
    } finally {
      setRuntimeFlagsSaving(false);
    }
  }

  useEffect(() => {
    void loadRuntimeFlags();
  }, []);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Settings"
        description="Admin panel configuration and environment diagnostics."
      >
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
            Settings mutations are restricted to owner/admin roles.
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0">
          <div>
            <CardTitle className="text-base">Runtime Feature Flags</CardTitle>
            <CardDescription>
              Live feature gating without redeploy.
            </CardDescription>
          </div>
          <Button
            size="sm"
            onClick={() => void saveRuntimeFlags()}
            disabled={
              !canMutate ||
              !runtimeFlags ||
              runtimeFlagsLoading ||
              runtimeFlagsSaving
            }
          >
            {runtimeFlagsSaving ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <Save className="h-4 w-4" />
            )}
            Save
          </Button>
        </CardHeader>
        <CardContent className="space-y-4">
          {runtimeFlagsLoading ? (
            <LoadingSpinner className="py-6" />
          ) : !runtimeFlags ? (
            <p className="text-sm text-muted-foreground">
              Runtime feature flags unavailable.
            </p>
          ) : (
            <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
              <div className="space-y-1.5">
                <Label>Alpha Radar</Label>
                <Select
                  value={runtimeFlags.alphaRadarEnabled ? "true" : "false"}
                  onValueChange={(value) =>
                    setRuntimeFlags((prev) =>
                      prev
                        ? { ...prev, alphaRadarEnabled: value === "true" }
                        : prev,
                    )
                  }
                  disabled={!canMutate || runtimeFlagsSaving}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="true">Enabled</SelectItem>
                    <SelectItem value="false">Disabled</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <Label>Follow Preferences</Label>
                <Select
                  value={runtimeFlags.followPrefsEnabled ? "true" : "false"}
                  onValueChange={(value) =>
                    setRuntimeFlags((prev) =>
                      prev
                        ? { ...prev, followPrefsEnabled: value === "true" }
                        : prev,
                    )
                  }
                  disabled={!canMutate || runtimeFlagsSaving}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="true">Enabled</SelectItem>
                    <SelectItem value="false">Disabled</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <Label>Weekly Digest</Label>
                <Select
                  value={runtimeFlags.weeklyDigestEnabled ? "true" : "false"}
                  onValueChange={(value) =>
                    setRuntimeFlags((prev) =>
                      prev
                        ? { ...prev, weeklyDigestEnabled: value === "true" }
                        : prev,
                    )
                  }
                  disabled={!canMutate || runtimeFlagsSaving}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="true">Enabled</SelectItem>
                    <SelectItem value="false">Disabled</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <Label>Mining</Label>
                <Select
                  value={runtimeFlags.miningEnabled ? "true" : "false"}
                  onValueChange={(value) =>
                    setRuntimeFlags((prev) =>
                      prev
                        ? { ...prev, miningEnabled: value === "true" }
                        : prev,
                    )
                  }
                  disabled={!canMutate || runtimeFlagsSaving}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="true">Enabled</SelectItem>
                    <SelectItem value="false">Disabled</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <Label>Referrals</Label>
                <Select
                  value={runtimeFlags.referralsEnabled ? "true" : "false"}
                  onValueChange={(value) =>
                    setRuntimeFlags((prev) =>
                      prev
                        ? { ...prev, referralsEnabled: value === "true" }
                        : prev,
                    )
                  }
                  disabled={!canMutate || runtimeFlagsSaving}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="true">Enabled</SelectItem>
                    <SelectItem value="false">Disabled</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
          )}

          {runtimeFlagsStatus ? (
            <p className="text-xs text-muted-foreground">
              {runtimeFlagsStatus}
            </p>
          ) : null}
        </CardContent>
      </Card>

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

        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="text-base">API Configuration</CardTitle>
            <CardDescription>
              Backend connection settings. Changes require restart.
            </CardDescription>
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
                <Input
                  id="supabase-url"
                  defaultValue=""
                  placeholder="https://xxxx.supabase.co"
                  disabled={!canMutate}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="supabase-key">Supabase Anon Key</Label>
                <Input
                  id="supabase-key"
                  type="password"
                  defaultValue=""
                  placeholder="eyJhbGciOi..."
                  disabled={!canMutate}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="admin-port">Admin Panel Port</Label>
                <Input
                  id="admin-port"
                  defaultValue="3081"
                  placeholder="3081"
                  disabled={!canMutate}
                />
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
