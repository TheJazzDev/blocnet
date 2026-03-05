"use client";

import { useEffect, useState } from "react";
import { clientApi, type AdminWalletKycRecord } from "@/lib/api-client";
import type { ReviewStatus, StatusFilter } from "../_lib/wallet-kyc";

export function useWalletKycAdmin() {
  const [rows, setRows] = useState<AdminWalletKycRecord[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [searchInput, setSearchInput] = useState("");
  const [q, setQ] = useState("");
  const [status, setStatus] = useState<StatusFilter>("all");
  const [limit, setLimit] = useState(25);
  const [offset, setOffset] = useState(0);

  const [dialogOpen, setDialogOpen] = useState(false);
  const [selected, setSelected] = useState<AdminWalletKycRecord | null>(null);
  const [reviewStatus, setReviewStatus] = useState<ReviewStatus>("approved");
  const [tier, setTier] = useState("verified");
  const [note, setNote] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [dialogError, setDialogError] = useState<string | null>(null);

  useEffect(() => {
    const timer = setTimeout(() => {
      setQ(searchInput.trim());
      setOffset(0);
    }, 300);
    return () => clearTimeout(timer);
  }, [searchInput]);

  function load() {
    setLoading(true);
    setError(null);
    clientApi
      .listWalletKyc({
        q,
        status: status === "all" ? undefined : status,
        limit,
        offset,
      })
      .then((result) => {
        setRows(result.data);
        setTotal(result.total);
      })
      .catch((err) => {
        setRows([]);
        setTotal(0);
        setError(err instanceof Error ? err.message : "Failed to load KYC records");
      })
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
  }, [q, status, limit, offset]);

  function openReview(row: AdminWalletKycRecord, nextStatus: ReviewStatus) {
    setSelected(row);
    setReviewStatus(nextStatus);
    setTier(row.tier || "verified");
    setNote("");
    setDialogError(null);
    setDialogOpen(true);
  }

  async function submitReview() {
    if (!selected) return;
    const trimmed = note.trim();
    if (trimmed.length < 3) {
      setDialogError("Review note must be at least 3 characters.");
      return;
    }

    setSubmitting(true);
    setDialogError(null);
    try {
      await clientApi.reviewWalletKyc(selected.userId, {
        status: reviewStatus,
        note: trimmed,
        ...(reviewStatus === "approved" ? { tier } : {}),
      });
      setDialogOpen(false);
      await load();
    } catch (err) {
      setDialogError(err instanceof Error ? err.message : "Failed to review KYC");
    } finally {
      setSubmitting(false);
    }
  }

  return {
    rows,
    total,
    loading,
    error,
    searchInput,
    setSearchInput,
    status,
    setStatus,
    limit,
    setLimit,
    offset,
    setOffset,
    dialogOpen,
    setDialogOpen,
    selected,
    reviewStatus,
    setReviewStatus,
    tier,
    setTier,
    note,
    setNote,
    submitting,
    dialogError,
    openReview,
    submitReview,
  };
}
