"use client";

import { useEffect, useMemo, useState } from "react";
import { clientApi, type AdminTipSettings } from "@/lib/api-client";
import { toDrafts, type CurrencyDraft } from "../_lib/tip-settings";

export function useTipSettings() {
  const [settings, setSettings] = useState<AdminTipSettings | null>(null);
  const [drafts, setDrafts] = useState<Record<string, CurrencyDraft>>({});
  const [activeCurrencyCode, setActiveCurrencyCode] = useState<string>("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [savingCode, setSavingCode] = useState<string | null>(null);
  const [activating, setActivating] = useState(false);

  const currencies = useMemo(() => settings?.currencies ?? [], [settings]);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const next = await clientApi.getTipSettings();
      setSettings(next);
      setDrafts(toDrafts(next));
      setActiveCurrencyCode(next.activeCurrencyCode ?? next.currencies[0]?.code ?? "");
    } catch (err) {
      setSettings(null);
      setDrafts({});
      setError(err instanceof Error ? err.message : "Failed to load tip settings");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
  }, []);

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
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save tip currency settings");
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
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to activate tip currency");
    } finally {
      setActivating(false);
    }
  }

  function updateDraft(code: string, patch: Partial<CurrencyDraft>) {
    setDrafts((prev) => ({
      ...prev,
      [code]: { ...prev[code], ...patch },
    }));
  }

  return {
    settings,
    drafts,
    currencies,
    activeCurrencyCode,
    setActiveCurrencyCode,
    loading,
    error,
    savingCode,
    activating,
    load,
    saveCurrency,
    activateCurrency,
    updateDraft,
  };
}
