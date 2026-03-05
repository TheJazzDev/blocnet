"use client";

import { useEffect, useState } from "react";
import {
  apiFetch,
  clientApi,
  type AdminMiningConfig,
  type AdminMiningMetrics,
} from "@/lib/api-client";

export function useMiningAdmin() {
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
  const [supportReferralLookup, setSupportReferralLookup] = useState<{
    loading: boolean;
    valid: boolean;
    ownerEmail: string | null;
    ownerName: string | null;
    ownerId: string | null;
  }>({
    loading: false,
    valid: false,
    ownerEmail: null,
    ownerName: null,
    ownerId: null,
  });

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
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load mining settings");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
  }, []);

  useEffect(() => {
    const code = supportReferralCode.trim().toUpperCase();
    if (!code || !/^[A-Z0-9]{8}$/.test(code)) {
      setSupportReferralLookup({
        loading: false,
        valid: false,
        ownerEmail: null,
        ownerName: null,
        ownerId: null,
      });
      return;
    }

    const timer = setTimeout(async () => {
      setSupportReferralLookup((prev) => ({ ...prev, loading: true }));
      try {
        const result = await apiFetch<{
          valid: boolean;
          referrer: { id: string; email: string | null; displayName: string | null } | null;
        }>(`/referrals/validate?code=${encodeURIComponent(code)}`);
        setSupportReferralLookup({
          loading: false,
          valid: result.valid,
          ownerEmail: result.referrer?.email ?? null,
          ownerName: result.referrer?.displayName ?? null,
          ownerId: result.referrer?.id ?? null,
        });
      } catch {
        setSupportReferralLookup({
          loading: false,
          valid: false,
          ownerEmail: null,
          ownerName: null,
          ownerId: null,
        });
      }
    }, 250);

    return () => clearTimeout(timer);
  }, [supportReferralCode]);

  async function save() {
    if (!config) return;
    setSaving(true);
    setError(null);
    try {
      const next = await clientApi.updateMiningConfig(config);
      setConfig(next);
      setMetrics(await clientApi.getMiningMetrics());
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save mining settings");
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
      setMetrics(await clientApi.getMiningMetrics());
    } catch (err) {
      setSupportError(
        err instanceof Error ? err.message : "Failed to bind referral for user",
      );
    } finally {
      setSupportSaving(false);
    }
  }

  return {
    config,
    setConfig,
    metrics,
    loading,
    saving,
    error,
    supportUserIdOrEmail,
    setSupportUserIdOrEmail,
    supportReferralCode,
    setSupportReferralCode,
    supportSaving,
    supportError,
    supportSuccess,
    supportReferralLookup,
    load,
    save,
    bindReferralBySupport,
  };
}
