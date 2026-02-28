"use client";

import { useEffect, useState } from "react";
import {
  LogOut,
  Server,
  Database,
  Shield,
  ShieldCheck,
  Smartphone,
  Bell,
  Globe,
  Key,
  Loader2,
  Save,
} from "lucide-react";
import axios from "axios";
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
import {
  clientApi,
  type AdminTwoFactorEnrollmentStartResponse,
  type AdminTwoFactorPolicy,
  type AdminTwoFactorPreflight,
  type RuntimeFeatureFlagsConfig,
} from "@/lib/api-client";
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
  const [twoFactorLoading, setTwoFactorLoading] = useState(true);
  const [twoFactorSaving, setTwoFactorSaving] = useState(false);
  const [twoFactorStatus, setTwoFactorStatus] = useState<string | null>(null);
  const [twoFactorPreflight, setTwoFactorPreflight] =
    useState<AdminTwoFactorPreflight | null>(null);
  const [twoFactorPolicy, setTwoFactorPolicy] =
    useState<AdminTwoFactorPolicy | null>(null);
  const [policyDraft, setPolicyDraft] = useState<"true" | "false">("false");
  const [enrollment, setEnrollment] =
    useState<AdminTwoFactorEnrollmentStartResponse | null>(null);
  const [confirmCode, setConfirmCode] = useState("");
  const [actionCode, setActionCode] = useState("");
  const [actionRecoveryCode, setActionRecoveryCode] = useState("");
  const [generatedRecoveryCodes, setGeneratedRecoveryCodes] = useState<
    string[]
  >([]);
  const isOwner = session.realRoles.includes("owner");

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

  async function loadTwoFactorState() {
    setTwoFactorLoading(true);
    setTwoFactorStatus(null);

    try {
      const [preflight, policy] = await Promise.all([
        clientApi.getAdminTwoFactorPreflight(),
        clientApi.getAdminTwoFactorPolicy(),
      ]);
      setTwoFactorPreflight(preflight);
      setTwoFactorPolicy(policy);
      setPolicyDraft(policy.require2faForAdminPanel ? "true" : "false");
    } catch (error) {
      setTwoFactorPreflight(null);
      setTwoFactorPolicy(null);
      setTwoFactorStatus(
        error instanceof Error
          ? error.message
          : "Failed to load admin 2FA state",
      );
    } finally {
      setTwoFactorLoading(false);
    }
  }

  async function startEnrollment() {
    setTwoFactorSaving(true);
    setTwoFactorStatus(null);
    try {
      const payload = await clientApi.startAdminTwoFactorEnrollment();
      setEnrollment(payload);
      setGeneratedRecoveryCodes([]);
      setConfirmCode("");
      setTwoFactorStatus("Enrollment challenge started. Confirm to enable 2FA.");
    } catch (error) {
      setTwoFactorStatus(
        error instanceof Error ? error.message : "Failed to start enrollment",
      );
    } finally {
      setTwoFactorSaving(false);
    }
  }

  async function confirmEnrollment() {
    if (!confirmCode.trim()) {
      setTwoFactorStatus("Enter your 6-digit authenticator code.");
      return;
    }

    setTwoFactorSaving(true);
    setTwoFactorStatus(null);
    try {
      const payload = await clientApi.confirmAdminTwoFactorEnrollment({
        code: confirmCode.trim(),
      });
      await axios.post("/api/auth/2fa/session", {
        sessionToken: payload.sessionToken,
        expiresAt: payload.sessionExpiresAt,
      });
      setGeneratedRecoveryCodes(payload.recoveryCodes);
      setEnrollment(null);
      setConfirmCode("");
      setActionCode("");
      setActionRecoveryCode("");
      setTwoFactorStatus(
        "Two-factor authentication enabled. Save your recovery codes now.",
      );
      await loadTwoFactorState();
    } catch (error) {
      setTwoFactorStatus(
        error instanceof Error
          ? error.message
          : "Failed to confirm enrollment",
      );
    } finally {
      setTwoFactorSaving(false);
    }
  }

  async function savePolicy() {
    if (!isOwner) {
      setTwoFactorStatus("Only owner can update 2FA policy.");
      return;
    }

    setTwoFactorSaving(true);
    setTwoFactorStatus(null);
    try {
      const updated = await clientApi.updateAdminTwoFactorPolicy({
        require2faForAdminPanel: policyDraft === "true",
      });
      setTwoFactorPolicy(updated);
      setTwoFactorStatus("Admin panel 2FA policy updated.");
      await loadTwoFactorState();
    } catch (error) {
      setTwoFactorStatus(
        error instanceof Error ? error.message : "Failed to update policy",
      );
    } finally {
      setTwoFactorSaving(false);
    }
  }

  async function regenerateRecoveryCodes() {
    setTwoFactorSaving(true);
    setTwoFactorStatus(null);
    try {
      const payload = await clientApi.regenerateAdminTwoFactorRecoveryCodes({
        code: actionCode.trim() || undefined,
        recoveryCode: actionRecoveryCode.trim() || undefined,
      });
      setGeneratedRecoveryCodes(payload.recoveryCodes);
      setActionCode("");
      setActionRecoveryCode("");
      setTwoFactorStatus("Recovery codes rotated.");
      await loadTwoFactorState();
    } catch (error) {
      setTwoFactorStatus(
        error instanceof Error
          ? error.message
          : "Failed to regenerate recovery codes",
      );
    } finally {
      setTwoFactorSaving(false);
    }
  }

  async function disableTwoFactor() {
    setTwoFactorSaving(true);
    setTwoFactorStatus(null);
    try {
      await clientApi.disableAdminTwoFactor({
        code: actionCode.trim() || undefined,
        recoveryCode: actionRecoveryCode.trim() || undefined,
      });
      await axios.post("/api/auth/2fa/clear");
      setGeneratedRecoveryCodes([]);
      setEnrollment(null);
      setActionCode("");
      setActionRecoveryCode("");
      setTwoFactorStatus("Two-factor authentication disabled.");
      await loadTwoFactorState();
    } catch (error) {
      setTwoFactorStatus(
        error instanceof Error ? error.message : "Failed to disable 2FA",
      );
    } finally {
      setTwoFactorSaving(false);
    }
  }

  useEffect(() => {
    void loadRuntimeFlags();
    void loadTwoFactorState();
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

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0">
          <div>
            <CardTitle className="flex items-center gap-2 text-base">
              <ShieldCheck className="h-4 w-4" />
              Admin Panel 2FA
            </CardTitle>
            <CardDescription>
              Google Authenticator TOTP, recovery codes, and owner-enforced policy.
            </CardDescription>
          </div>
          <Button
            variant="outline"
            size="sm"
            onClick={() => void loadTwoFactorState()}
            disabled={twoFactorLoading || twoFactorSaving}
          >
            {twoFactorLoading ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              "Refresh"
            )}
          </Button>
        </CardHeader>
        <CardContent className="space-y-4">
          {twoFactorLoading ? (
            <LoadingSpinner className="py-6" />
          ) : !twoFactorPreflight || !twoFactorPolicy ? (
            <p className="text-sm text-muted-foreground">
              Admin 2FA state unavailable.
            </p>
          ) : (
            <>
              <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
                <div className="rounded-md border border-border/70 p-3">
                  <p className="text-xs text-muted-foreground">Account 2FA</p>
                  <p className="mt-1 text-sm font-medium">
                    {twoFactorPreflight.totpEnabled ? "Enabled" : "Disabled"}
                  </p>
                </div>
                <div className="rounded-md border border-border/70 p-3">
                  <p className="text-xs text-muted-foreground">Recovery Codes Left</p>
                  <p className="mt-1 text-sm font-medium">
                    {twoFactorPreflight.recoveryCodesRemaining}
                  </p>
                </div>
                <div className="rounded-md border border-border/70 p-3">
                  <p className="text-xs text-muted-foreground">Policy Enforcement</p>
                  <p className="mt-1 text-sm font-medium">
                    {twoFactorPolicy.require2faForAdminPanel
                      ? "Required"
                      : "Optional"}
                  </p>
                </div>
                <div className="rounded-md border border-border/70 p-3">
                  <p className="text-xs text-muted-foreground">Eligible / Enabled</p>
                  <p className="mt-1 text-sm font-medium">
                    {twoFactorPolicy.summary.enabledUsers}/
                    {twoFactorPolicy.summary.eligibleUsers}
                  </p>
                </div>
              </div>

              <div className="grid gap-4 xl:grid-cols-2">
                <div className="space-y-3 rounded-md border border-border/70 p-3">
                  <p className="text-sm font-medium">Owner Policy</p>
                  <div className="space-y-1.5">
                    <Label>Require 2FA for Owner/Admin/Moderator panel access</Label>
                    <Select
                      value={policyDraft}
                      onValueChange={(value) =>
                        setPolicyDraft(value === "true" ? "true" : "false")
                      }
                      disabled={!isOwner || twoFactorSaving}
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="false">Optional</SelectItem>
                        <SelectItem value="true">Required</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <Button
                    size="sm"
                    onClick={() => void savePolicy()}
                    disabled={!isOwner || twoFactorSaving}
                  >
                    {twoFactorSaving ? (
                      <Loader2 className="h-4 w-4 animate-spin" />
                    ) : (
                      <Save className="h-4 w-4" />
                    )}
                    Save 2FA Policy
                  </Button>
                </div>

                <div className="space-y-3 rounded-md border border-border/70 p-3">
                  <p className="text-sm font-medium">Authenticator Enrollment</p>
                  {!twoFactorPreflight.totpEnabled && !enrollment && (
                    <Button
                      size="sm"
                      onClick={() => void startEnrollment()}
                      disabled={twoFactorSaving}
                    >
                      {twoFactorSaving ? (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      ) : (
                        <Smartphone className="h-4 w-4" />
                      )}
                      Start Enrollment
                    </Button>
                  )}

                  {enrollment && (
                    <div className="space-y-3">
                      <div className="space-y-1">
                        <Label>Secret Key</Label>
                        <Input value={enrollment.secret} readOnly />
                      </div>
                      <div className="space-y-1">
                        <Label>OTPAuth URI</Label>
                        <Input value={enrollment.otpAuthUrl} readOnly />
                      </div>
                      <div className="space-y-1">
                        <Label>Confirm Authenticator Code</Label>
                        <Input
                          value={confirmCode}
                          onChange={(event) => setConfirmCode(event.target.value)}
                          placeholder="123456"
                          disabled={twoFactorSaving}
                        />
                      </div>
                      <Button
                        size="sm"
                        onClick={() => void confirmEnrollment()}
                        disabled={twoFactorSaving}
                      >
                        {twoFactorSaving ? (
                          <Loader2 className="h-4 w-4 animate-spin" />
                        ) : (
                          <ShieldCheck className="h-4 w-4" />
                        )}
                        Confirm Enrollment
                      </Button>
                    </div>
                  )}
                </div>
              </div>

              {twoFactorPreflight.totpEnabled && (
                <div className="grid gap-3 rounded-md border border-border/70 p-3 xl:grid-cols-[1fr_auto_auto]">
                  <div className="space-y-2">
                    <p className="text-sm font-medium">2FA Actions</p>
                    <div className="grid gap-2 sm:grid-cols-2">
                      <Input
                        placeholder="Authenticator code (123456)"
                        value={actionCode}
                        onChange={(event) => setActionCode(event.target.value)}
                        disabled={twoFactorSaving}
                      />
                      <Input
                        placeholder="or recovery code"
                        value={actionRecoveryCode}
                        onChange={(event) =>
                          setActionRecoveryCode(event.target.value)
                        }
                        disabled={twoFactorSaving}
                      />
                    </div>
                  </div>
                  <Button
                    variant="outline"
                    onClick={() => void regenerateRecoveryCodes()}
                    disabled={twoFactorSaving}
                  >
                    {twoFactorSaving ? (
                      <Loader2 className="h-4 w-4 animate-spin" />
                    ) : (
                      "Regenerate Codes"
                    )}
                  </Button>
                  <Button
                    variant="destructive"
                    onClick={() => void disableTwoFactor()}
                    disabled={twoFactorSaving}
                  >
                    {twoFactorSaving ? (
                      <Loader2 className="h-4 w-4 animate-spin" />
                    ) : (
                      "Disable 2FA"
                    )}
                  </Button>
                </div>
              )}
            </>
          )}

          {twoFactorStatus ? (
            <p className="text-xs text-muted-foreground">{twoFactorStatus}</p>
          ) : null}
        </CardContent>
      </Card>

      {generatedRecoveryCodes.length > 0 && (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardHeader>
            <CardTitle className="text-base">Recovery Codes (Save Now)</CardTitle>
            <CardDescription>
              Each code can be used once. Store them in a secure location.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
              {generatedRecoveryCodes.map((code) => (
                <code
                  key={code}
                  className="rounded-md border border-border/70 bg-background/80 px-2 py-1 text-xs"
                >
                  {code}
                </code>
              ))}
            </div>
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
    </div>
  );
}
