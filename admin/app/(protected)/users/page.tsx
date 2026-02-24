"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import {
  AlertTriangle,
  ChevronLeft,
  ChevronRight,
  Loader2,
  MoreHorizontal,
  Pen,
  RotateCcw,
  Search,
  Shield,
  ShieldAlert,
  ShieldCheck,
  Trash2,
  User,
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { PageHeader } from "@/components/page-header";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useAdminSession } from "@/components/admin-shell";
import { clientApi, type AdminUser } from "@/lib/api-client";
import {
  canManageAdmins,
  canManageHunters,
  canManageModerators,
  diffRoleCapabilities,
  formatRoleLabel,
  getAdminGovernanceRole,
  type AdminPanelRole,
} from "@/lib/rbac";

type RoleFilter = "all" | "user" | "hunter" | "core_team" | "moderator" | "admin" | "owner";
type StatusFilter = "all" | "active" | "deactivated";

type EditFormState = {
  displayName: string;
  username: string;
  avatarUrl: string;
  bio: string;
};

type ManagedRole = "owner" | "admin" | "moderator" | "core_team" | "hunter";
type RoleActionMode = "grant" | "revoke";

type PendingRoleAction = {
  user: AdminUser;
  role: ManagedRole;
  mode: RoleActionMode;
  label: string;
  destructive?: boolean;
  submit: (note?: string) => Promise<unknown>;
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

function getHighestRole(roles: string[]): string {
  const sorted = sortRolesTopToLowest(roles);
  return sorted[0] ?? "user";
}

function roleBadge(role: string) {
  switch (role) {
    case "owner":
      return (
        <Badge className="border-primary/35 bg-primary/15 text-primary" variant="outline">
          <ShieldCheck className="mr-1 h-3 w-3" />
          Owner
        </Badge>
      );
    case "admin":
      return (
        <Badge className="border-teal-500/35 bg-teal-500/10 text-teal-300" variant="outline">
          <Shield className="mr-1 h-3 w-3" />
          Admin
        </Badge>
      );
    case "core_team":
      return (
        <Badge className="border-sky-500/25 bg-sky-500/10 text-sky-300" variant="outline">
          <Shield className="mr-1 h-3 w-3" />
          Core Team
        </Badge>
      );
    case "moderator":
      return (
        <Badge className="border-amber-500/20 bg-amber-500/10 text-amber-400" variant="outline">
          <ShieldAlert className="mr-1 h-3 w-3" />
          Moderator
        </Badge>
      );
    case "hunter":
      return (
        <Badge className="border-emerald-500/20 bg-emerald-500/10 text-emerald-400" variant="outline">
          <Pen className="mr-1 h-3 w-3" />
          Hunter
        </Badge>
      );
    default:
      return (
        <Badge variant="secondary">
          <User className="mr-1 h-3 w-3" />
          User
        </Badge>
      );
  }
}

function accountStatusBadge(isDeactivated: boolean) {
  if (isDeactivated) {
    return <Badge className="bg-red-500/15 text-red-300">Deactivated</Badge>;
  }
  return <Badge className="bg-emerald-500/15 text-emerald-300">Active</Badge>;
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

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

function UserActionsMenu({
  user,
  currentUserId,
  currentRoles,
  onRoleActionRequested,
  onEditProfile,
  onDeactivate,
  onReactivate,
  onHardDelete,
}: {
  user: AdminUser;
  currentUserId: string;
  currentRoles: string[];
  onRoleActionRequested: (action: PendingRoleAction) => void;
  onEditProfile: (user: AdminUser) => void;
  onDeactivate: (user: AdminUser) => void;
  onReactivate: (user: AdminUser) => void;
  onHardDelete: (user: AdminUser) => void;
}) {
  const actorIsOwner = currentRoles.includes("owner");
  const actorIsAdmin = currentRoles.includes("admin");

  const canAdmins = canManageAdmins(currentRoles);
  const canModerators = canManageModerators(currentRoles);
  const canHunters = canManageHunters(currentRoles);

  const targetIsSelf = user.id === currentUserId;
  const targetIsOwner = user.roles.includes("owner");
  const targetIsAdmin = user.roles.includes("admin");
  const targetIsDeactivated = user.isDeactivated;

  const canManageAccount =
    actorIsOwner || (actorIsAdmin && !targetIsOwner && !targetIsAdmin);
  const canEdit = canManageAccount && !targetIsDeactivated;
  const canDelete = canManageAccount && !targetIsSelf && !targetIsDeactivated;
  const canReactivate = actorIsOwner && !targetIsSelf && targetIsDeactivated;
  const canHardDelete = actorIsOwner && !targetIsSelf && targetIsDeactivated;

  const actions: Array<{
    key: string;
    label: string;
    mode: RoleActionMode;
    role: ManagedRole;
    submit: (note?: string) => Promise<unknown>;
    destructive?: boolean;
  }> = [];

  const canManageRoleTarget =
    !targetIsDeactivated &&
    (actorIsOwner || (actorIsAdmin && !targetIsOwner && !targetIsAdmin));

  if (canManageRoleTarget) {
    const hasOwner = user.roles.includes("owner");
    const hasAdmin = user.roles.includes("admin");
    const hasModerator = user.roles.includes("moderator");
    const hasCoreTeam = user.roles.includes("core_team");
    const hasHunter = user.roles.includes("hunter");

    if (actorIsOwner && !targetIsSelf) {
      if (hasOwner) {
        actions.push({
          key: "demote-owner",
          label: "Revoke Owner",
          mode: "revoke",
          role: "owner",
          submit: () => clientApi.demoteOwner(user.id),
          destructive: true,
        });
      } else {
        actions.push({
          key: "promote-owner",
          label: "Grant Owner",
          mode: "grant",
          role: "owner",
          submit: (note?: string) => clientApi.promoteToOwner(user.id, note),
        });
      }
    }

    if (actorIsOwner) {
      if (hasCoreTeam) {
        actions.push({
          key: "demote-core-team",
          label: "Revoke Core Team",
          mode: "revoke",
          role: "core_team",
          submit: () => clientApi.demoteCoreTeam(user.id),
          destructive: true,
        });
      } else {
        actions.push({
          key: "promote-core-team",
          label: "Grant Core Team",
          mode: "grant",
          role: "core_team",
          submit: (note?: string) => clientApi.promoteToCoreTeam(user.id, note),
        });
      }
    }

    if (canAdmins) {
      if (hasAdmin) {
        actions.push({
          key: "demote-admin",
          label: "Revoke Admin",
          mode: "revoke",
          role: "admin",
          submit: () => clientApi.demoteAdmin(user.id),
          destructive: true,
        });
      } else if (!targetIsSelf) {
        actions.push({
          key: "promote-admin",
          label: "Grant Admin",
          mode: "grant",
          role: "admin",
          submit: (note?: string) => clientApi.promoteToAdmin(user.id, note),
        });
      }
    }

    if (canModerators) {
      if (hasModerator) {
        actions.push({
          key: "demote-moderator",
          label: "Revoke Moderator",
          mode: "revoke",
          role: "moderator",
          submit: () => clientApi.demoteModerator(user.id),
          destructive: true,
        });
      } else if (!targetIsSelf) {
        actions.push({
          key: "promote-moderator",
          label: "Grant Moderator",
          mode: "grant",
          role: "moderator",
          submit: (note?: string) => clientApi.promoteToModerator(user.id, note),
        });
      }
    }

    if (canHunters) {
      if (hasHunter) {
        actions.push({
          key: "demote-hunter",
          label: "Revoke Hunter",
          mode: "revoke",
          role: "hunter",
          submit: () => clientApi.demoteHunter(user.id),
          destructive: true,
        });
      } else {
        actions.push({
          key: "promote-hunter",
          label: "Grant Hunter",
          mode: "grant",
          role: "hunter",
          submit: (note?: string) => clientApi.promoteToHunter(user.id, note),
        });
      }
    }
  }

  if (!canEdit && !canDelete && !canReactivate && !canHardDelete && actions.length === 0) {
    return null;
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon" className="h-8 w-8">
          <MoreHorizontal className="h-4 w-4" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        {(canEdit || canDelete || canReactivate || canHardDelete) && (
          <>
            <DropdownMenuLabel>User Management</DropdownMenuLabel>
            {canEdit && (
              <DropdownMenuItem onClick={() => onEditProfile(user)}>
                Edit Profile
              </DropdownMenuItem>
            )}
            {canDelete && (
              <DropdownMenuItem className="text-destructive" onClick={() => onDeactivate(user)}>
                <Trash2 className="mr-2 h-4 w-4" />
                Deactivate Account
              </DropdownMenuItem>
            )}
            {canReactivate && (
              <DropdownMenuItem onClick={() => onReactivate(user)}>
                <RotateCcw className="mr-2 h-4 w-4" />
                Reactivate Account
              </DropdownMenuItem>
            )}
            {canHardDelete && (
              <DropdownMenuItem className="text-destructive" onClick={() => onHardDelete(user)}>
                <AlertTriangle className="mr-2 h-4 w-4" />
                Hard Delete Account
              </DropdownMenuItem>
            )}
          </>
        )}

        {actions.length > 0 && (
          <>
            {(canEdit || canDelete || canReactivate || canHardDelete) && <DropdownMenuSeparator />}
            <DropdownMenuLabel>Manage Roles</DropdownMenuLabel>
            {actions.map((entry) => (
              <DropdownMenuItem
                key={entry.key}
                className={entry.destructive ? "text-destructive" : ""}
                onClick={() =>
                  onRoleActionRequested({
                    user,
                    role: entry.role,
                    mode: entry.mode,
                    label: entry.label,
                    destructive: entry.destructive,
                    submit: entry.submit,
                  })
                }
              >
                {entry.label}
              </DropdownMenuItem>
            ))}
          </>
        )}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

const EMPTY_EDIT_FORM: EditFormState = {
  displayName: "",
  username: "",
  avatarUrl: "",
  bio: "",
};

export default function UsersPage() {
  const session = useAdminSession();
  const canManageUsers = session.effectiveRoles.includes("owner") || session.effectiveRoles.includes("admin");

  const [users, setUsers] = useState<AdminUser[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [searchInput, setSearchInput] = useState("");
  const [q, setQ] = useState("");
  const [role, setRole] = useState<RoleFilter>("all");
  const [status, setStatus] = useState<StatusFilter>("all");
  const [limit, setLimit] = useState(25);
  const [offset, setOffset] = useState(0);

  const [selectedUser, setSelectedUser] = useState<AdminUser | null>(null);

  const [editOpen, setEditOpen] = useState(false);
  const [editLoading, setEditLoading] = useState(false);
  const [editSaving, setEditSaving] = useState(false);
  const [editError, setEditError] = useState<string | null>(null);
  const [editForm, setEditForm] = useState<EditFormState>(EMPTY_EDIT_FORM);

  const [deleteOpen, setDeleteOpen] = useState(false);
  const [deleteSaving, setDeleteSaving] = useState(false);
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [deleteReason, setDeleteReason] = useState("");

  const [roleActionOpen, setRoleActionOpen] = useState(false);
  const [pendingRoleAction, setPendingRoleAction] = useState<PendingRoleAction | null>(null);
  const [roleActionSaving, setRoleActionSaving] = useState(false);
  const [roleActionError, setRoleActionError] = useState<string | null>(null);
  const [roleActionNote, setRoleActionNote] = useState("");

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
      const result = await clientApi.listUsers({ limit, offset, role, status, q });
      setUsers(result.data);
      setTotal(result.total);
    } catch (e: unknown) {
      setUsers([]);
      setTotal(0);
      setError(e instanceof Error ? e.message : "Failed to load users");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [limit, offset, role, status, q]);

  const stats = useMemo(() => {
    const active = users.filter((entry) => !entry.isDeactivated).length;
    const deactivated = users.length - active;
    const admins = users.filter((entry) => entry.roles.includes("admin")).length;
    const moderators = users.filter((entry) => entry.roles.includes("moderator")).length;
    const coreTeam = users.filter((entry) => entry.roles.includes("core_team")).length;
    const hunters = users.filter((entry) => entry.roles.includes("hunter")).length;
    return { active, deactivated, admins, moderators, coreTeam, hunters };
  }, [users]);

  const pageStart = total === 0 ? 0 : offset + 1;
  const pageEnd = Math.min(offset + users.length, total);
  const canPrev = offset > 0;
  const canNext = offset + limit < total;

  async function openEdit(user: AdminUser) {
    if (!canManageUsers) return;
    setSelectedUser(user);
    setEditOpen(true);
    setEditLoading(true);
    setEditError(null);
    setEditForm(EMPTY_EDIT_FORM);

    try {
      const detail = await clientApi.getUser(user.id);
      setEditForm({
        displayName: detail.displayName ?? "",
        username: detail.username ?? "",
        avatarUrl: detail.avatarUrl ?? "",
        bio: detail.bio ?? "",
      });
    } catch (e: unknown) {
      setEditError(e instanceof Error ? e.message : "Failed to load user profile");
    } finally {
      setEditLoading(false);
    }
  }

  async function saveEdit() {
    if (!selectedUser) return;
    setEditSaving(true);
    setEditError(null);
    try {
      await clientApi.updateUser(selectedUser.id, {
        displayName: editForm.displayName.trim() || null,
        username: editForm.username.trim().toLowerCase() || null,
        avatarUrl: editForm.avatarUrl.trim() || null,
        bio: editForm.bio.trim() || null,
      });
      setEditOpen(false);
      setSelectedUser(null);
      setEditForm(EMPTY_EDIT_FORM);
      void load();
    } catch (e: unknown) {
      setEditError(e instanceof Error ? e.message : "Failed to update user");
    } finally {
      setEditSaving(false);
    }
  }

  function openDeactivate(user: AdminUser) {
    if (!canManageUsers) return;
    setSelectedUser(user);
    setDeleteReason("");
    setDeleteError(null);
    setDeleteOpen(true);
  }

  async function confirmDeactivate() {
    if (!selectedUser) return;
    setDeleteSaving(true);
    setDeleteError(null);
    try {
      await clientApi.deleteUser(selectedUser.id, {
        reason: deleteReason.trim() || undefined,
      });
      setDeleteOpen(false);
      setSelectedUser(null);
      setDeleteReason("");
      void load();
    } catch (e: unknown) {
      setDeleteError(e instanceof Error ? e.message : "Failed to deactivate user");
    } finally {
      setDeleteSaving(false);
    }
  }

  async function reactivateUser(user: AdminUser) {
    if (!canManageUsers) return;
    const reason = window.prompt("Reason for reactivation (optional)") ?? "";

    setLoading(true);
    setError(null);
    try {
      await clientApi.reactivateUser(user.id, {
        reason: reason.trim() || undefined,
      });
      await load();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Failed to reactivate user");
    } finally {
      setLoading(false);
    }
  }

  async function hardDeleteUser(user: AdminUser) {
    if (!canManageUsers) return;

    const proceed = window.confirm(
      `Permanently delete ${user.email} from Blocnet database? This cannot be undone.`,
    );
    if (!proceed) return;

    const reason = window.prompt("Reason for hard delete (optional)") ?? "";

    setLoading(true);
    setError(null);
    try {
      await clientApi.hardDeleteUser(user.id, {
        reason: reason.trim() || undefined,
      });
      await load();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Failed to hard delete user");
    } finally {
      setLoading(false);
    }
  }

  function governanceRoleForRoles(roles: string[]): AdminPanelRole | null {
    return getAdminGovernanceRole(roles);
  }

  function openRoleActionDialog(action: PendingRoleAction) {
    setPendingRoleAction(action);
    setRoleActionOpen(true);
    setRoleActionError(null);
    setRoleActionNote("");
  }

  async function confirmRoleAction() {
    if (!pendingRoleAction) return;
    setRoleActionSaving(true);
    setRoleActionError(null);
    try {
      await pendingRoleAction.submit(
        pendingRoleAction.mode === "grant" ? roleActionNote.trim() || undefined : undefined,
      );
      setRoleActionOpen(false);
      setPendingRoleAction(null);
      setRoleActionNote("");
      await load();
    } catch (e: unknown) {
      setRoleActionError(e instanceof Error ? e.message : "Failed to update role");
    } finally {
      setRoleActionSaving(false);
    }
  }

  const pendingRoleDiff = useMemo(() => {
    if (!pendingRoleAction) return null;
    const beforeRole = governanceRoleForRoles(pendingRoleAction.user.roles);
    const nextRoleSet = new Set(pendingRoleAction.user.roles);
    if (pendingRoleAction.mode === "grant") {
      nextRoleSet.add(pendingRoleAction.role);
    } else {
      nextRoleSet.delete(pendingRoleAction.role);
    }
    const afterRole = governanceRoleForRoles(Array.from(nextRoleSet));
    return diffRoleCapabilities(beforeRole, afterRole);
  }, [pendingRoleAction]);

  const pendingRoleTransition = useMemo(() => {
    if (!pendingRoleAction) {
      return { beforeRole: null as AdminPanelRole | null, afterRole: null as AdminPanelRole | null };
    }
    const beforeRole = governanceRoleForRoles(pendingRoleAction.user.roles);
    const nextRoleSet = new Set(pendingRoleAction.user.roles);
    if (pendingRoleAction.mode === "grant") {
      nextRoleSet.add(pendingRoleAction.role);
    } else {
      nextRoleSet.delete(pendingRoleAction.role);
    }
    const afterRole = governanceRoleForRoles(Array.from(nextRoleSet));
    return { beforeRole, afterRole };
  }, [pendingRoleAction]);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Users & Roles"
        description="Search members, manage account data, and control admin, moderator, and hunter access."
      >
        <Button variant="outline" size="sm" asChild>
          <Link href="/roles">View Full Role Access</Link>
        </Button>
      </PageHeader>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
        <Card>
          <CardContent className="pt-6">
            <p className="text-sm text-muted-foreground">Total Results</p>
            <p className="text-2xl font-bold">{total}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <p className="text-sm text-muted-foreground">Active (page)</p>
            <p className="text-2xl font-bold">{stats.active}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <p className="text-sm text-muted-foreground">Deactivated (page)</p>
            <p className="text-2xl font-bold">{stats.deactivated}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <p className="text-sm text-muted-foreground">Admins (page)</p>
            <p className="text-2xl font-bold">{stats.admins}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <p className="text-sm text-muted-foreground">Mods/Core/Hunters (page)</p>
            <p className="text-2xl font-bold">{stats.moderators + stats.coreTeam + stats.hunters}</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Directory</CardTitle>
          <div className="mt-3 grid gap-3 md:grid-cols-5">
            <div className="relative md:col-span-2">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
                className="pl-9"
                placeholder="Search email, name, username, or user ID"
              />
            </div>
            <Select
              value={role}
              onValueChange={(next) => {
                setRole(next as RoleFilter);
                setOffset(0);
              }}
            >
              <SelectTrigger>
                <SelectValue placeholder="Filter role" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Roles</SelectItem>
                <SelectItem value="owner">Owner</SelectItem>
                <SelectItem value="core_team">Core Team</SelectItem>
                <SelectItem value="admin">Admin</SelectItem>
                <SelectItem value="moderator">Moderator</SelectItem>
                <SelectItem value="hunter">Hunter</SelectItem>
                <SelectItem value="user">User</SelectItem>
              </SelectContent>
            </Select>
            <Select
              value={status}
              onValueChange={(next) => {
                setStatus(next as StatusFilter);
                setOffset(0);
              }}
            >
              <SelectTrigger>
                <SelectValue placeholder="Filter status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Statuses</SelectItem>
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="deactivated">Deactivated</SelectItem>
              </SelectContent>
            </Select>
            <Select
              value={String(limit)}
              onValueChange={(next) => {
                setLimit(Number(next));
                setOffset(0);
              }}
            >
              <SelectTrigger>
                <SelectValue placeholder="Page size" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="25">25 / page</SelectItem>
                <SelectItem value="50">50 / page</SelectItem>
                <SelectItem value="100">100 / page</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent>
          {loading ? (
            <LoadingSpinner className="py-10" />
          ) : error ? (
            <p className="py-8 text-center text-sm text-destructive">{error}</p>
          ) : users.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">No users found.</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>User</TableHead>
                  <TableHead>Roles</TableHead>
                  <TableHead>Badges</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Projects</TableHead>
                  <TableHead className="text-right">Updates</TableHead>
                  <TableHead className="w-[100px]" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {users.map((user) => (
                  <TableRow key={user.id}>
                    <TableCell>
                      <div className="flex items-center gap-3">
                        <Avatar className="h-8 w-8">
                          <AvatarFallback className="text-xs">
                            {getInitials(user.displayName, user.email)}
                          </AvatarFallback>
                        </Avatar>
                        <div className="min-w-0">
                          <p className="truncate font-medium">
                            {user.displayName ?? user.email.split("@")[0]}
                          </p>
                          <p className="truncate text-xs text-muted-foreground">
                            {user.email}
                            {user.username ? ` · @${user.username}` : ""}
                          </p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <span>{roleBadge(getHighestRole(user.roles))}</span>
                    </TableCell>
                    <TableCell>
                      <div className="flex flex-col">
                        <span className="text-sm font-medium">
                          {user.primaryBadge ? user.primaryBadge.name : "No primary badge"}
                        </span>
                        <span className="text-xs text-muted-foreground">
                          {user.badgesCount} total badge{user.badgesCount === 1 ? "" : "s"}
                        </span>
                      </div>
                    </TableCell>
                    <TableCell>{accountStatusBadge(user.isDeactivated)}</TableCell>
                    <TableCell className="text-right">{user.projectsAssigned}</TableCell>
                    <TableCell className="text-right">{user.updatesPosted}</TableCell>
                    <TableCell>
                      <div className="flex items-center justify-end">
                        <Button variant="outline" size="sm" asChild>
                          <Link href={`/users/${user.id}`}>Manage</Link>
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}

          <div className="mt-4 flex flex-col items-start justify-between gap-3 text-sm text-muted-foreground md:flex-row md:items-center">
            <p>
              Showing {pageStart}-{pageEnd} of {total}
            </p>
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={!canPrev || loading}
                onClick={() => setOffset((prev) => Math.max(prev - limit, 0))}
              >
                <ChevronLeft className="h-4 w-4" />
                Prev
              </Button>
              <Button
                variant="outline"
                size="sm"
                disabled={!canNext || loading}
                onClick={() => setOffset((prev) => prev + limit)}
              >
                Next
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      <Dialog
        open={editOpen}
        onOpenChange={(open) => {
          setEditOpen(open);
          if (!open) {
            setSelectedUser(null);
            setEditForm(EMPTY_EDIT_FORM);
            setEditError(null);
          }
        }}
      >
        <DialogContent className="max-w-xl">
          <DialogHeader>
            <DialogTitle>Edit User</DialogTitle>
            <DialogDescription>
              {selectedUser ? `Update profile data for ${selectedUser.email}.` : "Update user profile fields."}
            </DialogDescription>
          </DialogHeader>

          {editLoading ? (
            <LoadingSpinner className="py-10" />
          ) : (
            <div className="grid gap-4">
              <div className="grid gap-2">
                <Label htmlFor="edit-display-name">Display Name</Label>
                <Input
                  id="edit-display-name"
                  value={editForm.displayName}
                  onChange={(e) =>
                    setEditForm((prev) => ({
                      ...prev,
                      displayName: e.target.value,
                    }))
                  }
                  placeholder="Display name"
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="edit-username">Username</Label>
                <Input
                  id="edit-username"
                  value={editForm.username}
                  onChange={(e) =>
                    setEditForm((prev) => ({
                      ...prev,
                      username: e.target.value.toLowerCase(),
                    }))
                  }
                  placeholder="username"
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="edit-avatar">Avatar URL</Label>
                <Input
                  id="edit-avatar"
                  value={editForm.avatarUrl}
                  onChange={(e) =>
                    setEditForm((prev) => ({
                      ...prev,
                      avatarUrl: e.target.value,
                    }))
                  }
                  placeholder="https://..."
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="edit-bio">Bio</Label>
                <Textarea
                  id="edit-bio"
                  rows={4}
                  value={editForm.bio}
                  onChange={(e) =>
                    setEditForm((prev) => ({
                      ...prev,
                      bio: e.target.value,
                    }))
                  }
                  placeholder="Short profile biography"
                />
              </div>
            </div>
          )}

          {editError && <p className="text-sm text-destructive">{editError}</p>}

          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => {
                setEditOpen(false);
              }}
            >
              Cancel
            </Button>
            <Button onClick={saveEdit} disabled={editLoading || editSaving || !selectedUser}>
              {editSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
              Save Changes
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog
        open={roleActionOpen}
        onOpenChange={(open) => {
          setRoleActionOpen(open);
          if (!open) {
            setPendingRoleAction(null);
            setRoleActionError(null);
            setRoleActionNote("");
          }
        }}
      >
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>{pendingRoleAction?.label ?? "Confirm Role Action"}</DialogTitle>
            <DialogDescription>
              {pendingRoleAction
                ? `${pendingRoleAction.mode === "grant" ? "Apply" : "Confirm"} role update for ${pendingRoleAction.user.email}.`
                : "Confirm selected role action."}
            </DialogDescription>
          </DialogHeader>

          {pendingRoleAction && (
            <div className="space-y-4">
              <div className="rounded-md border bg-muted/20 p-3 text-sm">
                <p className="text-muted-foreground">
                  Governance Role Transition:
                </p>
                <p className="mt-1 font-medium">
                  {pendingRoleTransition.beforeRole
                    ? formatRoleLabel(pendingRoleTransition.beforeRole)
                    : "No governance role"}
                  {" -> "}
                  {pendingRoleTransition.afterRole
                    ? formatRoleLabel(pendingRoleTransition.afterRole)
                    : "No governance role"}
                </p>
              </div>

              {pendingRoleDiff && (
                <div className="grid gap-3 md:grid-cols-2">
                  <div className="rounded-md border p-3">
                    <p className="mb-2 text-sm font-medium text-emerald-300">Capabilities Gained</p>
                    {pendingRoleDiff.gained.length === 0 ? (
                      <p className="text-xs text-muted-foreground">No new capabilities.</p>
                    ) : (
                      <div className="flex flex-wrap gap-1">
                        {pendingRoleDiff.gained.map((entry) => (
                          <Badge key={entry.key} variant="outline" className="border-emerald-500/30 bg-emerald-500/10 text-emerald-300">
                            {entry.label}
                          </Badge>
                        ))}
                      </div>
                    )}
                  </div>
                  <div className="rounded-md border p-3">
                    <p className="mb-2 text-sm font-medium text-red-300">Capabilities Removed</p>
                    {pendingRoleDiff.removed.length === 0 ? (
                      <p className="text-xs text-muted-foreground">No capabilities removed.</p>
                    ) : (
                      <div className="flex flex-wrap gap-1">
                        {pendingRoleDiff.removed.map((entry) => (
                          <Badge key={entry.key} variant="outline" className="border-red-500/30 bg-red-500/10 text-red-300">
                            {entry.label}
                          </Badge>
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              )}

              {pendingRoleAction.mode === "grant" && (
                <div className="grid gap-2">
                  <Label htmlFor="role-action-note">Grant Note (optional)</Label>
                  <Textarea
                    id="role-action-note"
                    rows={3}
                    value={roleActionNote}
                    onChange={(e) => setRoleActionNote(e.target.value)}
                    placeholder="Context for this promotion"
                  />
                </div>
              )}

              {(pendingRoleAction.role === "hunter" ||
                pendingRoleAction.role === "core_team") && (
                <div className="rounded-md border border-teal-500/25 bg-teal-500/5 p-3 text-xs text-teal-200">
                  Hunter and Core Team are space/capability roles, not admin governance roles.
                </div>
              )}
            </div>
          )}

          {roleActionError && <p className="text-sm text-destructive">{roleActionError}</p>}

          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => {
                setRoleActionOpen(false);
              }}
            >
              Cancel
            </Button>
            <Button
              variant={pendingRoleAction?.destructive ? "destructive" : "default"}
              onClick={confirmRoleAction}
              disabled={roleActionSaving || !pendingRoleAction}
            >
              {roleActionSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
              Confirm
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog
        open={deleteOpen}
        onOpenChange={(open) => {
          setDeleteOpen(open);
          if (!open) {
            setSelectedUser(null);
            setDeleteError(null);
            setDeleteReason("");
          }
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Deactivate User Account</DialogTitle>
            <DialogDescription>
              {selectedUser
                ? `This will deactivate ${selectedUser.email}, clear roles and sign-in devices, and scrub editable profile fields.`
                : "This action deactivates the selected user account."}
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-2">
            <Label htmlFor="deactivate-reason">Reason (optional)</Label>
            <Textarea
              id="deactivate-reason"
              rows={3}
              value={deleteReason}
              onChange={(e) => setDeleteReason(e.target.value)}
              placeholder="Why this account is being deactivated"
            />
          </div>

          {deleteError && <p className="text-sm text-destructive">{deleteError}</p>}

          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => {
                setDeleteOpen(false);
              }}
            >
              Cancel
            </Button>
            <Button variant="destructive" onClick={confirmDeactivate} disabled={deleteSaving || !selectedUser}>
              {deleteSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
              Deactivate
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
