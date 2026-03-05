"use client";

import { useCallback, useEffect } from "react";
import { useWalletSettingsStore } from "@/lib/stores/wallet-settings-store";
import { clientApi } from "@/lib/api-client";

interface UseWalletSettingsOptions {
  autoLoad?: boolean;
}

/**
 * Hook to manage wallet settings
 */
export function useWalletSettings(options: UseWalletSettingsOptions = {}) {
  const { autoLoad = true } = options;

  const store = useWalletSettingsStore();
  const {
    setRuntimeConfig,
    setRiskLimits,
    setFeeConfigs,
    setAssetPriceConfigs,
    setLoadingRuntime,
    setLoadingRiskLimits,
    setLoadingFees,
    setLoadingPrices,
    setRuntimeError,
    setRiskLimitsError,
    setFeesError,
    setPricesError,
  } = store;

  const loadRuntimeConfig = useCallback(async () => {
    setLoadingRuntime(true);
    try {
      const data = await clientApi.getWalletRuntimeConfig();
      setRuntimeConfig(data);
    } catch (err) {
      setRuntimeError(
        err instanceof Error ? err.message : "Failed to load runtime config"
      );
    }
  }, [setRuntimeConfig, setLoadingRuntime, setRuntimeError]);

  const loadRiskLimits = useCallback(async () => {
    setLoadingRiskLimits(true);
    try {
      const data = await clientApi.listWalletRiskLimits();
      setRiskLimits(data);
    } catch (err) {
      setRiskLimitsError(
        err instanceof Error ? err.message : "Failed to load risk limits"
      );
    }
  }, [setRiskLimits, setLoadingRiskLimits, setRiskLimitsError]);

  const loadFeeConfigs = useCallback(async () => {
    setLoadingFees(true);
    try {
      const data = await clientApi.listWalletFeeConfigs();
      setFeeConfigs(data);
    } catch (err) {
      setFeesError(
        err instanceof Error ? err.message : "Failed to load fee configs"
      );
    }
  }, [setFeeConfigs, setLoadingFees, setFeesError]);

  const loadAssetPriceConfigs = useCallback(async () => {
    setLoadingPrices(true);
    try {
      const data = await clientApi.listWalletAssetPriceConfigs();
      setAssetPriceConfigs(data);
    } catch (err) {
      setPricesError(
        err instanceof Error ? err.message : "Failed to load asset price configs"
      );
    }
  }, [setAssetPriceConfigs, setLoadingPrices, setPricesError]);

  const loadAll = useCallback(async () => {
    await Promise.all([
      loadRuntimeConfig(),
      loadRiskLimits(),
      loadFeeConfigs(),
      loadAssetPriceConfigs(),
    ]);
  }, [loadRuntimeConfig, loadRiskLimits, loadFeeConfigs, loadAssetPriceConfigs]);

  useEffect(() => {
    if (autoLoad) {
      void loadAll();
    }
  }, [autoLoad, loadAll]);

  return {
    ...store,
    loadRuntimeConfig,
    loadRiskLimits,
    loadFeeConfigs,
    loadAssetPriceConfigs,
    loadAll,
    refresh: loadAll,
  };
}
