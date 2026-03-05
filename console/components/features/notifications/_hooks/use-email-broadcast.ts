"use client";

import { FormEvent, useEffect, useState } from "react";
import { clientApi } from "@/lib/api-client";
import {
  TARGET_OPTIONS,
  type BroadcastTarget,
  type SelectedUser,
} from "./use-push-broadcast";

interface EmailStatus {
  configured: boolean;
  reason: string | null;
  defaultFromAddress: string;
  defaultFromName: string;
  adminFromAddress: string;
  adminFromName: string;
  allowedFromAddresses: string[];
  replyTo: string | null;
  broadcastRatePerMinute: number;
}

interface EmailBroadcastResult {
  recipientCount: number;
  delivered: number;
  failed: number;
  skipped: number;
  skippedReason: string | null;
  estimatedRatePerMinute: number;
}

export function useEmailBroadcast(canSend: boolean) {
  const [emailStatus, setEmailStatus] = useState<EmailStatus | null>(null);
  const [emailSubject, setEmailSubject] = useState("");
  const [emailPreviewText, setEmailPreviewText] = useState("");
  const [emailMessage, setEmailMessage] = useState("");
  const [emailFromAddress, setEmailFromAddress] = useState("");
  const [emailFromName, setEmailFromName] = useState("");
  const [emailReplyTo, setEmailReplyTo] = useState("");
  const [emailCtaLabel, setEmailCtaLabel] = useState("Open Blocnet App");
  const [emailCtaUrl, setEmailCtaUrl] = useState(
    "https://blocnet.app/notifications",
  );
  const [emailTarget, setEmailTarget] = useState<BroadcastTarget>("all");
  const [emailSelectedUsers, setEmailSelectedUsers] = useState<SelectedUser[]>([]);
  const [emailSearchQuery, setEmailSearchQuery] = useState("");
  const [emailSearchResults, setEmailSearchResults] = useState<SelectedUser[]>([]);
  const [emailSearching, setEmailSearching] = useState(false);
  const [emailSearched, setEmailSearched] = useState(false);
  const [emailConfirmOpen, setEmailConfirmOpen] = useState(false);
  const [emailSending, setEmailSending] = useState(false);
  const [emailResult, setEmailResult] = useState<EmailBroadcastResult | null>(null);
  const [emailError, setEmailError] = useState<string | null>(null);

  useEffect(() => {
    if (!canSend) return;
    let cancelled = false;

    async function loadEmailStatus() {
      try {
        const status = await clientApi.getNotificationEmailStatus();
        if (cancelled) return;
        setEmailStatus(status);
        setEmailFromAddress(
          (prev) => prev || status.adminFromAddress || status.defaultFromAddress || "",
        );
        setEmailFromName(
          (prev) => prev || status.adminFromName || status.defaultFromName || "",
        );
        setEmailReplyTo((prev) => prev || status.replyTo || "");
      } catch (error) {
        if (!cancelled) {
          setEmailError(
            error instanceof Error ? error.message : "Failed to load email settings",
          );
        }
      }
    }

    void loadEmailStatus();
    return () => {
      cancelled = true;
    };
  }, [canSend]);

  async function handleEmailSearch(q?: string) {
    const query = (q ?? emailSearchQuery).trim();
    if (query.length < 2) return;
    setEmailSearching(true);
    setEmailSearched(false);
    try {
      const res = await clientApi.listUsers({ q: query, limit: 10 });
      setEmailSearchResults(
        (res.data ?? []).map((user) => ({
          id: user.id,
          displayName: user.displayName ?? null,
          email: user.email,
        })),
      );
    } catch {
      setEmailSearchResults([]);
    } finally {
      setEmailSearching(false);
      setEmailSearched(true);
    }
  }

  function addEmailUser(user: SelectedUser) {
    if (!emailSelectedUsers.find((entry) => entry.id === user.id)) {
      setEmailSelectedUsers((prev) => [...prev, user]);
    }
    setEmailSearchQuery("");
    setEmailSearchResults([]);
    setEmailSearched(false);
  }

  function removeEmailUser(id: string) {
    setEmailSelectedUsers((prev) => prev.filter((user) => user.id !== id));
  }

  function handleEmailSubmit(e: FormEvent) {
    e.preventDefault();
    if (!canSend || !emailSubject.trim() || !emailMessage.trim()) return;
    if (emailTarget === "specific" && emailSelectedUsers.length === 0) return;
    setEmailError(null);
    setEmailResult(null);
    setEmailConfirmOpen(true);
  }

  async function confirmEmailSend() {
    setEmailSending(true);
    setEmailError(null);
    try {
      const payload = await clientApi.broadcastEmail({
        subject: emailSubject.trim(),
        message: emailMessage.trim(),
        target: emailTarget,
        userIds:
          emailTarget === "specific"
            ? emailSelectedUsers.map((user) => user.id)
            : undefined,
        previewText: emailPreviewText.trim() || undefined,
        fromAddress: emailFromAddress.trim() || undefined,
        fromName: emailFromName.trim() || undefined,
        replyTo: emailReplyTo.trim() || undefined,
        ctaLabel: emailCtaLabel.trim() || undefined,
        ctaUrl: emailCtaUrl.trim() || undefined,
      });
      setEmailResult(payload);
      setEmailSubject("");
      setEmailPreviewText("");
      setEmailMessage("");
      setEmailTarget("all");
      setEmailSelectedUsers([]);
      setEmailCtaLabel("Open Blocnet App");
      setEmailCtaUrl("https://blocnet.app/notifications");
    } catch (error) {
      setEmailError(
        error instanceof Error ? error.message : "Failed to send email broadcast",
      );
    } finally {
      setEmailSending(false);
      setEmailConfirmOpen(false);
    }
  }

  const selectedEmailTargetOption = TARGET_OPTIONS.find(
    (option) => option.value === emailTarget,
  )!;

  return {
    emailStatus,
    emailSubject,
    setEmailSubject,
    emailPreviewText,
    setEmailPreviewText,
    emailMessage,
    setEmailMessage,
    emailFromAddress,
    setEmailFromAddress,
    emailFromName,
    setEmailFromName,
    emailReplyTo,
    setEmailReplyTo,
    emailCtaLabel,
    setEmailCtaLabel,
    emailCtaUrl,
    setEmailCtaUrl,
    emailTarget,
    setEmailTarget,
    emailSelectedUsers,
    emailSearchQuery,
    setEmailSearchQuery,
    emailSearchResults,
    emailSearching,
    emailSearched,
    emailConfirmOpen,
    setEmailConfirmOpen,
    emailSending,
    emailResult,
    emailError,
    selectedEmailTargetOption,
    handleEmailSearch,
    addEmailUser,
    removeEmailUser,
    handleEmailSubmit,
    confirmEmailSend,
    resetSearch() {
      setEmailSearched(false);
      setEmailSearchResults([]);
    },
  };
}
