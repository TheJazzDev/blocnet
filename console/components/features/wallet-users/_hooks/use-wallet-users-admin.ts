"use client";

import { useEffect, useState } from "react";
import { clientApi, type AdminWalletUser } from "@/lib/api-client";
import type { KycStatusFilter, WalletStatusFilter } from "../_lib/wallet-users";

export function useWalletUsersAdmin() {
  const [rows, setRows] = useState<AdminWalletUser[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusSavingUserId, setStatusSavingUserId] = useState<string | null>(null);
  const [statusError, setStatusError] = useState<string | null>(null);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [pendingStatusAction, setPendingStatusAction] = useState<{
    userId: string;
    email: string;
    nextDisabled: boolean;
  } | null>(null);

  const [searchInput, setSearchInput] = useState("");
  const [q, setQ] = useState("");
  const [walletStatus, setWalletStatus] = useState<WalletStatusFilter>("all");
  const [kycStatus, setKycStatus] = useState<KycStatusFilter>("all");
  const [limit, setLimit] = useState(25);
  const [offset, setOffset] = useState(0);

  useEffect(() => {
    const timer = setTimeout(() => {
      setQ(searchInput.trim());
      setOffset(0);
    }, 300);
    return () => clearTimeout(timer);
  }, [searchInput]);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const result = await clientApi.listWalletUsers({
        q,
        walletStatus: walletStatus === "all" ? undefined : walletStatus,
        kycStatus: kycStatus === "all" ? undefined : kycStatus,
        limit,
        offset,
      });
      setRows(result.data);
      setTotal(result.total);
    } catch (err) {
      setRows([]);
      setTotal(0);
      setError(err instanceof Error ? err.message : "Failed to load wallet users");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
  }, [q, walletStatus, kycStatus, limit, offset]);

  async function updateWalletStatus(userId: string, disabled: boolean) {
    setStatusSavingUserId(userId);
    setStatusError(null);
    try {
      await clientApi.updateWalletUserStatus(userId, { disabled });
      await load();
    } catch (err) {
      setStatusError(err instanceof Error ? err.message : "Failed to update wallet status");
    } finally {
      setStatusSavingUserId(null);
    }
  }

  function openStatusConfirm(userId: string, email: string, nextDisabled: boolean) {
    setPendingStatusAction({ userId, email, nextDisabled });
    setConfirmOpen(true);
  }

  async function confirmStatusChange() {
    if (!pendingStatusAction) return;
    await updateWalletStatus(pendingStatusAction.userId, pendingStatusAction.nextDisabled);
    setConfirmOpen(false);
    setPendingStatusAction(null);
  }

  return {
    rows,
    total,
    loading,
    error,
    statusSavingUserId,
    statusError,
    confirmOpen,
    setConfirmOpen,
    pendingStatusAction,
    setPendingStatusAction,
    searchInput,
    setSearchInput,
    walletStatus,
    setWalletStatus,
    kycStatus,
    setKycStatus,
    limit,
    setLimit,
    offset,
    setOffset,
    load,
    openStatusConfirm,
    confirmStatusChange,
  };
}
