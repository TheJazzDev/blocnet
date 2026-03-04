"use client";

import { useState } from "react";
import { type AdminUpdate, type UpdateStatus } from "@/lib/api-client";
import { useUpdatesQuery, useModerateUpdateMutation } from "@/lib/hooks/queries";
import { useDebounce } from "@/lib/hooks";
import type { StatusFilter } from "../_lib/updates-admin";

export function useUpdatesAdmin() {
  const [searchInput, setSearchInput] = useState("");
  const [status, setStatus] = useState<StatusFilter>("all");
  const [limit, setLimit] = useState(25);
  const [offset, setOffset] = useState(0);

  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedUpdate, setSelectedUpdate] = useState<AdminUpdate | null>(null);
  const [targetStatus, setTargetStatus] = useState<UpdateStatus>("published");

  // Debounce search input
  const q = useDebounce(searchInput.trim(), 300);

  // TanStack Query hook
  const { data: updates = [], isLoading, error } = useUpdatesQuery({
    q: q || undefined,
    status: status === "all" ? undefined : (status as UpdateStatus),
    limit,
    offset,
  });

  // Mutation hook
  const moderateMutation = useModerateUpdateMutation();

  function openModeration(update: AdminUpdate, nextStatus: UpdateStatus) {
    setSelectedUpdate(update);
    setTargetStatus(nextStatus);
    setDialogOpen(true);
  }

  async function submitModeration(nextStatus: UpdateStatus, reason: string) {
    if (!selectedUpdate) return;

    await moderateMutation.mutateAsync({
      updateId: selectedUpdate.id,
      status: nextStatus,
      reason,
    });
  }

  return {
    updates,
    setUpdates: () => {}, // Keep for compatibility, but not used
    loading: isLoading,
    error: error ? (error instanceof Error ? error.message : "Failed to load updates") : null,
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
    selectedUpdate,
    targetStatus,
    openModeration,
    submitModeration,
  };
}
