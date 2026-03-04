"use client";

import { useEffect, useMemo, useState } from "react";
import {
  clientApi, type AdminWalletDepositReprocessResponse, type AdminWalletHealth, type WalletAssetCode, type WalletAssetPriceConfig, type WalletFeeConfig, type WalletRiskLimit, type WalletRuntimeConfig,
} from "@/lib/api-client";
import {
  type AssetPriceDraft, buildAssetPriceDrafts, buildFeeDrafts, buildRiskDrafts, formatManualReprocessStatus, type FeeDraft, type RiskDraft, toRuntimeConfigPayload,
} from "./wallet-settings-utils";

export function useWalletSettings() {
  const [riskLimits, setRiskLimits] = useState<WalletRiskLimit[]>([]);
  const [feeConfigs, setFeeConfigs] = useState<WalletFeeConfig[]>([]);
  const [assetPriceConfigs, setAssetPriceConfigs] = useState<WalletAssetPriceConfig[]>([]);
  const [runtimeConfig, setRuntimeConfig] = useState<WalletRuntimeConfig | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [walletHealth, setWalletHealth] = useState<AdminWalletHealth | null>(null);
  const [healthLoading, setHealthLoading] = useState(true);
  const [healthError, setHealthError] = useState<string | null>(null);
  const [savingRiskTier, setSavingRiskTier] = useState<string | null>(null);
  const [savingFeeKey, setSavingFeeKey] = useState<string | null>(null);
  const [savingPriceAsset, setSavingPriceAsset] = useState<WalletAssetCode | null>(null);
  const [savingRuntimeConfig, setSavingRuntimeConfig] = useState(false);
  const [runtimeStatus, setRuntimeStatus] = useState<string | null>(null);
  const [manualTxHash, setManualTxHash] = useState("");
  const [manualChainEnvironment, setManualChainEnvironment] = useState<
    "testnet" | "mainnet"
  >("testnet");
  const [manualAsset, setManualAsset] = useState<"all" | WalletAssetCode>("all");
  const [manualReprocessLoading, setManualReprocessLoading] = useState(false);
  const [manualReprocessStatus, setManualReprocessStatus] = useState<string | null>(null);
  const [manualReprocessResult, setManualReprocessResult] =
    useState<AdminWalletDepositReprocessResponse | null>(null);
  const [riskDrafts, setRiskDrafts] = useState<Record<string, RiskDraft>>({});
  const [feeDrafts, setFeeDrafts] = useState<Record<string, FeeDraft>>({});
  const [assetPriceDrafts, setAssetPriceDrafts] = useState<Record<string, AssetPriceDraft>>(
    {},
  );

  async function loadWalletHealth() {
    setHealthLoading(true);
    setHealthError(null);
    try {
      const result = await clientApi.getWalletHealth();
      setWalletHealth(result);
    } catch (err) {
      setWalletHealth(null);
      setHealthError(err instanceof Error ? err.message : "Failed to load wallet health");
    } finally {
      setHealthLoading(false);
    }
  }

  async function loadSettings() {
    setLoading(true);
    setError(null);
    try {
      const [riskResult, feesResult, pricesResult, runtimeResult] = await Promise.allSettled([
        clientApi.listWalletRiskLimits(),
        clientApi.listWalletFeeConfigs(),
        clientApi.listWalletAssetPriceConfigs(),
        clientApi.getWalletRuntimeConfig(),
      ]);

      const risk = riskResult.status === "fulfilled" ? riskResult.value : [];
      const fees = feesResult.status === "fulfilled" ? feesResult.value : [];
      const prices = pricesResult.status === "fulfilled" ? pricesResult.value : [];
      const runtime = runtimeResult.status === "fulfilled" ? runtimeResult.value : null;

      setRiskLimits(risk);
      setFeeConfigs(fees);
      setAssetPriceConfigs(prices);
      setRuntimeConfig(runtime);
      setRiskDrafts(buildRiskDrafts(risk));
      setFeeDrafts(buildFeeDrafts(fees));
      setAssetPriceDrafts(buildAssetPriceDrafts(prices));

      const failures: string[] = [];
      if (riskResult.status === "rejected") failures.push("risk limits");
      if (feesResult.status === "rejected") failures.push("fee configs");
      if (pricesResult.status === "rejected") failures.push("asset price configs");
      if (runtimeResult.status === "rejected") failures.push("runtime config");
      if (failures.length > 0) {
        setError(
          `Some wallet settings failed to load (${failures.join(", ")}). Check backend/database connectivity.`,
        );
      }
    } catch (err) {
      setRiskLimits([]);
      setFeeConfigs([]);
      setAssetPriceConfigs([]);
      setRuntimeConfig(null);
      setError(err instanceof Error ? err.message : "Failed to load wallet settings");
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
    if (availableChainEnvironments.includes(manualChainEnvironment)) return;
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
      if (hasAsset && prev.withdrawalEnabledAssets.length === 1) return prev;
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
      const updated = await clientApi.updateWalletRuntimeConfig(
        toRuntimeConfigPayload(runtimeConfig),
      );
      setRuntimeConfig(updated);
      setRuntimeStatus("Runtime config saved and applied.");
      await loadWalletHealth();
    } catch (err) {
      setRuntimeStatus(err instanceof Error ? err.message : "Failed to save runtime config");
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
      setManualReprocessStatus(formatManualReprocessStatus(result));
      await loadWalletHealth();
    } catch (err) {
      setManualReprocessStatus(
        err instanceof Error ? err.message : "Failed to reprocess the transaction hash.",
      );
    } finally {
      setManualReprocessLoading(false);
    }
  }

  return {
    riskLimits,
    feeConfigs,
    assetPriceConfigs,
    runtimeConfig,
    setRuntimeConfig,
    loading,
    error,
    walletHealth,
    healthLoading,
    healthError,
    savingRiskTier,
    savingFeeKey,
    savingPriceAsset,
    savingRuntimeConfig,
    runtimeStatus,
    manualTxHash,
    setManualTxHash,
    manualChainEnvironment,
    setManualChainEnvironment,
    manualAsset,
    setManualAsset,
    manualReprocessLoading,
    manualReprocessStatus,
    manualReprocessResult,
    riskDrafts,
    feeDrafts,
    assetPriceDrafts,
    availableChainEnvironments,
    hasData,
    loadWalletHealth,
    saveRisk,
    saveFee,
    saveAssetPrice,
    toggleWithdrawalAsset,
    saveRuntime,
    runManualDepositReprocess,
    onRiskDraftChange(tier: string, draft: Partial<RiskDraft>) {
      setRiskDrafts((prev) => ({
        ...prev,
        [tier]: { ...prev[tier], ...draft },
      }));
    },
    onFeeDraftChange(key: string, draft: Partial<FeeDraft>) {
      setFeeDrafts((prev) => ({
        ...prev,
        [key]: { ...prev[key], ...draft },
      }));
    },
    onAssetPriceDraftChange(asset: WalletAssetCode, draft: Partial<AssetPriceDraft>) {
      setAssetPriceDrafts((prev) => ({
        ...prev,
        [asset]: { ...prev[asset], ...draft },
      }));
    },
  };
}
