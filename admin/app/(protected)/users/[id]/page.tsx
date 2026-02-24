"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { AlertTriangle, ArrowLeft, Loader2, RotateCcw, Save, Trash2 } from "lucide-react";
import { useAdminSession } from "@/components/admin-shell";
import { PageHeader } from "@/components/page-header";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { apiFetch, clientApi, type AdminUserDetail } from "@/lib/api-client";
import { canManageAdmins, canManageHunters, canManageModerators } from "@/lib/rbac";

type EditFormState = {
  displayName: string;
  username: string;
  avatarUrl: string;
  bio: string;
};

type AdminBadgeModel = {
  id: string;
  slug: string;
  name: string;
  isActive: boolean;
};

const ROLE_PRIORITY: Record<string, number> = {
  owner: 6,
  core_team: 5,
  admin: 4,
  moderator: 3,
  hunter: 2,
  user: 1,
};

function sortRolesTopToLowest(roles: string[]): string[] {
  return [...roles].sort((a, b) => {
    const priorityDiff = (ROLE_PRIORITY[b] ?? 0) - (ROLE_PRIORITY[a] ?? 0);
    if (priorityDiff !== 0) return priorityDiff;
    return a.localeCompare(b);
  });
}

function getInitials(name: string | null, email: string) {
  const source = name ?? email;
  return source
    .split(/[\s@]/)
    .filter(Boolean)
    .map((word) => word[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}

function roleBadge(role: string) {
  switch (role) {
    case "owner":
      return <Badge className="border-primary/35 bg-primary/15 text-primary">Owner</Badge>;
    case "core_team":
      return <Badge className="border-sky-500/25 bg-sky-500/10 text-sky-300">Core Team</Badge>;
    case "admin":
      return <Badge className="border-teal-500/35 bg-teal-500/10 text-teal-300">Admin</Badge>;
    case "moderator":
      return <Badge className="border-amber-500/20 bg-amber-500/10 text-amber-300">Moderator</Badge>;
    case "hunter":
      return <Badge className="border-emerald-500/20 bg-emerald-500/10 text-emerald-300">Hunter</Badge>;
    default:
      return <Badge variant="secondary">User</Badge>;
  }
}

function fmtDate(value: string | null) {
  if (!value) return "—";
  try {
    return new Date(value).toLocaleString();
  } catch {
    return "—";
  }
}

function statusBadge(isDeactivated: boolean) {
  return isDeactivated ? (
    <Badge className="bg-red-500/15 text-red-300">Deactivated</Badge>
  ) : (
    <Badge className="bg-emerald-500/15 text-emerald-300">Active</Badge>
  );
}

export default function UserManagementPage() {
  const session = useAdminSession();
  const params = useParams();
  const router = useRouter();
  const userId = (params?.id as string) ?? "";

  const [user, setUser] = useState<AdminUserDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [editForm, setEditForm] = useState<EditFormState>({
    displayName: "",
    username: "",
    avatarUrl: "",
    bio: "",
  });
  const [saveLoading, setSaveLoading] = useState(false);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [allBadges, setAllBadges] = useState<AdminBadgeModel[]>([]);
  const [selectedBadgeId, setSelectedBadgeId] = useState("");

  const actorRoles = session.effectiveRoles;
  const actorIsOwner = actorRoles.includes("owner");
  const actorIsAdmin = actorRoles.includes("admin");
  const canViewUsers =
    actorIsOwner || actorIsAdmin || actorRoles.includes("moderator");

  const targetRoles = user?.roles ?? [];
  const targetIsSelf = user?.id === session.id;
  const targetIsOwner = targetRoles.includes("owner");
  const targetIsAdmin = targetRoles.includes("admin");

  const canManageAccount =
    Boolean(user) &&
    (actorIsOwner || (actorIsAdmin && !targetIsOwner && !targetIsAdmin));
  const canEditProfile = canManageAccount && !Boolean(user?.isDeactivated);
  const canManageRoleTarget =
    Boolean(user) &&
    !Boolean(user?.isDeactivated) &&
    (actorIsOwner || (actorIsAdmin && !targetIsOwner && !targetIsAdmin));

  useEffect(() => {
    if (!canViewUsers || !userId) {
      return;
    }

    async function load() {
      setLoading(true);
      setError(null);
      try {
        const [detail, badges] = await Promise.all([
          clientApi.getUser(userId),
          apiFetch<AdminBadgeModel[]>("/admin/badges?includeInactive=true"),
        ]);
        setUser(detail);
        setAllBadges((badges ?? []).filter((entry) => entry.isActive));
        setEditForm({
          displayName: detail.displayName ?? "",
          username: detail.username ?? "",
          avatarUrl: detail.avatarUrl ?? "",
          bio: detail.bio ?? "",
        });
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : "Failed to load user details");
      } finally {
        setLoading(false);
      }
    }

    void load();
  }, [canViewUsers, userId]);

  async function refresh() {
    if (!userId) return;
    const detail = await clientApi.getUser(userId);
    setUser(detail);
    setEditForm({
      displayName: detail.displayName ?? "",
      username: detail.username ?? "",
      avatarUrl: detail.avatarUrl ?? "",
      bio: detail.bio ?? "",
    });
  }

  async function saveProfile() {
    if (!user) return;
    setSaveLoading(true);
    setActionError(null);
    try {
      await clientApi.updateUser(user.id, {
        displayName: editForm.displayName.trim() || null,
        username: editForm.username.trim().toLowerCase() || null,
        avatarUrl: editForm.avatarUrl.trim() || null,
        bio: editForm.bio.trim() || null,
      });
      await refresh();
    } catch (e: unknown) {
      setActionError(e instanceof Error ? e.message : "Failed to update user profile");
    } finally {
      setSaveLoading(false);
    }
  }

  async function runAction(
    key: string,
    submit: () => Promise<unknown>,
    opts?: { confirmText?: string },
  ) {
    if (opts?.confirmText) {
      const ok = window.confirm(opts.confirmText);
      if (!ok) return;
    }
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

  const roleButtons = useMemo(() => {
    if (!user || !canManageRoleTarget) return null;

    const entries: Array<{
      key: string;
      label: string;
      onClick: () => Promise<unknown>;
      destructive?: boolean;
    }> = [];

    if (actorIsOwner && !targetIsSelf) {
      if (user.roles.includes("owner")) {
        entries.push({
          key: "revoke-owner",
          label: "Revoke Owner",
          destructive: true,
          onClick: () => clientApi.demoteOwner(user.id),
        });
      } else {
        entries.push({
          key: "grant-owner",
          label: "Grant Owner",
          onClick: () => clientApi.promoteToOwner(user.id),
        });
      }
    }

    if (actorIsOwner) {
      if (user.roles.includes("core_team")) {
        entries.push({
          key: "revoke-core-team",
          label: "Revoke Core Team",
          destructive: true,
          onClick: () => clientApi.demoteCoreTeam(user.id),
        });
      } else {
        entries.push({
          key: "grant-core-team",
          label: "Grant Core Team",
          onClick: () => clientApi.promoteToCoreTeam(user.id),
        });
      }
    }

    if (canManageAdmins(actorRoles) && !targetIsSelf) {
      if (user.roles.includes("admin")) {
        entries.push({
          key: "revoke-admin",
          label: "Revoke Admin",
          destructive: true,
          onClick: () => clientApi.demoteAdmin(user.id),
        });
      } else {
        entries.push({
          key: "grant-admin",
          label: "Grant Admin",
          onClick: () => clientApi.promoteToAdmin(user.id),
        });
      }
    }

    if (canManageModerators(actorRoles) && !targetIsSelf) {
      if (user.roles.includes("moderator")) {
        entries.push({
          key: "revoke-moderator",
          label: "Revoke Moderator",
          destructive: true,
          onClick: () => clientApi.demoteModerator(user.id),
        });
      } else {
        entries.push({
          key: "grant-moderator",
          label: "Grant Moderator",
          onClick: () => clientApi.promoteToModerator(user.id),
        });
      }
    }

    if (canManageHunters(actorRoles)) {
      if (user.roles.includes("hunter")) {
        entries.push({
          key: "revoke-hunter",
          label: "Revoke Hunter",
          destructive: true,
          onClick: () => clientApi.demoteHunter(user.id),
        });
      } else {
        entries.push({
          key: "grant-hunter",
          label: "Grant Hunter",
          onClick: () => clientApi.promoteToHunter(user.id),
        });
      }
    }

    return entries;
  }, [actorIsOwner, actorRoles, canManageRoleTarget, targetIsSelf, user]);

  async function grantSelectedBadge() {
    if (!user || !selectedBadgeId || !canManageAccount) return;
    const badge = allBadges.find((entry) => entry.id === selectedBadgeId);
    if (!badge) return;
    await runAction(
      `grant-badge-${badge.id}`,
      () =>
        apiFetch(`/admin/badges/${badge.id}/grant`, {
          method: "POST",
          body: JSON.stringify({ userIdentifier: user.email }),
        }),
      {
        confirmText: `Grant "${badge.name}" to ${user.email}?`,
      },
    );
    setSelectedBadgeId("");
  }

  async function revokeBadgeForUser(badgeSlug: string, badgeName: string) {
    if (!user || !canManageAccount) return;
    await runAction(
      `revoke-badge-${badgeSlug}`,
      () =>
        apiFetch(`/admin/badges/users/${user.id}/badges/${badgeSlug}`, {
          method: "DELETE",
        }),
      {
        confirmText: `Revoke "${badgeName}" from ${user.email}?`,
      },
    );
  }

  if (!canViewUsers) {
    return (
      <div className="py-16 text-center text-sm text-destructive">
        You do not have permission to view user management.
      </div>
    );
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-16">
        <Loader2 className="h-5 w-5 animate-spin" />
      </div>
    );
  }

  if (!user) {
    return (
      <div className="space-y-4">
        <Button variant="outline" size="sm" onClick={() => router.push("/users")}>
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back to Users
        </Button>
        <p className="text-sm text-destructive">{error ?? "User not found."}</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title={user.displayName || user.email}
        description={`Manage profile, roles, badges, and account lifecycle for ${user.email}.`}
      >
        <Button variant="outline" size="sm" asChild>
          <Link href="/users">
            <ArrowLeft className="mr-2 h-4 w-4" />
            Back to Users
          </Link>
        </Button>
      </PageHeader>

      {actionError ? (
        <Card className="border-red-500/30 bg-red-500/5">
          <CardContent className="pt-6 text-sm text-red-300">{actionError}</CardContent>
        </Card>
      ) : null}

      <div className="grid gap-4 lg:grid-cols-3">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Identity</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex items-center gap-3">
              <Avatar className="h-12 w-12">
                {user.avatarUrl ? <AvatarImage src={user.avatarUrl} alt={user.displayName ?? user.email} /> : null}
                <AvatarFallback>{getInitials(user.displayName, user.email)}</AvatarFallback>
              </Avatar>
              <div className="min-w-0">
                <p className="truncate font-medium">{user.displayName ?? "Unnamed user"}</p>
                <p className="truncate text-xs text-muted-foreground">{user.email}</p>
              </div>
            </div>
            <div className="text-sm">
              <p className="text-muted-foreground">Username</p>
              <p className="font-medium">{user.username ? `@${user.username}` : "—"}</p>
            </div>
            <div className="text-sm">
              <p className="text-muted-foreground">Status</p>
              <div className="mt-1">{statusBadge(user.isDeactivated)}</div>
            </div>
            <div className="text-sm">
              <p className="text-muted-foreground">Joined</p>
              <p className="font-medium">{fmtDate(user.createdAt)}</p>
            </div>
          </CardContent>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="text-base">Roles</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex flex-wrap gap-2">
              {sortRolesTopToLowest(user.roles).map((role) => (
                <span key={role}>{roleBadge(role)}</span>
              ))}
            </div>
            {roleButtons && roleButtons.length > 0 ? (
              <div className="flex flex-wrap gap-2">
                {roleButtons.map((entry) => (
                  <Button
                    key={entry.key}
                    size="sm"
                    variant={entry.destructive ? "destructive" : "outline"}
                    disabled={Boolean(actionLoading)}
                    onClick={() =>
                      void runAction(entry.key, entry.onClick, {
                        confirmText: `${entry.label} for ${user.email}?`,
                      })
                    }
                  >
                    {actionLoading === entry.key ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
                    {entry.label}
                  </Button>
                ))}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">
                You cannot mutate roles for this account.
              </p>
            )}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Badges</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {canManageAccount ? (
            <div className="grid gap-2 rounded-md border p-3 md:grid-cols-[1fr_auto]">
              <div className="grid gap-1">
                <Label htmlFor="grant-badge-select">Grant Badge</Label>
                <Select value={selectedBadgeId} onValueChange={setSelectedBadgeId}>
                  <SelectTrigger id="grant-badge-select">
                    <SelectValue placeholder="Select badge to grant" />
                  </SelectTrigger>
                  <SelectContent>
                    {allBadges.map((entry) => (
                      <SelectItem key={entry.id} value={entry.id}>
                        {entry.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="flex items-end">
                <Button
                  onClick={() => void grantSelectedBadge()}
                  disabled={!selectedBadgeId || Boolean(actionLoading)}
                >
                  {actionLoading?.startsWith("grant-badge-") ? (
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  ) : null}
                  Grant Badge
                </Button>
              </div>
            </div>
          ) : null}

          <div className="text-sm">
            <p className="text-muted-foreground">Primary Badge</p>
            <p className="font-medium">{user.primaryBadge?.name ?? "No primary badge"}</p>
          </div>
          <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
            {user.badges.length === 0 ? (
              <p className="text-sm text-muted-foreground">No earned badges.</p>
            ) : (
              user.badges.map((entry) => (
                <div key={`${entry.badge.id}-${entry.earnedAt}`} className="rounded-md border p-3">
                  <p className="font-medium">{entry.badge.name}</p>
                  <p className="text-xs text-muted-foreground">
                    {entry.badge.rarity} · {entry.badge.category}
                  </p>
                  <p className="mt-1 text-xs text-muted-foreground">
                    Earned {fmtDate(entry.earnedAt)}
                  </p>
                  {canManageAccount ? (
                    <Button
                      variant="outline"
                      size="sm"
                      className="mt-2"
                      disabled={Boolean(actionLoading)}
                      onClick={() =>
                        void revokeBadgeForUser(entry.badge.slug, entry.badge.name)
                      }
                    >
                      {actionLoading === `revoke-badge-${entry.badge.slug}` ? (
                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      ) : null}
                      Revoke
                    </Button>
                  ) : null}
                </div>
              ))
            )}
          </div>
        </CardContent>
      </Card>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Profile Edit</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="grid gap-2">
              <Label htmlFor="displayName">Display Name</Label>
              <Input
                id="displayName"
                value={editForm.displayName}
                onChange={(e) => setEditForm((prev) => ({ ...prev, displayName: e.target.value }))}
                disabled={!canEditProfile || saveLoading}
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="username">Username</Label>
              <Input
                id="username"
                value={editForm.username}
                onChange={(e) => setEditForm((prev) => ({ ...prev, username: e.target.value.toLowerCase() }))}
                disabled={!canEditProfile || saveLoading}
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="avatarUrl">Avatar URL</Label>
              <Input
                id="avatarUrl"
                value={editForm.avatarUrl}
                onChange={(e) => setEditForm((prev) => ({ ...prev, avatarUrl: e.target.value }))}
                disabled={!canEditProfile || saveLoading}
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="bio">Bio</Label>
              <Textarea
                id="bio"
                rows={4}
                value={editForm.bio}
                onChange={(e) => setEditForm((prev) => ({ ...prev, bio: e.target.value }))}
                disabled={!canEditProfile || saveLoading}
              />
            </div>
            <Button onClick={() => void saveProfile()} disabled={!canEditProfile || saveLoading}>
              {saveLoading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Save className="mr-2 h-4 w-4" />}
              Save Profile Changes
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Account Lifecycle</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="grid grid-cols-2 gap-3 text-sm">
              <div className="rounded-md border p-3">
                <p className="text-muted-foreground">Followers</p>
                <p className="text-xl font-semibold">{user.counts.followers}</p>
              </div>
              <div className="rounded-md border p-3">
                <p className="text-muted-foreground">Following</p>
                <p className="text-xl font-semibold">{user.counts.following}</p>
              </div>
              <div className="rounded-md border p-3">
                <p className="text-muted-foreground">Updates</p>
                <p className="text-xl font-semibold">{user.counts.updates}</p>
              </div>
              <div className="rounded-md border p-3">
                <p className="text-muted-foreground">Badges</p>
                <p className="text-xl font-semibold">{user.counts.badges}</p>
              </div>
            </div>

            <div className="flex flex-wrap gap-2 pt-2">
              {canManageAccount && !targetIsSelf && !user.isDeactivated ? (
                <Button
                  variant="destructive"
                  disabled={Boolean(actionLoading)}
                  onClick={() =>
                    void runAction(
                      "deactivate",
                      () => clientApi.deleteUser(user.id),
                      { confirmText: `Deactivate ${user.email}?` },
                    )
                  }
                >
                  {actionLoading === "deactivate" ? (
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  ) : (
                    <Trash2 className="mr-2 h-4 w-4" />
                  )}
                  Deactivate
                </Button>
              ) : null}

              {actorIsOwner && !targetIsSelf && user.isDeactivated ? (
                <Button
                  variant="outline"
                  disabled={Boolean(actionLoading)}
                  onClick={() =>
                    void runAction(
                      "reactivate",
                      () => clientApi.reactivateUser(user.id),
                      { confirmText: `Reactivate ${user.email}?` },
                    )
                  }
                >
                  {actionLoading === "reactivate" ? (
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  ) : (
                    <RotateCcw className="mr-2 h-4 w-4" />
                  )}
                  Reactivate
                </Button>
              ) : null}

              {actorIsOwner && !targetIsSelf && user.isDeactivated ? (
                <Button
                  variant="destructive"
                  disabled={Boolean(actionLoading)}
                  onClick={() =>
                    void runAction(
                      "hard-delete",
                      () => clientApi.hardDeleteUser(user.id),
                      {
                        confirmText: `Permanently hard delete ${user.email}? This cannot be undone.`,
                      },
                    )
                  }
                >
                  {actionLoading === "hard-delete" ? (
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  ) : (
                    <AlertTriangle className="mr-2 h-4 w-4" />
                  )}
                  Hard Delete
                </Button>
              ) : null}
            </div>

            {!canManageAccount ? (
              <p className="text-sm text-muted-foreground">
                You have read-only access for this account.
              </p>
            ) : null}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Wallet & KYC</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-3 md:grid-cols-2">
          <div className="rounded-md border p-3 text-sm">
            <p className="text-muted-foreground">Wallet</p>
            <p className="mt-1 font-medium">
              {user.wallet ? `${user.wallet.status} · chain ${user.wallet.chainId}` : "No wallet"}
            </p>
            <p className="mt-1 break-all text-xs text-muted-foreground">
              {user.wallet?.address ?? "—"}
            </p>
          </div>
          <div className="rounded-md border p-3 text-sm">
            <p className="text-muted-foreground">KYC</p>
            <p className="mt-1 font-medium">{user.kyc?.status ?? "not_submitted"}</p>
            <p className="mt-1 text-xs text-muted-foreground">Tier: {user.kyc?.tier ?? "basic"}</p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
