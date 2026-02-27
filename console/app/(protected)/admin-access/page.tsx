"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import {
  ChevronLeft,
  ChevronRight,
  Loader2,
  Search,
  ShieldAlert,
  ShieldCheck,
  User,
} from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { useAdminSession } from "@/components/admin-shell";
import { clientApi, type AdminUser } from "@/lib/api-client";
import { canManageAdmins, canManageModerators, type AdminPanelRole } from "@/lib/rbac";

type GovernanceRole = AdminPanelRole;
type GovernanceFilter = "all" | GovernanceRole;
type StatusFilter = "all" | "active" | "deactivated";

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

function accountStatusBadge(isDeactivated: boolean) {
  if (isDeactivated) {
    return <Badge className="bg-red-500/15 text-red-300">Deactivated</Badge>;
  }
  return <Badge className="bg-emerald-500/15 text-emerald-300">Active</Badge>;
}

function governanceRolePills(roles: string[]) {
  const items: GovernanceRole[] = [];
  if (roles.includes("owner")) items.push("owner");
  if (roles.includes("admin")) items.push("admin");
  if (roles.includes("moderator")) items.push("moderator");
  return items.map((role) => {
    if (role === "owner") {
      return (
        <Badge
          key={role}
          className="border-primary/35 bg-primary/15 text-primary"
          variant="outline"
        >
          <ShieldCheck className="mr-1 h-3 w-3" />
          Owner
        </Badge>
      );
    }
    if (role === "admin") {
      return (
        <Badge
          key={role}
          className="border-teal-500/35 bg-teal-500/10 text-teal-300"
          variant="outline"
        >
          <ShieldCheck className="mr-1 h-3 w-3" />
          Admin
        </Badge>
      );
    }
    return (
      <Badge
        key={role}
        className="border-amber-500/20 bg-amber-500/10 text-amber-400"
        variant="outline"
      >
        <ShieldAlert className="mr-1 h-3 w-3" />
        Moderator
      </Badge>
    );
  });
}

export default function AdminAccessPage() {
  const session = useAdminSession();
  const actorRoles = session.effectiveRoles;
  const actorIsOwner = actorRoles.includes("owner");
  const actorCanManageAdmins = canManageAdmins(actorRoles);
  const actorCanManageModerators = canManageModerators(actorRoles);

  const [users, setUsers] = useState<AdminUser[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [actionUserId, setActionUserId] = useState<string | null>(null);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [confirmError, setConfirmError] = useState<string | null>(null);
  const [confirmNote, setConfirmNote] = useState("");
  const [pendingAction, setPendingAction] = useState<{
    user: AdminUser;
    action:
      | "grant_owner"
      | "revoke_owner"
      | "grant_admin"
      | "revoke_admin"
      | "grant_moderator"
      | "revoke_moderator";
  } | null>(null);

  const [searchInput, setSearchInput] = useState("");
  const [q, setQ] = useState("");
  const [role, setRole] = useState<GovernanceFilter>("all");
  const [status, setStatus] = useState<StatusFilter>("active");
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
      if (role === "all") {
        const governanceRoles: GovernanceRole[] = ["owner", "admin", "moderator"];
        const governancePageSize = 100;

        const fetchAllForRole = async (targetRole: GovernanceRole) => {
          const rows: AdminUser[] = [];
          let nextOffset = 0;
          // Governance user sets are expected to be small, but keep a hard cap.
          while (nextOffset <= 5000) {
            const response = await clientApi.listUsers({
              limit: governancePageSize,
              offset: nextOffset,
              role: targetRole,
              status,
              q,
            });
            rows.push(...response.data);
            if (response.data.length < governancePageSize) break;
            nextOffset += governancePageSize;
          }
          return rows;
        };

        const roleBatches = await Promise.all(governanceRoles.map((entry) => fetchAllForRole(entry)));
        const byUserId = new Map<string, AdminUser>();
        for (const batch of roleBatches) {
          for (const row of batch) {
            const existing = byUserId.get(row.id);
            if (!existing) {
              byUserId.set(row.id, row);
              continue;
            }
            byUserId.set(row.id, {
              ...row,
              roles: Array.from(new Set([...existing.roles, ...row.roles])),
            });
          }
        }

        const merged = Array.from(byUserId.values()).sort((a, b) => {
          return a.email.localeCompare(b.email);
        });
        setTotal(merged.length);
        setUsers(merged.slice(offset, offset + limit));
      } else {
        const result = await clientApi.listUsers({
          limit,
          offset,
          role,
          status,
          q,
        });
        const filtered = result.data.filter((entry) => entry.roles.includes(role));
        setUsers(filtered);
        setTotal(result.total);
      }
    } catch (e: unknown) {
      setUsers([]);
      setTotal(0);
      setError(e instanceof Error ? e.message : "Failed to load admin access members");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [limit, offset, role, status, q]);

  const stats = useMemo(() => {
    const owners = users.filter((entry) => entry.roles.includes("owner")).length;
    const admins = users.filter((entry) => entry.roles.includes("admin")).length;
    const moderators = users.filter((entry) => entry.roles.includes("moderator")).length;
    return { owners, admins, moderators };
  }, [users]);

  const pageStart = total === 0 ? 0 : offset + 1;
  const pageEnd = Math.min(offset + users.length, total);
  const canPrev = offset > 0;
  const canNext = offset + limit < total;

  async function submitGovernanceAction(
    user: AdminUser,
    action: "grant_owner" | "revoke_owner" | "grant_admin" | "revoke_admin" | "grant_moderator" | "revoke_moderator",
    note?: string,
  ) {
    setActionUserId(user.id);
    setError(null);
    try {
      switch (action) {
        case "grant_owner":
          await clientApi.promoteToOwner(user.id, note || undefined);
          break;
        case "revoke_owner":
          await clientApi.demoteOwner(user.id);
          break;
        case "grant_admin":
          await clientApi.promoteToAdmin(user.id, note || undefined);
          break;
        case "revoke_admin":
          await clientApi.demoteAdmin(user.id);
          break;
        case "grant_moderator":
          await clientApi.promoteToModerator(user.id, note || undefined);
          break;
        case "revoke_moderator":
          await clientApi.demoteModerator(user.id);
          break;
      }
      await load();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Failed to update admin access role");
      throw e;
    } finally {
      setActionUserId(null);
    }
  }

  function openGovernanceActionDialog(
    user: AdminUser,
    action:
      | "grant_owner"
      | "revoke_owner"
      | "grant_admin"
      | "revoke_admin"
      | "grant_moderator"
      | "revoke_moderator",
  ) {
    setPendingAction({ user, action });
    setConfirmError(null);
    setConfirmNote("");
    setConfirmOpen(true);
  }

  async function confirmGovernanceAction() {
    if (!pendingAction) return;
    setConfirmError(null);
    try {
      await submitGovernanceAction(
        pendingAction.user,
        pendingAction.action,
        pendingAction.action.startsWith("grant")
          ? confirmNote.trim() || undefined
          : undefined,
      );
      setConfirmOpen(false);
      setPendingAction(null);
      setConfirmNote("");
    } catch (e: unknown) {
      setConfirmError(
        e instanceof Error ? e.message : "Failed to apply role action",
      );
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Admin Panel Access"
        description="Manage governance roles for panel operators only: owner, admin, and moderator."
      >
        <Button variant="outline" size="sm" asChild>
          <Link href="/users">Open Members Directory</Link>
        </Button>
        <Button variant="outline" size="sm" asChild>
          <Link href="/roles">View Role Matrix</Link>
        </Button>
      </PageHeader>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <Card>
          <CardContent className="pt-6">
            <p className="text-sm text-muted-foreground">Total Results</p>
            <p className="text-2xl font-bold">{total}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <p className="text-sm text-muted-foreground">Owners (page)</p>
            <p className="text-2xl font-bold">{stats.owners}</p>
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
            <p className="text-sm text-muted-foreground">Moderators (page)</p>
            <p className="text-2xl font-bold">{stats.moderators}</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardContent className="pt-6">
          <div className="grid gap-3 md:grid-cols-5">
            <div className="relative md:col-span-2">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={searchInput}
                onChange={(event) => setSearchInput(event.target.value)}
                className="pl-9"
                placeholder="Search by name, email, username, or user ID"
              />
            </div>
            <Select
              value={role}
              onValueChange={(next) => {
                setRole(next as GovernanceFilter);
                setOffset(0);
              }}
            >
              <SelectTrigger>
                <SelectValue placeholder="Governance role" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Owner/Admin/Moderator</SelectItem>
                <SelectItem value="owner">Owner only</SelectItem>
                <SelectItem value="admin">Admin only</SelectItem>
                <SelectItem value="moderator">Moderator only</SelectItem>
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
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="deactivated">Deactivated</SelectItem>
                <SelectItem value="all">All statuses</SelectItem>
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
        </CardContent>
      </Card>

      <Card>
        <CardContent className="pt-6">
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
                  <TableHead>Member</TableHead>
                  <TableHead>Governance Role</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="w-[320px]">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {users.map((user) => {
                  const targetIsSelf = user.id === session.id;
                  const hasOwner = user.roles.includes("owner");
                  const hasAdmin = user.roles.includes("admin");
                  const hasModerator = user.roles.includes("moderator");
                  const governancePills = governanceRolePills(user.roles);
                  const actionDisabled = actionUserId === user.id;

                  return (
                    <TableRow key={user.id}>
                      <TableCell>
                        <div className="min-w-0">
                          <p className="truncate font-medium">
                            {user.displayName ?? user.email.split("@")[0]}
                          </p>
                          <p className="truncate text-xs text-muted-foreground">
                            {user.email}
                            {user.username ? ` · @${user.username}` : ""}
                          </p>
                          <p className="truncate text-[11px] text-muted-foreground">
                            {getInitials(user.displayName, user.email)} · {user.id}
                          </p>
                        </div>
                      </TableCell>
                      <TableCell>
                        {governancePills.length > 0 ? (
                          <div className="flex flex-wrap gap-1.5">{governancePills}</div>
                        ) : (
                          <Badge variant="secondary">
                            <User className="mr-1 h-3 w-3" />
                            None
                          </Badge>
                        )}
                      </TableCell>
                      <TableCell>{accountStatusBadge(user.isDeactivated)}</TableCell>
                      <TableCell>
                        <div className="flex flex-wrap gap-2">
                          {actorIsOwner && (
                            <Button
                              variant={hasOwner ? "destructive" : "outline"}
                              size="sm"
                              disabled={targetIsSelf || user.isDeactivated || actionDisabled}
                              onClick={() =>
                                openGovernanceActionDialog(
                                  user,
                                  hasOwner ? "revoke_owner" : "grant_owner",
                                )
                              }
                            >
                              {actionDisabled ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
                              {hasOwner ? "Revoke Owner" : "Grant Owner"}
                            </Button>
                          )}

                          {actorCanManageAdmins && (
                            <Button
                              variant={hasAdmin ? "destructive" : "outline"}
                              size="sm"
                              disabled={targetIsSelf || user.isDeactivated || actionDisabled}
                              onClick={() =>
                                openGovernanceActionDialog(
                                  user,
                                  hasAdmin ? "revoke_admin" : "grant_admin",
                                )
                              }
                            >
                              {actionDisabled ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
                              {hasAdmin ? "Revoke Admin" : "Grant Admin"}
                            </Button>
                          )}

                          {actorCanManageModerators && (
                            <Button
                              variant={hasModerator ? "destructive" : "outline"}
                              size="sm"
                              disabled={targetIsSelf || user.isDeactivated || actionDisabled}
                              onClick={() =>
                                openGovernanceActionDialog(
                                  user,
                                  hasModerator ? "revoke_moderator" : "grant_moderator",
                                )
                              }
                            >
                              {actionDisabled ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
                              {hasModerator ? "Revoke Moderator" : "Grant Moderator"}
                            </Button>
                          )}
                        </div>
                      </TableCell>
                    </TableRow>
                  );
                })}
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
        open={confirmOpen}
        onOpenChange={(nextOpen) => {
          setConfirmOpen(nextOpen);
          if (!nextOpen) {
            setPendingAction(null);
            setConfirmError(null);
            setConfirmNote("");
          }
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Confirm Role Action</DialogTitle>
            <DialogDescription>
              {pendingAction
                ? `Apply ${pendingAction.action.replace("_", " ")} for ${pendingAction.user.email}?`
                : "Confirm role action."}
            </DialogDescription>
          </DialogHeader>
          {pendingAction?.action.startsWith("grant") ? (
            <div className="space-y-2">
              <p className="text-sm text-muted-foreground">
                Optional note for audit log
              </p>
              <Textarea
                rows={3}
                value={confirmNote}
                onChange={(event) => setConfirmNote(event.target.value)}
                placeholder="Reason/context for this role grant"
              />
            </div>
          ) : null}

          {confirmError ? (
            <p className="text-sm text-destructive">{confirmError}</p>
          ) : null}

          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setConfirmOpen(false)}
              disabled={Boolean(actionUserId)}
            >
              Cancel
            </Button>
            <Button
              variant={pendingAction?.action.startsWith("revoke") ? "destructive" : "default"}
              onClick={() => void confirmGovernanceAction()}
              disabled={!pendingAction || Boolean(actionUserId)}
            >
              {actionUserId ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
              Confirm
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
