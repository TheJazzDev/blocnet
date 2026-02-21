"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Save, RefreshCw, Loader2, Trophy } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import {
  clientApi,
  type AdminMiningConfig,
  type AdminMiningMetrics,
} from "@/lib/api-client";
import { useAdminSession } from "@/components/admin-shell";
import { canMutateWallet } from "@/lib/rbac";

export default function MiningPage() {
  const session = useAdminSession();
  const canMutate = canMutateWallet(session.effectiveRoles);

  const [config, setConfig] = useState<AdminMiningConfig | null>(null);
  const [metrics, setMetrics] = useState<AdminMiningMetrics | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [supportUserIdOrEmail, setSupportUserIdOrEmail] = useState("");
  const [supportReferralCode, setSupportReferralCode] = useState("");
  const [supportSaving, setSupportSaving] = useState(false);
  const [supportError, setSupportError] = useState<string | null>(null);
  const [supportSuccess, setSupportSuccess] = useState<string | null>(null);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const [cfg, m] = await Promise.all([
        clientApi.getMiningConfig(),
        clientApi.getMiningMetrics(),
      ]);
      setConfig(cfg);
      setMetrics(m);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Failed to load mining settings");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
  }, []);

  async function save() {
    if (!config) return;
    setSaving(true);
    setError(null);
    try {
      const next = await clientApi.updateMiningConfig(config);
      setConfig(next);
      const refreshedMetrics = await clientApi.getMiningMetrics();
      setMetrics(refreshedMetrics);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Failed to save mining settings");
    } finally {
      setSaving(false);
    }
  }

  async function bindReferralBySupport() {
    if (!supportUserIdOrEmail.trim()) {
      setSupportError("Enter a user ID or email.");
      setSupportSuccess(null);
      return;
    }

    if (!supportReferralCode.trim()) {
      setSupportError("Enter a referral code.");
      setSupportSuccess(null);
      return;
    }

    setSupportSaving(true);
    setSupportError(null);
    setSupportSuccess(null);
    try {
      const result = await clientApi.adminBindReferral({
        userIdOrEmail: supportUserIdOrEmail.trim(),
        code: supportReferralCode.trim().toUpperCase(),
      });
      setSupportSuccess(
        `Bound ${result.targetUser.email} to ${result.referrer.code ?? "UNKNOWN"} (${result.referrer.email}).`,
      );
      setSupportUserIdOrEmail("");
      setSupportReferralCode("");
      const refreshedMetrics = await clientApi.getMiningMetrics();
      setMetrics(refreshedMetrics);
    } catch (e: unknown) {
      setSupportError(
        e instanceof Error ? e.message : "Failed to bind referral for user",
      );
    } finally {
      setSupportSaving(false);
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Mining"
        description="Tune cycle economics and review referral engagement metrics."
      >
        <Button variant="outline" asChild>
          <Link href="/mining/leaderboard">
            <Trophy className="h-4 w-4" />
            Open Leaderboard
          </Link>
        </Button>
        <Button variant="outline" onClick={() => void load()} disabled={loading || saving}>
          {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
          Refresh
        </Button>
      </PageHeader>

      {!canMutate && (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardContent className="pt-6 text-sm text-amber-200">
            Read-only mode. Owner/Admin roles are required to update mining config.
          </CardContent>
        </Card>
      )}

      {error && (
        <Card>
          <CardContent className="pt-6 text-sm text-destructive">{error}</CardContent>
        </Card>
      )}

      {loading ? (
        <Card>
          <CardContent className="pt-6">
            <LoadingSpinner className="py-10" />
          </CardContent>
        </Card>
      ) : (
        <>
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Mining Configuration</CardTitle>
            </CardHeader>
            <CardContent className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="enabled">Mining Enabled</Label>
                <select
                  id="enabled"
                  className="h-10 w-full rounded-md border bg-background px-3 text-sm"
                  value={config?.enabled ? "true" : "false"}
                  onChange={(e) =>
                    setConfig((prev) =>
                      prev ? { ...prev, enabled: e.target.value === "true" } : prev,
                    )
                  }
                  disabled={!canMutate || !config}
                >
                  <option value="true">Enabled</option>
                  <option value="false">Disabled</option>
                </select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="referralsEnabled">Referrals Enabled</Label>
                <select
                  id="referralsEnabled"
                  className="h-10 w-full rounded-md border bg-background px-3 text-sm"
                  value={config?.referralsEnabled ? "true" : "false"}
                  onChange={(e) =>
                    setConfig((prev) =>
                      prev ? { ...prev, referralsEnabled: e.target.value === "true" } : prev,
                    )
                  }
                  disabled={!canMutate || !config}
                >
                  <option value="true">Enabled</option>
                  <option value="false">Disabled</option>
                </select>
              </div>

              <ConfigInput
                id="cycleHours"
                label="Cycle Hours"
                value={config?.cycleHours}
                disabled={!canMutate || !config}
                onChange={(value) =>
                  setConfig((prev) => (prev ? { ...prev, cycleHours: value } : prev))
                }
              />

              <ConfigInput
                id="basePointsPerCycle"
                label="Base Points / Cycle"
                value={config?.basePointsPerCycle}
                disabled={!canMutate || !config}
                onChange={(value) =>
                  setConfig((prev) =>
                    prev ? { ...prev, basePointsPerCycle: value } : prev,
                  )
                }
              />

              <ConfigInput
                id="perActiveReferralBoostBps"
                label="Boost per Active Referral (bps)"
                value={config?.perActiveReferralBoostBps}
                disabled={!canMutate || !config}
                onChange={(value) =>
                  setConfig((prev) =>
                    prev ? { ...prev, perActiveReferralBoostBps: value } : prev,
                  )
                }
              />

              <ConfigInput
                id="maxBoostBps"
                label="Max Boost (bps)"
                value={config?.maxBoostBps}
                disabled={!canMutate || !config}
                onChange={(value) =>
                  setConfig((prev) => (prev ? { ...prev, maxBoostBps: value } : prev))
                }
              />

              <ConfigInput
                id="activeReferralWindowHours"
                label="Active Referral Window (hours)"
                value={config?.activeReferralWindowHours}
                disabled={!canMutate || !config}
                onChange={(value) =>
                  setConfig((prev) =>
                    prev ? { ...prev, activeReferralWindowHours: value } : prev,
                  )
                }
              />

              <ConfigInput
                id="referralBindWindowHours"
                label="Referral Bind Window (hours)"
                value={config?.referralBindWindowHours}
                disabled={!canMutate || !config}
                onChange={(value) =>
                  setConfig((prev) =>
                    prev ? { ...prev, referralBindWindowHours: value } : prev,
                  )
                }
              />

              <div className="md:col-span-2 flex justify-end">
                <Button onClick={() => void save()} disabled={!canMutate || !config || saving}>
                  {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                  Save Mining Config
                </Button>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Mining Metrics (24h)</CardTitle>
            </CardHeader>
            <CardContent>
              {!metrics ? (
                <p className="text-sm text-muted-foreground">No metrics available.</p>
              ) : (
                <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
                  <Metric title="DAU Miners" value={metrics.dauMiners.toString()} />
                  <Metric title="Cycle Starts" value={metrics.startsDay.toString()} />
                  <Metric title="Claims" value={metrics.claimsDay.toString()} />
                  <Metric title="Avg Boost" value={`${metrics.averageBoostBps} bps`} />
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
                    value={metrics.totalDirectReferrals.toString()}
                  />
                  <Metric
                    title="Active Direct Referrals"
                    value={metrics.activeDirectReferrals.toString()}
                  />
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Referral Support</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-sm text-muted-foreground">
                Use this when a user signed up without entering a referral code.
              </p>
              <div className="grid gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="supportUserIdOrEmail">User ID or Email</Label>
                  <Input
                    id="supportUserIdOrEmail"
                    placeholder="user UUID or user@email.com"
                    value={supportUserIdOrEmail}
                    onChange={(e) => setSupportUserIdOrEmail(e.target.value)}
                    disabled={!canMutate || supportSaving}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="supportReferralCode">Referral Code</Label>
                  <Input
                    id="supportReferralCode"
                    placeholder="AB12CD34"
                    value={supportReferralCode}
                    onChange={(e) =>
                      setSupportReferralCode(e.target.value.toUpperCase())
                    }
                    disabled={!canMutate || supportSaving}
                  />
                </div>
              </div>
              {supportError ? (
                <p className="text-sm text-destructive">{supportError}</p>
              ) : null}
              {supportSuccess ? (
                <p className="text-sm text-emerald-500">{supportSuccess}</p>
              ) : null}
              <div className="flex justify-end">
                <Button
                  onClick={() => void bindReferralBySupport()}
                  disabled={!canMutate || supportSaving}
                >
                  {supportSaving ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <Save className="h-4 w-4" />
                  )}
                  Bind Referral
                </Button>
              </div>
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
}

function ConfigInput({
  id,
  label,
  value,
  onChange,
  disabled,
}: {
  id: string;
  label: string;
  value: number | undefined;
  onChange: (value: number) => void;
  disabled?: boolean;
}) {
  return (
    <div className="space-y-2">
      <Label htmlFor={id}>{label}</Label>
      <Input
        id={id}
        type="number"
        value={value ?? 0}
        onChange={(e) => onChange(Number(e.target.value))}
        disabled={disabled}
      />
    </div>
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
