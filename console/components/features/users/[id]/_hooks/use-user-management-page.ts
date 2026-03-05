"use client";

import { useEffect, useMemo, useState } from "react";
import { apiFetch, clientApi, type AdminUserDetail } from "@/lib/api-client";

type AdminBadgeModel = {
  id: string;
  slug: string;
  name: string;
  isActive: boolean;
};

type SessionInput = {
  id: string;
  effectiveRoles: string[];
  realRoles: string[];
};

export function useUserManagementPage(userId: string, session: SessionInput) {
  const [user, setUser] = useState<AdminUserDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [pendingConfirmation, setPendingConfirmation] = useState<{
    key: string;
    confirmText: string;
    submit: () => Promise<unknown>;
  } | null>(null);
  const [allBadges, setAllBadges] = useState<AdminBadgeModel[]>([]);
  const [activeTab, setActiveTab] = useState("overview");

  const actorRoles = session.effectiveRoles;
  const actorIsOwner = actorRoles.includes("owner");
  const actorIsDev = actorRoles.includes("dev");
  const actorIsAdmin = actorRoles.includes("admin");
  const canViewUsers =
    actorIsOwner || actorIsDev || actorIsAdmin;

  const targetRoles = user?.roles ?? [];
  const targetIsSelf = user?.id === session.id;
  const targetIsOwner = targetRoles.includes("owner");
  const targetIsDev = targetRoles.includes("dev");
  const targetIsAdmin = targetRoles.includes("admin");

  const canManageAccount =
    Boolean(user) &&
    (actorIsOwner ||
      (actorIsDev && !targetIsOwner && !targetIsDev) ||
      (actorIsAdmin && !targetIsOwner && !targetIsDev && !targetIsAdmin));
  const canEditProfile = canManageAccount && !Boolean(user?.isDeactivated);
  const canManageRoles =
    Boolean(user) &&
    !Boolean(user?.isDeactivated) &&
    (actorIsOwner ||
      (actorIsDev && !targetIsOwner && !targetIsDev) ||
      (actorIsAdmin && !targetIsOwner && !targetIsDev && !targetIsAdmin));

  const load = useMemo(
    () => async () => {
      if (!canViewUsers || !userId) return;
      setLoading(true);
      setError(null);
      try {
        const [detail, badges] = await Promise.all([
          clientApi.getUser(userId),
          apiFetch<AdminBadgeModel[]>("/admin/badges?includeInactive=true"),
        ]);
        setUser(detail);
        setAllBadges((badges ?? []).filter((entry) => entry.isActive));
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : "Failed to load user details");
      } finally {
        setLoading(false);
      }
    },
    [canViewUsers, userId],
  );

  useEffect(() => {
    if (!canViewUsers) {
      setLoading(false);
      return;
    }
    void load();
  }, [canViewUsers, load]);

  async function refresh() {
    if (!userId) return;
    const detail = await clientApi.getUser(userId);
    setUser(detail);
  }

  async function executeAction(key: string, submit: () => Promise<unknown>) {
    setActionLoading(key);
    setActionError(null);
    try {
      await submit();
      await refresh();
    } catch (e: unknown) {
      setActionError(e instanceof Error ? e.message : "Action failed");
    } finally {
      setActionLoading(null);
    }
  }

  async function runAction(
    key: string,
    submit: () => Promise<unknown>,
    opts?: { confirmText?: string },
  ) {
    if (opts?.confirmText) {
      setPendingConfirmation({ key, confirmText: opts.confirmText, submit });
      setConfirmOpen(true);
      return;
    }
    await executeAction(key, submit);
  }

  async function confirmPendingAction() {
    if (!pendingConfirmation) return;
    await executeAction(pendingConfirmation.key, pendingConfirmation.submit);
    setConfirmOpen(false);
    setPendingConfirmation(null);
  }

  async function handleUpdateProfile(data: {
    displayName: string | null;
    username: string | null;
    avatarUrl: string | null;
    bio: string | null;
  }) {
    if (!user) return;
    await clientApi.updateUser(user.id, data);
    await refresh();
  }

  async function handleGrantBadge(badgeId: string, badgeName: string) {
    if (!user) return;
    await runAction(
      `grant-badge-${badgeId}`,
      () =>
        apiFetch(`/admin/badges/${badgeId}/grant`, {
          method: "POST",
          body: JSON.stringify({ userIdentifier: user.email }),
        }),
      { confirmText: `Grant "${badgeName}" to ${user.email}?` },
    );
  }

  async function handleRevokeBadge(badgeSlug: string, badgeName: string) {
    if (!user) return;
    await runAction(
      `revoke-badge-${badgeSlug}`,
      () =>
        apiFetch(`/admin/badges/users/${user.id}/badges/${badgeSlug}`, {
          method: "DELETE",
        }),
      { confirmText: `Revoke "${badgeName}" from ${user.email}?` },
    );
  }

  return {
    user,
    loading,
    error,
    actionLoading,
    actionError,
    confirmOpen,
    setConfirmOpen,
    pendingConfirmation,
    setPendingConfirmation,
    allBadges,
    activeTab,
    setActiveTab,
    actorRoles,
    actorIsOwner,
    canViewUsers,
    canManageAccount,
    canEditProfile,
    canManageRoles,
    targetIsSelf,
    refresh,
    runAction,
    confirmPendingAction,
    handleUpdateProfile,
    handleGrantBadge,
    handleRevokeBadge,
  };
}
