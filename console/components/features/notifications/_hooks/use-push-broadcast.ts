"use client";

import { FormEvent, useState } from "react";
import { clientApi } from "@/lib/api-client";

export type BroadcastTarget = "all" | "hunters" | "users" | "specific";

export interface SelectedUser {
  id: string;
  displayName: string | null;
  email: string;
}

export interface BroadcastResult {
  insertedCount: number;
  sentCount: number;
  failureCount: number;
  recipientCount: number;
  skipped: boolean;
  skipReason?: string | null;
}

export const TARGET_OPTIONS: {
  value: BroadcastTarget;
  label: string;
  description: string;
}[] = [
  { value: "all", label: "All Users", description: "Every registered user" },
  {
    value: "hunters",
    label: "Hunters & Admins",
    description: "Users with hunter, admin, or owner role",
  },
  {
    value: "users",
    label: "Regular Users",
    description: "Users with only the base user role",
  },
  {
    value: "specific",
    label: "Specific People",
    description: "Search and pick individual users",
  },
];

export function usePushBroadcast(canSend: boolean) {
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [target, setTarget] = useState<BroadcastTarget>("all");
  const [selectedUsers, setSelectedUsers] = useState<SelectedUser[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState<SelectedUser[]>([]);
  const [searching, setSearching] = useState(false);
  const [searched, setSearched] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [sending, setSending] = useState(false);
  const [result, setResult] = useState<BroadcastResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function handleSearch(q?: string) {
    const query = (q ?? searchQuery).trim();
    if (query.length < 2) return;
    setSearching(true);
    setSearched(false);
    try {
      const res = await clientApi.listUsers({ q: query, limit: 10 });
      setSearchResults(
        (res.data ?? []).map((user) => ({
          id: user.id,
          displayName: user.displayName ?? null,
          email: user.email,
        })),
      );
    } catch {
      setSearchResults([]);
    } finally {
      setSearching(false);
      setSearched(true);
    }
  }

  function addUser(user: SelectedUser) {
    if (!selectedUsers.find((entry) => entry.id === user.id)) {
      setSelectedUsers((prev) => [...prev, user]);
    }
    setSearchQuery("");
    setSearchResults([]);
    setSearched(false);
  }

  function removeUser(id: string) {
    setSelectedUsers((prev) => prev.filter((user) => user.id !== id));
  }

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (!canSend || !title.trim() || !body.trim()) return;
    if (target === "specific" && selectedUsers.length === 0) return;
    setError(null);
    setResult(null);
    setConfirmOpen(true);
  }

  async function confirmSend() {
    setSending(true);
    setError(null);
    try {
      const payload = await clientApi.broadcastNotification({
        title: title.trim(),
        body: body.trim(),
        target,
        userIds:
          target === "specific" ? selectedUsers.map((user) => user.id) : undefined,
      });
      setResult(payload);
      setTitle("");
      setBody("");
      setSelectedUsers([]);
      setTarget("all");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to send notification");
    } finally {
      setSending(false);
      setConfirmOpen(false);
    }
  }

  const selectedTargetOption = TARGET_OPTIONS.find((opt) => opt.value === target)!;

  return {
    title,
    setTitle,
    body,
    setBody,
    target,
    setTarget,
    selectedUsers,
    searchQuery,
    setSearchQuery,
    searchResults,
    searching,
    searched,
    confirmOpen,
    setConfirmOpen,
    sending,
    result,
    error,
    selectedTargetOption,
    handleSearch,
    addUser,
    removeUser,
    handleSubmit,
    confirmSend,
    resetSearch() {
      setSearched(false);
      setSearchResults([]);
    },
  };
}
