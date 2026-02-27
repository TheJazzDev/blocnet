"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { ChevronLeft, ChevronRight, Search } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
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
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { clientApi, type AdminUser } from "@/lib/api-client";

type RoleFilter = "all" | "user" | "hunter" | "core_team";
type StatusFilter = "all" | "active" | "deactivated";

function roleBadge(role: "core_team" | "hunter" | "user") {
  if (role === "core_team") {
    return (
      <Badge
        className="border-sky-500/25 bg-sky-500/10 text-sky-300"
        variant="outline"
      >
        Core Team
      </Badge>
    );
  }

  if (role === "hunter") {
    return (
      <Badge
        className="border-emerald-500/20 bg-emerald-500/10 text-emerald-400"
        variant="outline"
      >
        Hunter
      </Badge>
    );
  }

  return <Badge variant="secondary">User</Badge>;
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

function getHighestMemberRole(roles: string[]): "core_team" | "hunter" | "user" {
  if (roles.includes("core_team")) return "core_team";
  if (roles.includes("hunter")) return "hunter";
  return "user";
}

export default function UsersPage() {
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
      setError(e instanceof Error ? e.message : "Failed to load members");
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
    const coreTeam = users.filter((entry) => entry.roles.includes("core_team")).length;
    const hunters = users.filter((entry) => entry.roles.includes("hunter")).length;
    return { active, deactivated, coreTeam, hunters };
  }, [users]);

  const pageStart = total === 0 ? 0 : offset + 1;
  const pageEnd = Math.min(offset + users.length, total);
  const canPrev = offset > 0;
  const canNext = offset + limit < total;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Members"
        description="Directory for all application users. Open Manage to edit full profile, roles, badges, referral, wallet, and activity details."
      >
        <Button variant="outline" size="sm" asChild>
          <Link href="/admin-access">Manage Admin Panel Access</Link>
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
            <p className="text-sm text-muted-foreground">Hunters (page)</p>
            <p className="text-2xl font-bold">{stats.hunters}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <p className="text-sm text-muted-foreground">Core Team (page)</p>
            <p className="text-2xl font-bold">{stats.coreTeam}</p>
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
                <SelectItem value="core_team">Core Team</SelectItem>
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
                  <TableHead>Member Role</TableHead>
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
                    <TableCell>{roleBadge(getHighestMemberRole(user.roles))}</TableCell>
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
    </div>
  );
}
