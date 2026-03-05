import { create } from "zustand";
import { devtools } from "zustand/middleware";
import type {
  WalletRuntimeConfig,
  WalletRiskLimit,
  WalletFeeConfig,
  WalletAssetPriceConfig,
} from "@/lib/api";

interface WalletSettingsState {
  // Data
  runtimeConfig: WalletRuntimeConfig | null;
  riskLimits: WalletRiskLimit[];
  feeConfigs: WalletFeeConfig[];
  assetPriceConfigs: WalletAssetPriceConfig[];

  // Loading states
  isLoadingRuntime: boolean;
  isLoadingRiskLimits: boolean;
  isLoadingFees: boolean;
  isLoadingPrices: boolean;

  // Errors
  runtimeError: string | null;
  riskLimitsError: string | null;
  feesError: string | null;
  pricesError: string | null;

  // Actions
  setRuntimeConfig: (config: WalletRuntimeConfig) => void;
  setRiskLimits: (limits: WalletRiskLimit[]) => void;
  setFeeConfigs: (configs: WalletFeeConfig[]) => void;
  setAssetPriceConfigs: (configs: WalletAssetPriceConfig[]) => void;

  setLoadingRuntime: (loading: boolean) => void;
  setLoadingRiskLimits: (loading: boolean) => void;
  setLoadingFees: (loading: boolean) => void;
  setLoadingPrices: (loading: boolean) => void;

  setRuntimeError: (error: string | null) => void;
  setRiskLimitsError: (error: string | null) => void;
  setFeesError: (error: string | null) => void;
  setPricesError: (error: string | null) => void;

  reset: () => void;
}

const initialState = {
  runtimeConfig: null,
  riskLimits: [],
  feeConfigs: [],
  assetPriceConfigs: [],
  isLoadingRuntime: false,
  isLoadingRiskLimits: false,
  isLoadingFees: false,
  isLoadingPrices: false,
  runtimeError: null,
  riskLimitsError: null,
  feesError: null,
  pricesError: null,
};

export const useWalletSettingsStore = create<WalletSettingsState>()(
  devtools(
    (set) => ({
      ...initialState,

      setRuntimeConfig: (runtimeConfig) =>
        set({ runtimeConfig, runtimeError: null, isLoadingRuntime: false }),

      setRiskLimits: (riskLimits) =>
        set({ riskLimits, riskLimitsError: null, isLoadingRiskLimits: false }),

      setFeeConfigs: (feeConfigs) =>
        set({ feeConfigs, feesError: null, isLoadingFees: false }),

      setAssetPriceConfigs: (assetPriceConfigs) =>
        set({ assetPriceConfigs, pricesError: null, isLoadingPrices: false }),

      setLoadingRuntime: (isLoadingRuntime) => set({ isLoadingRuntime }),

      setLoadingRiskLimits: (isLoadingRiskLimits) => set({ isLoadingRiskLimits }),

      setLoadingFees: (isLoadingFees) => set({ isLoadingFees }),

      setLoadingPrices: (isLoadingPrices) => set({ isLoadingPrices }),

      setRuntimeError: (runtimeError) =>
        set({ runtimeError, isLoadingRuntime: false }),

      setRiskLimitsError: (riskLimitsError) =>
        set({ riskLimitsError, isLoadingRiskLimits: false }),

      setFeesError: (feesError) => set({ feesError, isLoadingFees: false }),

      setPricesError: (pricesError) =>
        set({ pricesError, isLoadingPrices: false }),

      reset: () => set(initialState),
    }),
    { name: "wallet-settings-store" }
  )
);
