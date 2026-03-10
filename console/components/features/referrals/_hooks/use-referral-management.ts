"use client";

import { useEffect, useState } from "react";
import {
  apiFetch,
  clientApi,
  type AdminMiningMetrics,
} from "@/lib/api-client";

export function useReferralManagement() {
  const [userIdOrEmail, setUserIdOrEmail] = useState("");
  const [referralCode, setReferralCode] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [referralLookup, setReferralLookup] = useState<{
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

  const [metrics, setMetrics] = useState<AdminMiningMetrics | null>(null);
  const [metricsLoading, setMetricsLoading] = useState(true);
  const [metricsError, setMetricsError] = useState<string | null>(null);

  // Validate referral code as user types
  useEffect(() => {
    const code = referralCode.trim().toUpperCase();
    if (!code || !/^[A-Z0-9]{8}$/.test(code)) {
      setReferralLookup({
        loading: false,
        valid: false,
        ownerEmail: null,
        ownerName: null,
        ownerId: null,
      });
      return;
    }

    const timer = setTimeout(async () => {
      setReferralLookup((prev) => ({ ...prev, loading: true }));
      try {
        const result = await apiFetch<{
          valid: boolean;
          referrer: { id: string; email: string | null; displayName: string | null } | null;
        }>(`/referrals/validate?code=${encodeURIComponent(code)}`);
        setReferralLookup({
          loading: false,
          valid: result.valid,
          ownerEmail: result.referrer?.email ?? null,
          ownerName: result.referrer?.displayName ?? null,
          ownerId: result.referrer?.id ?? null,
        });
      } catch {
        setReferralLookup({
          loading: false,
          valid: false,
          ownerEmail: null,
          ownerName: null,
          ownerId: null,
        });
      }
    }, 300);

    return () => clearTimeout(timer);
  }, [referralCode]);

  // Load metrics on mount
  useEffect(() => {
    void loadMetrics();
  }, []);

  async function loadMetrics() {
    setMetricsLoading(true);
    setMetricsError(null);
    try {
      const m = await clientApi.getMiningMetrics();
      setMetrics(m);
    } catch (err) {
      setMetricsError(err instanceof Error ? err.message : "Failed to load metrics");
    } finally {
      setMetricsLoading(false);
    }
  }

  async function bindReferral() {
    if (!userIdOrEmail.trim()) {
      setError("Enter a user ID or email.");
      setSuccess(null);
      return;
    }
    if (!referralCode.trim()) {
      setError("Enter a referral code.");
      setSuccess(null);
      return;
    }

    setSaving(true);
    setError(null);
    setSuccess(null);
    try {
      const result = await clientApi.adminBindReferral({
        userIdOrEmail: userIdOrEmail.trim(),
        code: referralCode.trim().toUpperCase(),
      });
      setSuccess(
        `Successfully bound ${result.targetUser.email} to referral code ${result.referrer.code ?? "UNKNOWN"} (owner: ${result.referrer.email}).`,
      );
      setUserIdOrEmail("");
      setReferralCode("");
      // Refresh metrics after successful binding
      await loadMetrics();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to bind referral for user",
      );
    } finally {
      setSaving(false);
    }
  }

  return {
    userIdOrEmail,
    setUserIdOrEmail,
    referralCode,
    setReferralCode,
    saving,
    error,
    success,
    referralLookup,
    bindReferral,
    metrics,
    metricsLoading,
    metricsError,
    loadMetrics,
  };
}
