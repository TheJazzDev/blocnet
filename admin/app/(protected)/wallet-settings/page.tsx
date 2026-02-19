"use client";

import { useEffect, useMemo, useState } from "react";
import { Loader2, Save } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { clientApi, type WalletFeeConfig, type WalletRiskLimit } from "@/lib/api-client";
import { useAdminSession } from "@/components/admin-shell";
import { canMutateWallet } from "@/lib/rbac";

type RiskDraft = {
  description: string;
  requiresKyc: boolean;
  maxWithdrawalPerTx: string;
  maxWithdrawalPerDay: string;
  maxInternalTransferPerDay: string;
};

type FeeDraft = {
  flatFee: string;
  percentFee: string;
  minFee: string;
  maxFee: string;
  isActive: boolean;
};

export default function WalletSettingsPage() {
  const session = useAdminSession();
  const canMutate = canMutateWallet(session.roles);

  const [riskLimits, setRiskLimits] = useState<WalletRiskLimit[]>([]);
  const [feeConfigs, setFeeConfigs] = useState<WalletFeeConfig[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [savingRiskTier, setSavingRiskTier] = useState<string | null>(null);
  const [savingFeeKey, setSavingFeeKey] = useState<string | null>(null);

  const [riskDrafts, setRiskDrafts] = useState<Record<string, RiskDraft>>({});
  const [feeDrafts, setFeeDrafts] = useState<Record<string, FeeDraft>>({});

  function load() {
    setLoading(true);
    setError(null);
    Promise.all([clientApi.listWalletRiskLimits(), clientApi.listWalletFeeConfigs()])
      .then(([risk, fees]) => {
        setRiskLimits(risk);
        setFeeConfigs(fees);

        const nextRiskDrafts: Record<string, RiskDraft> = {};
        for (const row of risk) {
          nextRiskDrafts[row.tier] = {
            description: row.description ?? "",
            requiresKyc: row.requiresKyc,
            maxWithdrawalPerTx: row.maxWithdrawalPerTx,
            maxWithdrawalPerDay: row.maxWithdrawalPerDay,
            maxInternalTransferPerDay: row.maxInternalTransferPerDay,
          };
        }
        setRiskDrafts(nextRiskDrafts);

        const nextFeeDrafts: Record<string, FeeDraft> = {};
        for (const row of fees) {
          nextFeeDrafts[row.key] = {
            flatFee: row.flatFee,
            percentFee: row.percentFee,
            minFee: row.minFee,
            maxFee: row.maxFee ?? "",
            isActive: row.isActive,
          };
        }
        setFeeDrafts(nextFeeDrafts);
      })
      .catch((e: unknown) => {
        setRiskLimits([]);
        setFeeConfigs([]);
        setError(e instanceof Error ? e.message : "Failed to load wallet settings");
      })
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
  }, []);

  const hasData = useMemo(() => riskLimits.length > 0 || feeConfigs.length > 0, [riskLimits, feeConfigs]);

  async function saveRisk(tier: string) {
    const draft = riskDrafts[tier];
    if (!draft) return;
    setSavingRiskTier(tier);
    try {
      await clientApi.updateWalletRiskLimit(tier, {
        description: draft.description,
        requiresKyc: draft.requiresKyc,
        maxWithdrawalPerTx: draft.maxWithdrawalPerTx,
        maxWithdrawalPerDay: draft.maxWithdrawalPerDay,
        maxInternalTransferPerDay: draft.maxInternalTransferPerDay,
      });
      await load();
    } finally {
      setSavingRiskTier(null);
    }
  }

  async function saveFee(key: string) {
    const draft = feeDrafts[key];
    if (!draft) return;
    setSavingFeeKey(key);
    try {
      await clientApi.updateWalletFeeConfig(key, {
        flatFee: draft.flatFee,
        percentFee: draft.percentFee,
        minFee: draft.minFee,
        maxFee: draft.maxFee.trim() ? draft.maxFee : null,
        isActive: draft.isActive,
      });
      await load();
    } finally {
      setSavingFeeKey(null);
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Wallet Settings"
        description="Manage withdrawal limits and wallet fee policies."
      />

      {!canMutate && (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardContent className="pt-6 text-sm text-amber-200">
            Read-only access. Owner/Admin roles are required to mutate wallet settings.
          </CardContent>
        </Card>
      )}

      {error && (
        <Card>
          <CardContent className="pt-6 text-sm text-destructive">{error}</CardContent>
        </Card>
      )}

      {!hasData && loading ? (
        <Card>
          <CardContent className="pt-6">
            <LoadingSpinner className="py-10" />
          </CardContent>
        </Card>
      ) : (
        <>
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Risk Limits</CardTitle>
            </CardHeader>
            <CardContent>
              {loading ? (
                <LoadingSpinner className="py-10" />
              ) : riskLimits.length === 0 ? (
                <p className="text-sm text-muted-foreground">No risk tiers configured.</p>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Tier</TableHead>
                      <TableHead>Requires KYC</TableHead>
                      <TableHead>Per Tx</TableHead>
                      <TableHead>Per Day</TableHead>
                      <TableHead>Internal/Day</TableHead>
                      <TableHead className="w-[130px]" />
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {riskLimits.map((row) => {
                      const draft = riskDrafts[row.tier];
                      if (!draft) return null;
                      return (
                        <TableRow key={row.id}>
                          <TableCell>
                            <Badge variant="secondary">{row.tier}</Badge>
                          </TableCell>
                          <TableCell>
                            <Select
                              value={draft.requiresKyc ? "true" : "false"}
                              onValueChange={(next) =>
                                setRiskDrafts((prev) => ({
                                  ...prev,
                                  [row.tier]: {
                                    ...prev[row.tier],
                                    requiresKyc: next === "true",
                                  },
                                }))
                              }
                              disabled={!canMutate}
                            >
                              <SelectTrigger className="w-[110px]">
                                <SelectValue />
                              </SelectTrigger>
                              <SelectContent>
                                <SelectItem value="true">Yes</SelectItem>
                                <SelectItem value="false">No</SelectItem>
                              </SelectContent>
                            </Select>
                          </TableCell>
                          <TableCell>
                            <Input
                              value={draft.maxWithdrawalPerTx}
                              onChange={(e) =>
                                setRiskDrafts((prev) => ({
                                  ...prev,
                                  [row.tier]: {
                                    ...prev[row.tier],
                                    maxWithdrawalPerTx: e.target.value,
                                  },
                                }))
                              }
                              disabled={!canMutate}
                            />
                          </TableCell>
                          <TableCell>
                            <Input
                              value={draft.maxWithdrawalPerDay}
                              onChange={(e) =>
                                setRiskDrafts((prev) => ({
                                  ...prev,
                                  [row.tier]: {
                                    ...prev[row.tier],
                                    maxWithdrawalPerDay: e.target.value,
                                  },
                                }))
                              }
                              disabled={!canMutate}
                            />
                          </TableCell>
                          <TableCell>
                            <Input
                              value={draft.maxInternalTransferPerDay}
                              onChange={(e) =>
                                setRiskDrafts((prev) => ({
                                  ...prev,
                                  [row.tier]: {
                                    ...prev[row.tier],
                                    maxInternalTransferPerDay: e.target.value,
                                  },
                                }))
                              }
                              disabled={!canMutate}
                            />
                          </TableCell>
                          <TableCell>
                            <Button
                              size="sm"
                              onClick={() => saveRisk(row.tier)}
                              disabled={!canMutate || savingRiskTier === row.tier}
                            >
                              {savingRiskTier === row.tier ? (
                                <Loader2 className="h-4 w-4 animate-spin" />
                              ) : (
                                <Save className="h-4 w-4" />
                              )}
                              Save
                            </Button>
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Fee Configs</CardTitle>
            </CardHeader>
            <CardContent>
              {loading ? (
                <LoadingSpinner className="py-10" />
              ) : feeConfigs.length === 0 ? (
                <p className="text-sm text-muted-foreground">No fee configs configured.</p>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Key</TableHead>
                      <TableHead>Flat</TableHead>
                      <TableHead>Percent</TableHead>
                      <TableHead>Min</TableHead>
                      <TableHead>Max</TableHead>
                      <TableHead>Active</TableHead>
                      <TableHead className="w-[130px]" />
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {feeConfigs.map((row) => {
                      const draft = feeDrafts[row.key];
                      if (!draft) return null;
                      return (
                        <TableRow key={row.id}>
                          <TableCell>
                            <Badge variant="secondary">{row.key}</Badge>
                          </TableCell>
                          <TableCell>
                            <Input
                              value={draft.flatFee}
                              onChange={(e) =>
                                setFeeDrafts((prev) => ({
                                  ...prev,
                                  [row.key]: {
                                    ...prev[row.key],
                                    flatFee: e.target.value,
                                  },
                                }))
                              }
                              disabled={!canMutate}
                            />
                          </TableCell>
                          <TableCell>
                            <Input
                              value={draft.percentFee}
                              onChange={(e) =>
                                setFeeDrafts((prev) => ({
                                  ...prev,
                                  [row.key]: {
                                    ...prev[row.key],
                                    percentFee: e.target.value,
                                  },
                                }))
                              }
                              disabled={!canMutate}
                            />
                          </TableCell>
                          <TableCell>
                            <Input
                              value={draft.minFee}
                              onChange={(e) =>
                                setFeeDrafts((prev) => ({
                                  ...prev,
                                  [row.key]: {
                                    ...prev[row.key],
                                    minFee: e.target.value,
                                  },
                                }))
                              }
                              disabled={!canMutate}
                            />
                          </TableCell>
                          <TableCell>
                            <Input
                              value={draft.maxFee}
                              onChange={(e) =>
                                setFeeDrafts((prev) => ({
                                  ...prev,
                                  [row.key]: {
                                    ...prev[row.key],
                                    maxFee: e.target.value,
                                  },
                                }))
                              }
                              placeholder="optional"
                              disabled={!canMutate}
                            />
                          </TableCell>
                          <TableCell>
                            <Select
                              value={draft.isActive ? "true" : "false"}
                              onValueChange={(next) =>
                                setFeeDrafts((prev) => ({
                                  ...prev,
                                  [row.key]: {
                                    ...prev[row.key],
                                    isActive: next === "true",
                                  },
                                }))
                              }
                              disabled={!canMutate}
                            >
                              <SelectTrigger className="w-[90px]">
                                <SelectValue />
                              </SelectTrigger>
                              <SelectContent>
                                <SelectItem value="true">Yes</SelectItem>
                                <SelectItem value="false">No</SelectItem>
                              </SelectContent>
                            </Select>
                          </TableCell>
                          <TableCell>
                            <Button
                              size="sm"
                              onClick={() => saveFee(row.key)}
                              disabled={!canMutate || savingFeeKey === row.key}
                            >
                              {savingFeeKey === row.key ? (
                                <Loader2 className="h-4 w-4 animate-spin" />
                              ) : (
                                <Save className="h-4 w-4" />
                              )}
                              Save
                            </Button>
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
}
