"use client";

import { useCallback, useEffect } from "react";
import { useTipSettingsStore } from "@/lib/stores/tip-settings-store";
import { clientApi } from "@/lib/api-client";

interface UseTipSettingsOptions {
  autoLoad?: boolean;
}

/**
 * Hook to manage tip settings
 */
export function useTipSettings(options: UseTipSettingsOptions = {}) {
  const { autoLoad = true } = options;

  const store = useTipSettingsStore();
  const { settings, isLoading, error, setSettings, setLoading, setError } = store;

  const loadSettings = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const data = await clientApi.getTipSettings();
      setSettings(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load tip settings");
    }
  }, [setSettings, setLoading, setError]);

  useEffect(() => {
    if (autoLoad) {
      void loadSettings();
    }
  }, [autoLoad, loadSettings]);

  return {
    ...store,
    loadSettings,
    refresh: loadSettings,
  };
}
