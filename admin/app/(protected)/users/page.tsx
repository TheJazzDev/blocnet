"use client";

import { useEffect, useMemo, useState } from "react";
import {
  ShieldCheck,
  Shield,
  Pen,
  User,
  MoreHorizontal,
  Loader2,
  ShieldAlert,
  Search,
  ChevronLeft,
  ChevronRight,
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
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
} from "@/lib/rbac";

type RoleFilter = "all" | "user" | "hunter" | "moderator" | "admin" | "owner";

function roleBadge(role: string) {
  switch (role) {
    case "owner":
      return (
        <Badge className="border-purple-500/20 bg-purple-500/10 text-purple-400" variant="outline">
          <ShieldCheck className="mr-1 h-3 w-3" />
          Owner
        </Badge>
      );
    case "admin":
      return (
        <Badge className="border-blue-500/20 bg-blue-500/10 text-blue-400" variant="outline">
          <Shield className="mr-1 h-3 w-3" />
          Admin
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

function getInitials(name: string | null, email: string) {
  const source = name ?? email;
  return source
    .split(/[\s@]/)
    .filter(Boolean)
    .map((w) => w[0])
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

function TableSkeleton() {
  return (
    <div className="space-y-3">
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} className="flex items-center gap-4 py-2">
          <Skeleton className="h-8 w-8 rounded-full" />
          <div className="space-y-1">
            <Skeleton className="h-4 w-28" />
            <Skeleton className="h-3 w-36" />
          </div>
          <Skeleton className="ml-auto h-5 w-16" />
          <Skeleton className="h-4 w-8" />
          <Skeleton className="h-4 w-8" />
          <Skeleton className="h-4 w-20" />
        </div>
      ))}
    </div>
  );
}

function UserRoleActions({
  user,
  currentUserId,
  currentRoles,
  onSuccess,
}: {
  user: AdminUser;
  currentUserId: string;
  currentRoles: string[];
  onSuccess: () => void;
}) {
  const [loading, setLoading] = useState(false);
  const canAdmins = canManageAdmins(currentRoles);
  const canModerators = canManageModerators(currentRoles);
  const canHunters = canManageHunters(currentRoles);

  if (!canAdmins && !canModerators && !canHunters) return null;
  if (user.id === currentUserId) return null;
  if (user.roles.includes("owner")) return null;

  const hasAdmin = user.roles.includes("admin");
  const hasModerator = user.roles.includes("moderator");
  const hasHunter = user.roles.includes("hunter");

  const actions: Array<{
    key: string;
    label: string;
    action: () => Promise<unknown>;
    destructive?: boolean;
  }> = [];

  if (canAdmins) {
    if (hasAdmin) {
      actions.push({
        key: "demote-admin",
        label: "Revoke Admin",
        action: () => clientApi.demoteAdmin(user.id),
        destructive: true,
      });
    } else {
      actions.push({
        key: "promote-admin",
        label: "Grant Admin",
        action: () => clientApi.promoteToAdmin(user.id),
      });
    }
  }

  if (canModerators) {
    if (hasModerator) {
      actions.push({
        key: "demote-moderator",
        label: "Revoke Moderator",
        action: () => clientApi.demoteModerator(user.id),
        destructive: true,
      });
    } else {
      actions.push({
        key: "promote-moderator",
        label: "Grant Moderator",
        action: () => clientApi.promoteToModerator(user.id),
      });
    }
  }

  if (canHunters) {
    if (hasHunter) {
      actions.push({
        key: "demote-hunter",
        label: "Revoke Hunter",
        action: () => clientApi.demoteHunter(user.id),
        destructive: true,
      });
    } else {
      actions.push({
        key: "promote-hunter",
        label: "Grant Hunter",
        action: () => clientApi.promoteToHunter(user.id),
      });
    }
  }

  if (actions.length === 0) return null;

  async function run(action: () => Promise<unknown>) {
    setLoading(true);
    try {
      await action();
      onSuccess();
    } finally {
      setLoading(false);
    }
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon" className="h-8 w-8" disabled={loading}>
          {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <MoreHorizontal className="h-4 w-4" />}
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuLabel>Manage Roles</DropdownMenuLabel>
        <DropdownMenuSeparator />
        {actions.map((item) => (
          <DropdownMenuItem
            key={item.key}
            className={item.destructive ? "text-destructive" : ""}
            onClick={() => run(item.action)}
          >
            {item.label}
          </DropdownMenuItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

export default function UsersPage() {
  const session = useAdminSession();
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [searchInput, setSearchInput] = useState("");
  const [q, setQ] = useState("");
  const [role, setRole] = useState<RoleFilter>("all");
  const [limit, setLimit] = useState(25);
  const [offset, setOffset] = useState(0);

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
      .listUsers({ limit, offset, role, q })
      .then((result) => {
        setUsers(result.data);
        setTotal(result.total);
      })
      .catch((e: unknown) => {
        setUsers([]);
        setTotal(0);
        setError(e instanceof Error ? e.message : "Failed to load users");
      })
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [limit, offset, role, q]);

  const stats = useMemo(() => {
    const admins = users.filter((u) => u.roles.includes("admin")).length;
    const moderators = users.filter((u) => u.roles.includes("moderator")).length;
    const hunters = users.filter((u) => u.roles.includes("hunter")).length;
    const regularUsers = users.filter(
      (u) => u.roles.length === 0 || (u.roles.length === 1 && u.roles[0] === "user"),
    ).length;
    return { admins, moderators, hunters, regularUsers };
  }, [users]);

  const pageStart = total === 0 ? 0 : offset + 1;
  const pageEnd = Math.min(offset + users.length, total);
  const canPrev = offset > 0;
  const canNext = offset + limit < total;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Users & Roles"
        description="Search members, filter by role, and manage admin, moderator, and hunter access."
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
        <Card>
          <CardContent className="pt-6">
            <p className="text-sm text-muted-foreground">Total Results</p>
            <p className="text-2xl font-bold">{total}</p>
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
        <Card>
          <CardContent className="pt-6">
            <p className="text-sm text-muted-foreground">Hunters (page)</p>
            <p className="text-2xl font-bold">{stats.hunters}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <p className="text-sm text-muted-foreground">Regular (page)</p>
            <p className="text-2xl font-bold">{stats.regularUsers}</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Directory</CardTitle>
          <div className="mt-3 flex flex-col gap-3 md:flex-row">
            <div className="relative flex-1">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
                className="pl-9"
                placeholder="Search email, name, or user ID"
              />
            </div>
            <Select
              value={role}
              onValueChange={(next) => {
                setRole(next as RoleFilter);
                setOffset(0);
              }}
            >
              <SelectTrigger className="w-full md:w-[220px]">
                <SelectValue placeholder="Filter role" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Roles</SelectItem>
                <SelectItem value="user">User</SelectItem>
                <SelectItem value="hunter">Hunter</SelectItem>
                <SelectItem value="moderator">Moderator</SelectItem>
                <SelectItem value="admin">Admin</SelectItem>
                <SelectItem value="owner">Owner</SelectItem>
              </SelectContent>
            </Select>
            <Select
              value={String(limit)}
              onValueChange={(next) => {
                setLimit(Number(next));
                setOffset(0);
              }}
            >
              <SelectTrigger className="w-full md:w-[140px]">
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
            <TableSkeleton />
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
                  <TableHead className="text-right">Projects</TableHead>
                  <TableHead className="text-right">Updates</TableHead>
                  <TableHead className="text-right">Joined</TableHead>
                  <TableHead className="w-[40px]" />
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
                          <p className="truncate text-xs text-muted-foreground">{user.email}</p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex flex-wrap gap-1">
                        {user.roles.length === 0 ? (
                          <Badge variant="secondary">
                            <User className="mr-1 h-3 w-3" />
                            User
                          </Badge>
                        ) : (
                          user.roles.map((entry) => <span key={entry}>{roleBadge(entry)}</span>)
                        )}
                      </div>
                    </TableCell>
                    <TableCell className="text-right">{user.projectsAssigned}</TableCell>
                    <TableCell className="text-right">{user.updatesPosted}</TableCell>
                    <TableCell className="text-right text-sm text-muted-foreground">
                      {formatDate(user.createdAt)}
                    </TableCell>
                    <TableCell>
                      <UserRoleActions
                        user={user}
                        currentUserId={session.id}
                        currentRoles={session.roles}
                        onSuccess={load}
                      />
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
    </div>
  );
}
