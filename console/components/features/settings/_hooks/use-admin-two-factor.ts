"use client";

import { useEffect, useState } from "react";
import QRCode from "qrcode";
import axios from "axios";
import {
  clientApi,
  type AdminTwoFactorEnrollmentStartResponse, type AdminTwoFactorPolicy, type AdminTwoFactorPreflight,
} from "@/lib/api-client";

export function useAdminTwoFactor(isOwner: boolean) {
  const [twoFactorLoading, setTwoFactorLoading] = useState(true);
  const [twoFactorSaving, setTwoFactorSaving] = useState(false);
  const [twoFactorStatus, setTwoFactorStatus] = useState<string | null>(null);
  const [twoFactorPreflight, setTwoFactorPreflight] =
    useState<AdminTwoFactorPreflight | null>(null);
  const [twoFactorPolicy, setTwoFactorPolicy] =
    useState<AdminTwoFactorPolicy | null>(null);
  const [policyDraft, setPolicyDraft] = useState<"true" | "false">("false");
  const [enrollment, setEnrollment] =
    useState<AdminTwoFactorEnrollmentStartResponse | null>(null);
  const [confirmCode, setConfirmCode] = useState("");
  const [actionCode, setActionCode] = useState("");
  const [actionRecoveryCode, setActionRecoveryCode] = useState("");
  const [generatedRecoveryCodes, setGeneratedRecoveryCodes] = useState<
    string[]
  >([]);
  const [showManualSetup, setShowManualSetup] = useState(false);
  const [showAdvancedOtpUri, setShowAdvancedOtpUri] = useState(false);
  const [qrCodeDataUrl, setQrCodeDataUrl] = useState<string | null>(null);
  const [qrCodeError, setQrCodeError] = useState<string | null>(null);
  const [recoveryCopyStatus, setRecoveryCopyStatus] = useState<string | null>(
    null,
  );
  const [lastCopiedRecoveryCode, setLastCopiedRecoveryCode] = useState<
    string | null
  >(null);
  function resetEnrollmentArtifacts() {
    setShowManualSetup(false);
    setShowAdvancedOtpUri(false);
    setQrCodeDataUrl(null);
    setQrCodeError(null);
    setRecoveryCopyStatus(null);
    setLastCopiedRecoveryCode(null);
  }

  function resetActionCredentials() {
    setConfirmCode("");
    setActionCode("");
    setActionRecoveryCode("");
  }

  async function loadTwoFactorState() {
    setTwoFactorLoading(true);
    setTwoFactorStatus(null);
    try {
      const [preflight, policy] = await Promise.all([
        clientApi.getAdminTwoFactorPreflight(),
        clientApi.getAdminTwoFactorPolicy(),
      ]);
      setTwoFactorPreflight(preflight);
      setTwoFactorPolicy(policy);
      setPolicyDraft(policy.require2faForAdminPanel ? "true" : "false");
    } catch (error) {
      setTwoFactorPreflight(null);
      setTwoFactorPolicy(null);
      setTwoFactorStatus(
        error instanceof Error
          ? error.message
          : "Failed to load admin 2FA state",
      );
    } finally {
      setTwoFactorLoading(false);
    }
  }
  async function startEnrollment() {
    setTwoFactorSaving(true);
    setTwoFactorStatus(null);
    try {
      const payload = await clientApi.startAdminTwoFactorEnrollment();
      setEnrollment(payload);
      resetEnrollmentArtifacts();
      setGeneratedRecoveryCodes([]);
      resetActionCredentials();
      setTwoFactorStatus("Enrollment challenge started. Confirm to enable 2FA.");
    } catch (error) {
      setTwoFactorStatus(
        error instanceof Error ? error.message : "Failed to start enrollment",
      );
    } finally {
      setTwoFactorSaving(false);
    }
  }

  async function confirmEnrollment() {
    if (!confirmCode.trim()) {
      setTwoFactorStatus("Enter your 6-digit authenticator code.");
      return;
    }

    setTwoFactorSaving(true);
    setTwoFactorStatus(null);
    try {
      const payload = await clientApi.confirmAdminTwoFactorEnrollment({
        code: confirmCode.trim(),
      });
      await axios.post("/api/auth/2fa/session", {
        sessionToken: payload.sessionToken,
        expiresAt: payload.sessionExpiresAt,
      });
      setGeneratedRecoveryCodes(payload.recoveryCodes);
      setEnrollment(null);
      resetEnrollmentArtifacts();
      resetActionCredentials();
      setTwoFactorStatus(
        "Two-factor authentication enabled. Save your recovery codes now.",
      );
      await loadTwoFactorState();
    } catch (error) {
      setTwoFactorStatus(
        error instanceof Error
          ? error.message
          : "Failed to confirm enrollment",
      );
    } finally {
      setTwoFactorSaving(false);
    }
  }

  async function savePolicy() {
    if (!isOwner) {
      setTwoFactorStatus("Only owner can update 2FA policy.");
      return;
    }

    setTwoFactorSaving(true);
    setTwoFactorStatus(null);
    try {
      const updated = await clientApi.updateAdminTwoFactorPolicy({
        require2faForAdminPanel: policyDraft === "true",
      });
      setTwoFactorPolicy(updated);
      setTwoFactorStatus("Admin panel 2FA policy updated.");
      await loadTwoFactorState();
    } catch (error) {
      setTwoFactorStatus(
        error instanceof Error ? error.message : "Failed to update policy",
      );
    } finally {
      setTwoFactorSaving(false);
    }
  }

  async function regenerateRecoveryCodes() {
    setTwoFactorSaving(true);
    setTwoFactorStatus(null);
    try {
      const payload = await clientApi.regenerateAdminTwoFactorRecoveryCodes({
        code: actionCode.trim() || undefined,
        recoveryCode: actionRecoveryCode.trim() || undefined,
      });
      setGeneratedRecoveryCodes(payload.recoveryCodes);
      resetActionCredentials();
      setRecoveryCopyStatus(null);
      setLastCopiedRecoveryCode(null);
      setTwoFactorStatus("Recovery codes rotated.");
      await loadTwoFactorState();
    } catch (error) {
      setTwoFactorStatus(
        error instanceof Error
          ? error.message
          : "Failed to regenerate recovery codes",
      );
    } finally {
      setTwoFactorSaving(false);
    }
  }

  async function disableTwoFactor() {
    setTwoFactorSaving(true);
    setTwoFactorStatus(null);
    try {
      await clientApi.disableAdminTwoFactor({
        code: actionCode.trim() || undefined,
        recoveryCode: actionRecoveryCode.trim() || undefined,
      });
      await axios.post("/api/auth/2fa/clear");
      setGeneratedRecoveryCodes([]);
      setEnrollment(null);
      resetEnrollmentArtifacts();
      resetActionCredentials();
      setTwoFactorStatus("Two-factor authentication disabled.");
      await loadTwoFactorState();
    } catch (error) {
      setTwoFactorStatus(
        error instanceof Error ? error.message : "Failed to disable 2FA",
      );
    } finally {
      setTwoFactorSaving(false);
    }
  }

  async function copyToClipboard(
    value: string,
    successMessage: string,
    code?: string,
  ) {
    try {
      if (!navigator.clipboard) {
        throw new Error("Clipboard API unavailable");
      }
      await navigator.clipboard.writeText(value);
      setRecoveryCopyStatus(successMessage);
      setLastCopiedRecoveryCode(code ?? null);
    } catch {
      setRecoveryCopyStatus(null);
      setLastCopiedRecoveryCode(null);
      setTwoFactorStatus("Could not copy. Please copy manually.");
    }
  }

  async function copyAllRecoveryCodes() {
    if (generatedRecoveryCodes.length === 0) return;
    await copyToClipboard(
      generatedRecoveryCodes.join("\n"),
      "All recovery codes copied.",
    );
  }

  async function copyRecoveryCode(code: string) {
    await copyToClipboard(code, `Copied ${code}.`, code);
  }

  useEffect(() => {
    void loadTwoFactorState();
  }, []);
  useEffect(() => {
    let cancelled = false;

    const run = async () => {
      if (!enrollment?.otpAuthUrl) {
        setQrCodeDataUrl(null);
        setQrCodeError(null);
        return;
      }
      try {
        const dataUrl = await QRCode.toDataURL(enrollment.otpAuthUrl, {
          width: 220,
          margin: 1,
        });
        if (cancelled) return;
        setQrCodeDataUrl(dataUrl);
        setQrCodeError(null);
      } catch {
        if (cancelled) return;
        setQrCodeDataUrl(null);
        setQrCodeError("Could not render QR code. Use manual setup instead.");
      }
    };

    void run();
    return () => {
      cancelled = true;
    };
  }, [enrollment]);

  return {
    twoFactorLoading,
    twoFactorSaving,
    twoFactorStatus,
    twoFactorPreflight,
    twoFactorPolicy,
    policyDraft,
    setPolicyDraft,
    enrollment,
    confirmCode,
    setConfirmCode,
    actionCode,
    setActionCode,
    actionRecoveryCode,
    setActionRecoveryCode,
    generatedRecoveryCodes,
    showManualSetup,
    setShowManualSetup,
    showAdvancedOtpUri,
    setShowAdvancedOtpUri,
    qrCodeDataUrl,
    qrCodeError,
    recoveryCopyStatus,
    lastCopiedRecoveryCode,
    loadTwoFactorState,
    startEnrollment,
    confirmEnrollment,
    savePolicy,
    regenerateRecoveryCodes,
    disableTwoFactor,
    copyAllRecoveryCodes,
    copyRecoveryCode,
  };
}
