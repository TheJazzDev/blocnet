"use client";

import { useEffect, useMemo, useState } from "react";
import { Loader2, RefreshCw, Save } from "lucide-react";
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
import {
  clientApi,
  type AdminWalletDepositReprocessResponse,
  type AdminWalletHealth,
  type WalletAssetCode,
  type WalletAssetPriceConfig,
  type WalletFeeConfig,
  type WalletRiskLimit,
  type WalletRuntimeConfig,
} from "@/lib/api-client";
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

type AssetPriceDraft = {
  providerId: string;
  fallbackUsdPrice: string;
  isActive: boolean;
};

function boolBadge(enabled: boolean, trueLabel = "Yes", falseLabel = "No") {
  if (enabled) {
    return (
      <Badge className="bg-emerald-500/15 text-emerald-300">{trueLabel}</Badge>
    );
  }
  return <Badge variant="secondary">{falseLabel}</Badge>;
}

function formatKeyLabel(value: string) {
  return value
    .replace(/_/g, " ")
    .replace(/\b\w/g, (char) => char.toUpperCase());
}

function renderCountGroup(title: string, values: Record<string, number>) {
  return (
    <div className="rounded-lg border p-3">
      <p className="mb-2 text-xs font-medium uppercase tracking-wide text-muted-foreground">
        {title}
      </p>
      <div className="space-y-1.5">
        {Object.entries(values).map(([key, value]) => (
          <div key={key} className="flex items-center justify-between text-sm">
            <span className="text-muted-foreground">{formatKeyLabel(key)}</span>
            <span className="font-medium">{value}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

export default function WalletSettingsPage() {
  const session = useAdminSession();
  const canMutate = canMutateWallet(session.effectiveRoles);

  const [riskLimits, setRiskLimits] = useState<WalletRiskLimit[]>([]);
  const [feeConfigs, setFeeConfigs] = useState<WalletFeeConfig[]>([]);
  const [assetPriceConfigs, setAssetPriceConfigs] = useState<
    WalletAssetPriceConfig[]
  >([]);
  const [runtimeConfig, setRuntimeConfig] =
    useState<WalletRuntimeConfig | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [walletHealth, setWalletHealth] = useState<AdminWalletHealth | null>(
    null,
  );
  const [healthLoading, setHealthLoading] = useState(true);
  const [healthError, setHealthError] = useState<string | null>(null);

  const [savingRiskTier, setSavingRiskTier] = useState<string | null>(null);
  const [savingFeeKey, setSavingFeeKey] = useState<string | null>(null);
  const [savingPriceAsset, setSavingPriceAsset] =
    useState<WalletAssetCode | null>(null);
  const [savingRuntimeConfig, setSavingRuntimeConfig] = useState(false);
  const [runtimeStatus, setRuntimeStatus] = useState<string | null>(null);
  const [manualTxHash, setManualTxHash] = useState("");
  const [manualChainEnvironment, setManualChainEnvironment] = useState<
    "testnet" | "mainnet"
  >("testnet");
  const [manualAsset, setManualAsset] = useState<"all" | WalletAssetCode>(
    "all",
  );
  const [manualReprocessLoading, setManualReprocessLoading] = useState(false);
  const [manualReprocessStatus, setManualReprocessStatus] = useState<
    string | null
  >(null);
  const [manualReprocessResult, setManualReprocessResult] =
    useState<AdminWalletDepositReprocessResponse | null>(null);

  const [riskDrafts, setRiskDrafts] = useState<Record<string, RiskDraft>>({});
  const [feeDrafts, setFeeDrafts] = useState<Record<string, FeeDraft>>({});
  const [assetPriceDrafts, setAssetPriceDrafts] = useState<
    Record<string, AssetPriceDraft>
  >({});

  async function loadWalletHealth() {
    setHealthLoading(true);
    setHealthError(null);
    try {
      const result = await clientApi.getWalletHealth();
      setWalletHealth(result);
    } catch (e: unknown) {
      setWalletHealth(null);
      setHealthError(
        e instanceof Error ? e.message : "Failed to load wallet health",
      );
    } finally {
      setHealthLoading(false);
    }
  }

  async function loadSettings() {
    setLoading(true);
    setError(null);
    try {
      const [risk, fees, prices, runtime] = await Promise.all([
        clientApi.listWalletRiskLimits(),
        clientApi.listWalletFeeConfigs(),
        clientApi.listWalletAssetPriceConfigs(),
        clientApi.getWalletRuntimeConfig(),
      ]);
      setRiskLimits(risk);
      setFeeConfigs(fees);
      setAssetPriceConfigs(prices);
      setRuntimeConfig(runtime);

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

      const nextPriceDrafts: Record<string, AssetPriceDraft> = {};
      for (const row of prices) {
        nextPriceDrafts[row.asset] = {
          providerId: row.providerId ?? "",
          fallbackUsdPrice: row.fallbackUsdPrice,
          isActive: row.isActive,
        };
      }
      setAssetPriceDrafts(nextPriceDrafts);
    } catch (e: unknown) {
      setRiskLimits([]);
      setFeeConfigs([]);
      setAssetPriceConfigs([]);
      setRuntimeConfig(null);
      setError(
        e instanceof Error ? e.message : "Failed to load wallet settings",
      );
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void loadSettings();
    void loadWalletHealth();
  }, []);

  const availableChainEnvironments = useMemo(() => {
    if (!walletHealth || walletHealth.networks.length === 0) {
      return ["testnet", "mainnet"] as ("testnet" | "mainnet")[];
    }
    const environments = Array.from(
      new Set(walletHealth.networks.map((row) => row.chainEnvironment)),
    );
    return environments as ("testnet" | "mainnet")[];
  }, [walletHealth]);

  useEffect(() => {
    if (availableChainEnvironments.includes(manualChainEnvironment)) {
      return;
    }
    setManualChainEnvironment(availableChainEnvironments[0] ?? "testnet");
  }, [availableChainEnvironments, manualChainEnvironment]);

  const hasData = useMemo(
    () =>
      riskLimits.length > 0 ||
      feeConfigs.length > 0 ||
      assetPriceConfigs.length > 0 ||
      runtimeConfig !== null,
    [riskLimits, feeConfigs, assetPriceConfigs, runtimeConfig],
  );

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
      await loadSettings();
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
      await loadSettings();
    } finally {
      setSavingFeeKey(null);
    }
  }

  async function saveAssetPrice(asset: WalletAssetCode) {
    const draft = assetPriceDrafts[asset];
    if (!draft) return;
    setSavingPriceAsset(asset);
    try {
      await clientApi.updateWalletAssetPriceConfig(asset, {
        providerId: draft.providerId.trim() || null,
        fallbackUsdPrice: draft.fallbackUsdPrice,
        isActive: draft.isActive,
      });
      await loadSettings();
    } finally {
      setSavingPriceAsset(null);
    }
  }

  function toggleWithdrawalAsset(asset: WalletAssetCode) {
    setRuntimeConfig((prev) => {
      if (!prev) return prev;
      const hasAsset = prev.withdrawalEnabledAssets.includes(asset);
      if (hasAsset && prev.withdrawalEnabledAssets.length === 1) {
        return prev;
      }
      const nextAssets = hasAsset
        ? prev.withdrawalEnabledAssets.filter((entry) => entry !== asset)
        : [...prev.withdrawalEnabledAssets, asset];
      return { ...prev, withdrawalEnabledAssets: nextAssets };
    });
  }

  async function saveRuntime() {
    if (!runtimeConfig) return;
    setSavingRuntimeConfig(true);
    setRuntimeStatus(null);
    try {
      const updated = await clientApi.updateWalletRuntimeConfig({
        walletEnabled: runtimeConfig.walletEnabled,
        depositsEnabled: runtimeConfig.depositsEnabled,
        withdrawalsEnabled: runtimeConfig.withdrawalsEnabled,
        depositRealtimeEnabled: runtimeConfig.depositRealtimeEnabled,
        depositConfirmations: runtimeConfig.depositConfirmations,
        withdrawalConfirmations: runtimeConfig.withdrawalConfirmations,
        walletAssetBntEnabled: runtimeConfig.walletAssetBntEnabled,
        walletAssetBnbEnabled: runtimeConfig.walletAssetBnbEnabled,
        walletAssetUsdtEnabled: runtimeConfig.walletAssetUsdtEnabled,
        withdrawalEnabledAssets: runtimeConfig.withdrawalEnabledAssets,
      });
      setRuntimeConfig(updated);
      setRuntimeStatus("Runtime config saved and applied.");
      await loadWalletHealth();
    } catch (e: unknown) {
      setRuntimeStatus(
        e instanceof Error ? e.message : "Failed to save runtime config",
      );
    } finally {
      setSavingRuntimeConfig(false);
    }
  }

  async function runManualDepositReprocess() {
    const txHash = manualTxHash.trim();
    if (!txHash) {
      setManualReprocessStatus("Transaction hash is required.");
      return;
    }

    setManualReprocessLoading(true);
    setManualReprocessStatus(null);
    setManualReprocessResult(null);
    try {
      const result = await clientApi.reprocessWalletDepositByTxHash({
        txHash,
        chainEnvironment: manualChainEnvironment,
        asset: manualAsset === "all" ? undefined : manualAsset,
      });
      setManualReprocessResult(result);
      setManualReprocessStatus(
        `Reprocess complete. Matched assets: ${result.summary.matchedAssets}. Credited deposits: ${result.summary.creditedDeposits}.`,
      );
      await loadWalletHealth();
    } catch (e: unknown) {
      setManualReprocessStatus(
        e instanceof Error
          ? e.message
          : "Failed to reprocess the transaction hash.",
      );
    } finally {
      setManualReprocessLoading(false);
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Wallet Settings"
        description="Manage withdrawal limits, fee policies, and wallet operations health."
      />

      {!canMutate && (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardContent className="pt-6 text-sm text-amber-200">
            Read-only access. Owner/Admin roles are required to mutate wallet
            settings.
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0">
          <CardTitle className="text-base">Runtime Wallet Controls</CardTitle>
          <Button
            size="sm"
            onClick={() => void saveRuntime()}
            disabled={
              !canMutate || !runtimeConfig || savingRuntimeConfig || loading
            }
          >
            {savingRuntimeConfig ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <Save className="h-4 w-4" />
            )}
            Save Runtime Config
          </Button>
        </CardHeader>
        <CardContent className="space-y-4">
          {loading ? (
            <LoadingSpinner className="py-6" />
          ) : !runtimeConfig ? (
            <p className="text-sm text-muted-foreground">
              Runtime wallet config unavailable.
            </p>
          ) : (
            <>
              <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
                <div className="space-y-1.5">
                  <p className="text-xs uppercase tracking-wide text-muted-foreground">
                    Wallet
                  </p>
                  <Select
                    value={runtimeConfig.walletEnabled ? "true" : "false"}
                    onValueChange={(value) =>
                      setRuntimeConfig((prev) =>
                        prev
                          ? { ...prev, walletEnabled: value === "true" }
                          : prev,
                      )
                    }
                    disabled={!canMutate || savingRuntimeConfig}
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
                  <p className="text-xs uppercase tracking-wide text-muted-foreground">
                    Deposits
                  </p>
                  <Select
                    value={runtimeConfig.depositsEnabled ? "true" : "false"}
                    onValueChange={(value) =>
                      setRuntimeConfig((prev) =>
                        prev
                          ? { ...prev, depositsEnabled: value === "true" }
                          : prev,
                      )
                    }
                    disabled={!canMutate || savingRuntimeConfig}
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
                  <p className="text-xs uppercase tracking-wide text-muted-foreground">
                    Withdrawals
                  </p>
                  <Select
                    value={runtimeConfig.withdrawalsEnabled ? "true" : "false"}
                    onValueChange={(value) =>
                      setRuntimeConfig((prev) =>
                        prev
                          ? { ...prev, withdrawalsEnabled: value === "true" }
                          : prev,
                      )
                    }
                    disabled={!canMutate || savingRuntimeConfig}
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
                  <p className="text-xs uppercase tracking-wide text-muted-foreground">
                    Realtime Deposits
                  </p>
                  <Select
                    value={
                      runtimeConfig.depositRealtimeEnabled ? "true" : "false"
                    }
                    onValueChange={(value) =>
                      setRuntimeConfig((prev) =>
                        prev
                          ? {
                              ...prev,
                              depositRealtimeEnabled: value === "true",
                            }
                          : prev,
                      )
                    }
                    disabled={!canMutate || savingRuntimeConfig}
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

              <div className="grid gap-3 md:grid-cols-2">
                <div className="space-y-1.5">
                  <p className="text-xs uppercase tracking-wide text-muted-foreground">
                    Deposit Confirmations
                  </p>
                  <Input
                    type="number"
                    min={1}
                    max={400}
                    value={runtimeConfig.depositConfirmations}
                    onChange={(event) => {
                      const next = Number(event.target.value);
                      setRuntimeConfig((prev) =>
                        prev
                          ? {
                              ...prev,
                              depositConfirmations: Number.isFinite(next)
                                ? Math.min(Math.max(Math.floor(next), 1), 400)
                                : prev.depositConfirmations,
                            }
                          : prev,
                      );
                    }}
                    disabled={!canMutate || savingRuntimeConfig}
                  />
                </div>
                <div className="space-y-1.5">
                  <p className="text-xs uppercase tracking-wide text-muted-foreground">
                    Withdrawal Confirmations
                  </p>
                  <Input
                    type="number"
                    min={1}
                    max={400}
                    value={runtimeConfig.withdrawalConfirmations}
                    onChange={(event) => {
                      const next = Number(event.target.value);
                      setRuntimeConfig((prev) =>
                        prev
                          ? {
                              ...prev,
                              withdrawalConfirmations: Number.isFinite(next)
                                ? Math.min(Math.max(Math.floor(next), 1), 400)
                                : prev.withdrawalConfirmations,
                            }
                          : prev,
                      );
                    }}
                    disabled={!canMutate || savingRuntimeConfig}
                  />
                </div>
              </div>

              <div className="grid gap-3 md:grid-cols-2">
                <div className="space-y-1.5">
                  <p className="text-xs uppercase tracking-wide text-muted-foreground">
                    Enabled Assets
                  </p>
                  <div className="flex flex-wrap gap-2">
                    {(["BNT", "BNB", "USDT"] as WalletAssetCode[]).map(
                      (asset) => {
                        const selected =
                          asset === "BNT"
                            ? runtimeConfig.walletAssetBntEnabled
                            : asset === "BNB"
                              ? runtimeConfig.walletAssetBnbEnabled
                              : runtimeConfig.walletAssetUsdtEnabled;
                        return (
                          <Button
                            key={asset}
                            type="button"
                            size="sm"
                            variant={selected ? "default" : "outline"}
                            disabled={!canMutate || savingRuntimeConfig}
                            onClick={() =>
                              setRuntimeConfig((prev) => {
                                if (!prev) return prev;
                                if (asset === "BNT") {
                                  return {
                                    ...prev,
                                    walletAssetBntEnabled:
                                      !prev.walletAssetBntEnabled,
                                  };
                                }
                                if (asset === "BNB") {
                                  return {
                                    ...prev,
                                    walletAssetBnbEnabled:
                                      !prev.walletAssetBnbEnabled,
                                  };
                                }
                                return {
                                  ...prev,
                                  walletAssetUsdtEnabled:
                                    !prev.walletAssetUsdtEnabled,
                                };
                              })
                            }
                          >
                            {asset}
                          </Button>
                        );
                      },
                    )}
                  </div>
                </div>
                <div className="space-y-1.5">
                  <p className="text-xs uppercase tracking-wide text-muted-foreground">
                    Transfer/Withdrawal Assets
                  </p>
                  <div className="flex flex-wrap gap-2">
                    {(["BNT", "BNB", "USDT"] as WalletAssetCode[]).map(
                      (asset) => (
                        <Button
                          key={asset}
                          type="button"
                          size="sm"
                          variant={
                            runtimeConfig.withdrawalEnabledAssets.includes(
                              asset,
                            )
                              ? "default"
                              : "outline"
                          }
                          disabled={!canMutate || savingRuntimeConfig}
                          onClick={() => toggleWithdrawalAsset(asset)}
                        >
                          {asset}
                        </Button>
                      ),
                    )}
                  </div>
                </div>
              </div>

              <p className="text-xs text-muted-foreground">
                Last updated:{" "}
                {new Date(runtimeConfig.updatedAt).toLocaleString()}
              </p>
            </>
          )}

          {runtimeStatus ? (
            <p className="text-xs text-muted-foreground">{runtimeStatus}</p>
          ) : null}
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0">
          <CardTitle className="text-base">Manual Deposit Reprocess</CardTitle>
          <Button
            size="sm"
            onClick={() => void runManualDepositReprocess()}
            disabled={
              !canMutate || manualReprocessLoading || !manualTxHash.trim()
            }
          >
            {manualReprocessLoading ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <RefreshCw className="h-4 w-4" />
            )}
            Reprocess Tx
          </Button>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted-foreground">
            Replay one on-chain transaction through the deposit indexer and
            credit path without changing runtime scan windows.
          </p>
          <div className="grid gap-3 md:grid-cols-3">
            <div className="space-y-1.5 md:col-span-2">
              <p className="text-xs uppercase tracking-wide text-muted-foreground">
                Transaction Hash
              </p>
              <Input
                placeholder="0x..."
                value={manualTxHash}
                onChange={(event) => setManualTxHash(event.target.value)}
                disabled={!canMutate || manualReprocessLoading}
              />
            </div>
            <div className="space-y-1.5">
              <p className="text-xs uppercase tracking-wide text-muted-foreground">
                Chain Environment
              </p>
              <Select
                value={manualChainEnvironment}
                onValueChange={(value: "testnet" | "mainnet") =>
                  setManualChainEnvironment(value)
                }
                disabled={!canMutate || manualReprocessLoading}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {availableChainEnvironments.map((environment) => (
                    <SelectItem key={environment} value={environment}>
                      {environment.toUpperCase()}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="space-y-1.5">
            <p className="text-xs uppercase tracking-wide text-muted-foreground">
              Asset Filter
            </p>
            <Select
              value={manualAsset}
              onValueChange={(value: "all" | WalletAssetCode) =>
                setManualAsset(value)
              }
              disabled={!canMutate || manualReprocessLoading}
            >
              <SelectTrigger className="max-w-[220px]">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All assets</SelectItem>
                <SelectItem value="BNT">BNT</SelectItem>
                <SelectItem value="BNB">BNB</SelectItem>
                <SelectItem value="USDT">USDT</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {manualReprocessStatus ? (
            <p className="text-xs text-muted-foreground">{manualReprocessStatus}</p>
          ) : null}

          {manualReprocessResult ? (
            <div className="space-y-3 rounded-lg border p-3">
              <div className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
                <Badge variant="outline">{manualReprocessResult.txHash}</Badge>
                <Badge variant="secondary">
                  {manualReprocessResult.chainEnvironment.toUpperCase()}
                </Badge>
                <span>
                  Tx Block: {manualReprocessResult.txBlockNumber} | Head:{" "}
                  {manualReprocessResult.headBlockNumber}
                </span>
              </div>
              <div className="grid gap-3 md:grid-cols-3">
                <div className="rounded border p-2 text-xs">
                  <p className="text-muted-foreground">Matched Assets</p>
                  <p className="font-medium">
                    {manualReprocessResult.summary.matchedAssets}
                  </p>
                </div>
                <div className="rounded border p-2 text-xs">
                  <p className="text-muted-foreground">Detected Deposits</p>
                  <p className="font-medium">
                    {manualReprocessResult.summary.detectedDeposits}
                  </p>
                </div>
                <div className="rounded border p-2 text-xs">
                  <p className="text-muted-foreground">Credited Deposits</p>
                  <p className="font-medium">
                    {manualReprocessResult.summary.creditedDeposits}
                  </p>
                </div>
              </div>
              <div className="space-y-2">
                {manualReprocessResult.networkResults.map((row) => (
                  <div
                    key={row.asset}
                    className="rounded border p-2 text-xs text-muted-foreground"
                  >
                    <div className="flex flex-wrap items-center gap-2">
                      <Badge variant="secondary">{row.asset}</Badge>
                      {boolBadge(row.matched, "Matched", "No Match")}
                      <span>Detected: {row.detectedCount}</span>
                      <span>Credited: {row.creditedCount}</span>
                    </div>
                    {row.reason ? <p className="mt-1">{row.reason}</p> : null}
                    {row.depositIds.length > 0 ? (
                      <p className="mt-1 break-all">
                        Deposit IDs: {row.depositIds.join(", ")}
                      </p>
                    ) : null}
                  </div>
                ))}
              </div>
            </div>
          ) : null}
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0">
          <CardTitle className="text-base">Wallet Health</CardTitle>
          <Button
            variant="outline"
            size="sm"
            onClick={() => void loadWalletHealth()}
            disabled={healthLoading}
          >
            {healthLoading ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <RefreshCw className="h-4 w-4" />
            )}
            Refresh
          </Button>
        </CardHeader>
        <CardContent className="space-y-4">
          {healthLoading ? (
            <LoadingSpinner className="py-6" />
          ) : healthError ? (
            <p className="text-sm text-destructive">{healthError}</p>
          ) : !walletHealth ? (
            <p className="text-sm text-muted-foreground">
              No wallet health data available.
            </p>
          ) : (
            <>
              <div className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
                <span>
                  Last check:{" "}
                  {new Date(walletHealth.timestamp).toLocaleString()}
                </span>
                {boolBadge(
                  walletHealth.flags.walletEnabled,
                  "Wallet On",
                  "Wallet Off",
                )}
                {boolBadge(
                  walletHealth.flags.depositsEnabled,
                  "Deposits On",
                  "Deposits Off",
                )}
                {boolBadge(
                  walletHealth.flags.withdrawalsEnabled,
                  "Withdrawals On",
                  "Withdrawals Off",
                )}
                <Badge variant="outline">
                  {walletHealth.flags.turnkeyExecutionMode}
                </Badge>
              </div>

              <div className="rounded-lg border p-3">
                <p className="text-sm font-medium">Turnkey Provider</p>
                <div className="mt-2 flex flex-wrap items-center gap-2 text-xs">
                  {boolBadge(
                    walletHealth.turnkey.connectivity.ok,
                    "Connected",
                    "Disconnected",
                  )}
                  {boolBadge(
                    walletHealth.turnkey.connectivity.simulated,
                    "Simulated",
                    "Live",
                  )}
                  {boolBadge(
                    walletHealth.turnkey.configured.organizationId,
                    "Org ID",
                    "Org Missing",
                  )}
                  {boolBadge(
                    walletHealth.turnkey.configured.apiPublicKey,
                    "Public Key",
                    "Public Missing",
                  )}
                  {boolBadge(
                    walletHealth.turnkey.configured.apiPrivateKey,
                    "Private Key",
                    "Private Missing",
                  )}
                  {boolBadge(
                    walletHealth.turnkey.configured.apiKeyId,
                    "API Key ID",
                    "API Key ID Missing",
                  )}
                </div>
                {walletHealth.turnkey.connectivity.error && (
                  <p className="mt-2 text-xs text-destructive">
                    {walletHealth.turnkey.connectivity.error}
                  </p>
                )}
              </div>

              <div className="grid gap-3 md:grid-cols-2">
                {walletHealth.networks.map((network) => (
                  <div
                    key={network.chainEnvironment}
                    className="rounded-lg border p-3"
                  >
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-medium">
                        {network.chainEnvironment.toUpperCase()} (Chain{" "}
                        {network.chainId})
                      </p>
                      {boolBadge(
                        network.rpcReachable,
                        "RPC Reachable",
                        "RPC Down",
                      )}
                    </div>
                    <div className="mt-2 space-y-1 text-xs text-muted-foreground">
                      <p>Latest block: {network.latestBlock ?? "n/a"}</p>
                      <p>
                        Deposit start block:{" "}
                        {network.depositStartBlock ?? "n/a"}
                      </p>
                      <p>
                        Confirmations required: {network.confirmationsRequired}
                      </p>
                      <p>
                        Token address configured:{" "}
                        {network.tokenAddressConfigured ? "yes" : "no"}
                      </p>
                      <p>
                        Treasury wallet ID configured:{" "}
                        {network.treasuryWalletIdConfigured ? "yes" : "no"}
                      </p>
                      <p>
                        Treasury sweep address configured:{" "}
                        {network.treasurySweepAddressConfigured ? "yes" : "no"}
                      </p>
                      {network.rpcError ? (
                        <p className="text-destructive">{network.rpcError}</p>
                      ) : null}
                    </div>
                  </div>
                ))}
              </div>

              <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
                {renderCountGroup(
                  "Wallets",
                  walletHealth.counts.walletsByStatus,
                )}
                {renderCountGroup(
                  "Deposits",
                  walletHealth.counts.depositsByStatus,
                )}
                {renderCountGroup(
                  "Sweeps",
                  walletHealth.counts.sweepJobsByStatus,
                )}
                {renderCountGroup(
                  "Withdrawals",
                  walletHealth.counts.withdrawalsByStatus,
                )}
              </div>
            </>
          )}
        </CardContent>
      </Card>

      {error && (
        <Card>
          <CardContent className="pt-6 text-sm text-destructive">
            {error}
          </CardContent>
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
                <p className="text-sm text-muted-foreground">
                  No risk tiers configured.
                </p>
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
                              onClick={() => void saveRisk(row.tier)}
                              disabled={
                                !canMutate || savingRiskTier === row.tier
                              }
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
                <p className="text-sm text-muted-foreground">
                  No fee configs configured.
                </p>
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
                              onClick={() => void saveFee(row.key)}
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

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Asset Price Fallbacks</CardTitle>
            </CardHeader>
            <CardContent>
              {loading ? (
                <LoadingSpinner className="py-10" />
              ) : assetPriceConfigs.length === 0 ? (
                <p className="text-sm text-muted-foreground">
                  No asset price configs configured.
                </p>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Asset</TableHead>
                      <TableHead>Provider ID</TableHead>
                      <TableHead>Fallback USD</TableHead>
                      <TableHead>Active</TableHead>
                      <TableHead className="w-[130px]" />
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {assetPriceConfigs.map((row) => {
                      const draft = assetPriceDrafts[row.asset];
                      if (!draft) return null;
                      return (
                        <TableRow key={row.id}>
                          <TableCell>
                            <Badge variant="secondary">{row.asset}</Badge>
                          </TableCell>
                          <TableCell>
                            <Input
                              value={draft.providerId}
                              onChange={(e) =>
                                setAssetPriceDrafts((prev) => ({
                                  ...prev,
                                  [row.asset]: {
                                    ...prev[row.asset],
                                    providerId: e.target.value,
                                  },
                                }))
                              }
                              placeholder="coingecko id"
                              disabled={!canMutate}
                            />
                          </TableCell>
                          <TableCell>
                            <Input
                              value={draft.fallbackUsdPrice}
                              onChange={(e) =>
                                setAssetPriceDrafts((prev) => ({
                                  ...prev,
                                  [row.asset]: {
                                    ...prev[row.asset],
                                    fallbackUsdPrice: e.target.value,
                                  },
                                }))
                              }
                              disabled={!canMutate}
                            />
                          </TableCell>
                          <TableCell>
                            <Select
                              value={draft.isActive ? "true" : "false"}
                              onValueChange={(next) =>
                                setAssetPriceDrafts((prev) => ({
                                  ...prev,
                                  [row.asset]: {
                                    ...prev[row.asset],
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
                              onClick={() => void saveAssetPrice(row.asset)}
                              disabled={
                                !canMutate || savingPriceAsset === row.asset
                              }
                            >
                              {savingPriceAsset === row.asset ? (
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
