"use client";

import { useEffect, useMemo, useState } from "react";
import { Loader2, RefreshCw, Save } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { clientApi, type AdminTipSettings } from "@/lib/api-client";
import { useAdminSession } from "@/components/admin-shell";
import { canMutateWallet } from "@/lib/rbac";

type CurrencyDraft = {
  name: string;
  symbol: string;
  isEnabled: boolean;
  feeBps: number;
  minTip: string;
  maxTip: string;
  minFee: string;
  maxFee: string;
  senderPaysFee: boolean;
  policyActive: boolean;
};

function boolBadge(enabled: boolean, trueLabel = "Yes", falseLabel = "No") {
  if (enabled) {
    return <Badge className="bg-emerald-500/15 text-emerald-300">{trueLabel}</Badge>;
  }
  return <Badge variant="secondary">{falseLabel}</Badge>;
}

function toDrafts(settings: AdminTipSettings): Record<string, CurrencyDraft> {
  const drafts: Record<string, CurrencyDraft> = {};
  for (const row of settings.currencies) {
    drafts[row.code] = {
      name: row.name,
      symbol: row.symbol,
      isEnabled: row.isEnabled,
      feeBps: row.feePolicy?.feeBps ?? 0,
      minTip: row.feePolicy?.minTip ?? "0.001",
      maxTip: row.feePolicy?.maxTip ?? "",
      minFee: row.feePolicy?.minFee ?? "0",
      maxFee: row.feePolicy?.maxFee ?? "",
      senderPaysFee: row.feePolicy?.senderPaysFee ?? true,
      policyActive: row.feePolicy?.isActive ?? true,
    };
  }
  return drafts;
}

export default function TipSettingsPage() {
  const session = useAdminSession();
  const canMutate = canMutateWallet(session.effectiveRoles);

  const [settings, setSettings] = useState<AdminTipSettings | null>(null);
  const [drafts, setDrafts] = useState<Record<string, CurrencyDraft>>({});
  const [activeCurrencyCode, setActiveCurrencyCode] = useState<string>("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [savingCode, setSavingCode] = useState<string | null>(null);
  const [activating, setActivating] = useState(false);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const next = await clientApi.getTipSettings();
      setSettings(next);
      setDrafts(toDrafts(next));
      setActiveCurrencyCode(next.activeCurrencyCode ?? next.currencies[0]?.code ?? "");
    } catch (e: unknown) {
      setSettings(null);
      setDrafts({});
      setError(e instanceof Error ? e.message : "Failed to load tip settings");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
  }, []);

  const currencies = useMemo(() => settings?.currencies ?? [], [settings]);

  async function saveCurrency(code: string) {
    const draft = drafts[code];
    if (!draft) return;
    if (!draft.name.trim() || !draft.symbol.trim()) {
      setError("Currency name and symbol are required.");
      return;
    }

    setSavingCode(code);
    setError(null);
    try {
      const next = await clientApi.updateTipCurrencySettings(code, {
        name: draft.name.trim(),
        symbol: draft.symbol.trim(),
        isEnabled: draft.isEnabled,
        feeBps: draft.feeBps,
        minTip: draft.minTip,
        maxTip: draft.maxTip.trim() ? draft.maxTip.trim() : null,
        minFee: draft.minFee,
        maxFee: draft.maxFee.trim() ? draft.maxFee.trim() : null,
        senderPaysFee: draft.senderPaysFee,
        policyActive: draft.policyActive,
      });
      setSettings(next);
      setDrafts(toDrafts(next));
      setActiveCurrencyCode(next.activeCurrencyCode ?? code);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Failed to save tip currency settings");
    } finally {
      setSavingCode(null);
    }
  }

  async function activateCurrency() {
    if (!activeCurrencyCode) return;
    setActivating(true);
    setError(null);
    try {
      const next = await clientApi.setActiveTipCurrency({ currencyCode: activeCurrencyCode });
      setSettings(next);
      setDrafts(toDrafts(next));
      setActiveCurrencyCode(next.activeCurrencyCode ?? activeCurrencyCode);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Failed to activate tip currency");
    } finally {
      setActivating(false);
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Tip Settings"
        description="Manage active tipping currency, sender fee policy, and fee vault balances."
      >
        <Button variant="outline" onClick={() => void load()} disabled={loading}>
          {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
          Refresh
        </Button>
      </PageHeader>

      {!canMutate && (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardContent className="pt-6 text-sm text-amber-200">
            Read-only access. Owner/Admin roles are required to update tipping settings.
          </CardContent>
        </Card>
      )}

      {error && (
        <Card>
          <CardContent className="pt-6 text-sm text-destructive">{error}</CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Active Tipping Currency</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3 md:max-w-xl">
          {loading ? (
            <LoadingSpinner className="py-8" />
          ) : currencies.length === 0 ? (
            <p className="text-sm text-muted-foreground">No tip currencies configured.</p>
          ) : (
            <>
              <div className="flex flex-wrap items-center gap-2">
                {currencies.map((row) => (
                  <Badge key={row.code} variant={row.isActiveTippingCurrency ? "default" : "secondary"}>
                    {row.code} {row.isActiveTippingCurrency ? "(Active)" : ""}
                  </Badge>
                ))}
              </div>
              <div className="flex flex-col gap-3 md:flex-row">
                <Select value={activeCurrencyCode} onValueChange={setActiveCurrencyCode}>
                  <SelectTrigger className="w-full md:w-[220px]">
                    <SelectValue placeholder="Select currency" />
                  </SelectTrigger>
                  <SelectContent>
                    {currencies.map((row) => (
                      <SelectItem key={row.code} value={row.code}>
                        {row.code} ({row.symbol})
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <Button
                  onClick={() => void activateCurrency()}
                  disabled={
                    !canMutate ||
                    !activeCurrencyCode ||
                    activeCurrencyCode === settings?.activeCurrencyCode ||
                    activating
                  }
                >
                  {activating ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
                  Set Active
                </Button>
              </div>
            </>
          )}
        </CardContent>
      </Card>

      {loading ? (
        <Card>
          <CardContent className="pt-6">
            <LoadingSpinner className="py-10" />
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4">
          {currencies.map((row) => {
            const draft = drafts[row.code];
            if (!draft) return null;

            return (
              <Card key={row.code}>
                <CardHeader className="pb-3">
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <CardTitle className="text-base">
                      {row.code} · {row.name}
                    </CardTitle>
                    <div className="flex flex-wrap items-center gap-2">
                      {row.kind === "points" ? (
                        <Badge className="bg-blue-500/15 text-blue-300">Points</Badge>
                      ) : (
                        <Badge className="bg-violet-500/15 text-violet-300">Token</Badge>
                      )}
                      {boolBadge(row.isEnabled, "Enabled", "Disabled")}
                      {boolBadge(row.feePolicy?.isActive ?? false, "Policy Active", "Policy Off")}
                    </div>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid gap-3 md:grid-cols-2">
                    <div className="space-y-2">
                      <Label htmlFor={`name-${row.code}`}>Name</Label>
                      <Input
                        id={`name-${row.code}`}
                        value={draft.name}
                        onChange={(event) =>
                          setDrafts((prev) => ({
                            ...prev,
                            [row.code]: { ...prev[row.code], name: event.target.value },
                          }))
                        }
                        disabled={!canMutate}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor={`symbol-${row.code}`}>Symbol</Label>
                      <Input
                        id={`symbol-${row.code}`}
                        value={draft.symbol}
                        onChange={(event) =>
                          setDrafts((prev) => ({
                            ...prev,
                            [row.code]: { ...prev[row.code], symbol: event.target.value.toUpperCase() },
                          }))
                        }
                        disabled={!canMutate}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor={`feeBps-${row.code}`}>Fee (bps)</Label>
                      <Input
                        id={`feeBps-${row.code}`}
                        type="number"
                        min={0}
                        max={10000}
                        value={draft.feeBps}
                        onChange={(event) =>
                          setDrafts((prev) => ({
                            ...prev,
                            [row.code]: {
                              ...prev[row.code],
                              feeBps: Number(event.target.value || 0),
                            },
                          }))
                        }
                        disabled={!canMutate}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor={`minTip-${row.code}`}>Min Tip ({row.symbol})</Label>
                      <Input
                        id={`minTip-${row.code}`}
                        value={draft.minTip}
                        onChange={(event) =>
                          setDrafts((prev) => ({
                            ...prev,
                            [row.code]: { ...prev[row.code], minTip: event.target.value },
                          }))
                        }
                        disabled={!canMutate}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor={`maxTip-${row.code}`}>Max Tip ({row.symbol})</Label>
                      <Input
                        id={`maxTip-${row.code}`}
                        value={draft.maxTip}
                        onChange={(event) =>
                          setDrafts((prev) => ({
                            ...prev,
                            [row.code]: { ...prev[row.code], maxTip: event.target.value },
                          }))
                        }
                        disabled={!canMutate}
                        placeholder="No max"
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor={`minFee-${row.code}`}>Min Fee ({row.symbol})</Label>
                      <Input
                        id={`minFee-${row.code}`}
                        value={draft.minFee}
                        onChange={(event) =>
                          setDrafts((prev) => ({
                            ...prev,
                            [row.code]: { ...prev[row.code], minFee: event.target.value },
                          }))
                        }
                        disabled={!canMutate}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor={`maxFee-${row.code}`}>Max Fee ({row.symbol})</Label>
                      <Input
                        id={`maxFee-${row.code}`}
                        value={draft.maxFee}
                        onChange={(event) =>
                          setDrafts((prev) => ({
                            ...prev,
                            [row.code]: { ...prev[row.code], maxFee: event.target.value },
                          }))
                        }
                        disabled={!canMutate}
                        placeholder="No max"
                      />
                    </div>
                    <div className="space-y-2">
                      <Label>Sender Pays Fee</Label>
                      <Select
                        value={draft.senderPaysFee ? "true" : "false"}
                        onValueChange={(value) =>
                          setDrafts((prev) => ({
                            ...prev,
                            [row.code]: { ...prev[row.code], senderPaysFee: value === "true" },
                          }))
                        }
                        disabled={!canMutate}
                      >
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="true">Yes</SelectItem>
                          <SelectItem value="false">No (hunter pays)</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                    <div className="space-y-2">
                      <Label>Policy Active</Label>
                      <Select
                        value={draft.policyActive ? "true" : "false"}
                        onValueChange={(value) =>
                          setDrafts((prev) => ({
                            ...prev,
                            [row.code]: { ...prev[row.code], policyActive: value === "true" },
                          }))
                        }
                        disabled={!canMutate}
                      >
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="true">Active</SelectItem>
                          <SelectItem value="false">Inactive</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                    <div className="space-y-2">
                      <Label>Currency Enabled</Label>
                      <Select
                        value={draft.isEnabled ? "true" : "false"}
                        onValueChange={(value) =>
                          setDrafts((prev) => ({
                            ...prev,
                            [row.code]: { ...prev[row.code], isEnabled: value === "true" },
                          }))
                        }
                        disabled={!canMutate}
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

                  <div className="rounded-lg border p-3">
                    <p className="text-sm font-medium">Fee Vault</p>
                    <p className="text-xs text-muted-foreground">
                      Current balance: {row.feeVaultBalance} {row.symbol}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      Atomic: {row.feeVaultBalanceAtomic}
                    </p>
                  </div>

                  <div className="flex justify-end">
                    <Button
                      onClick={() => void saveCurrency(row.code)}
                      disabled={!canMutate || savingCode === row.code}
                    >
                      {savingCode === row.code ? (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      ) : (
                        <Save className="h-4 w-4" />
                      )}
                      Save {row.code}
                    </Button>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
