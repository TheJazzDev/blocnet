"use client";

import { useEffect, useState } from "react";
import {
  ShieldCheck,
  Shield,
  Pen,
  User,
  MoreHorizontal,
  ChevronUp,
  Loader2,
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
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
import { clientApi, type AdminUser } from "@/lib/api-client";

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
    case "poster":
      return (
        <Badge className="border-emerald-500/20 bg-emerald-500/10 text-emerald-400" variant="outline">
          <Pen className="mr-1 h-3 w-3" />
          Poster
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
  const str = name ?? email;
  return str
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

function UserRoleActions({
  user,
  onRefresh,
}: {
  user: AdminUser;
  onRefresh: () => void;
}) {
  const [loading, setLoading] = useState(false);

  const isOwner = user.roles.includes("owner");
  const isAdmin = user.roles.includes("admin");
  const isPoster = user.roles.includes("poster");

  if (isOwner || (isAdmin && isPoster)) return null;

  async function promote(target: "admin" | "poster") {
    setLoading(true);
    try {
      if (target === "admin") {
        await clientApi.promoteToAdmin(user.id);
      } else {
        await clientApi.promoteToPoster(user.id);
      }
      onRefresh();
    } finally {
      setLoading(false);
    }
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon" className="h-8 w-8" disabled={loading}>
          {loading ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            <MoreHorizontal className="h-4 w-4" />
          )}
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuLabel>Manage Role</DropdownMenuLabel>
        <DropdownMenuSeparator />
        {!isAdmin && (
          <DropdownMenuItem onClick={() => promote("admin")}>
            <ChevronUp className="h-4 w-4" />
            Promote to Admin
          </DropdownMenuItem>
        )}
        {!isPoster && (
          <DropdownMenuItem onClick={() => promote("poster")}>
            <ChevronUp className="h-4 w-4" />
            Promote to Poster
          </DropdownMenuItem>
        )}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

function StatCardSkeleton() {
  return (
    <Card>
      <CardContent className="pt-6">
        <div className="flex items-center justify-between">
          <div className="space-y-2">
            <Skeleton className="h-3 w-20" />
            <Skeleton className="h-8 w-12" />
          </div>
          <Skeleton className="h-10 w-10 rounded-full" />
        </div>
      </CardContent>
    </Card>
  );
}

function TableSkeleton() {
  return (
    <div className="space-y-3">
      {Array.from({ length: 6 }).map((_, i) => (
        <div key={i} className="flex items-center gap-4 py-2">
          <Skeleton className="h-8 w-8 rounded-full" />
          <div className="space-y-1">
            <Skeleton className="h-4 w-28" />
            <Skeleton className="h-3 w-36" />
          </div>
          <Skeleton className="ml-auto h-5 w-14" />
          <Skeleton className="h-4 w-8" />
          <Skeleton className="h-4 w-8" />
          <Skeleton className="h-4 w-20" />
        </div>
      ))}
    </div>
  );
}

export default function UsersPage() {
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);

  function load() {
    setLoading(true);
    clientApi
      .listUsers({ limit: 100 })
      .then((result) => {
        setUsers(result.data);
        setTotal(result.total);
      })
      .catch(() => {
        setUsers([]);
        setTotal(0);
      })
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
  }, []);

  const admins = users.filter((u) => u.roles.includes("admin")).length;
  const posters = users.filter((u) => u.roles.includes("poster")).length;
  const regularUsers = users.filter(
    (u) => u.roles.length === 0 || (u.roles.length === 1 && u.roles[0] === "user")
  ).length;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Users & Roles"
        description="Manage user roles and permissions across the platform."
      />

      {/* Role summary cards */}
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {loading ? (
          Array.from({ length: 4 }).map((_, i) => <StatCardSkeleton key={i} />)
        ) : (
          <>
            <Card>
              <CardContent className="pt-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-muted-foreground">Total Users</p>
                    <p className="text-2xl font-bold">{total}</p>
                  </div>
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-secondary">
                    <User className="h-5 w-5 text-muted-foreground" />
                  </div>
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-muted-foreground">Admins</p>
                    <p className="text-2xl font-bold">{admins}</p>
                  </div>
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-blue-500/10">
                    <Shield className="h-5 w-5 text-blue-400" />
                  </div>
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-muted-foreground">Posters</p>
                    <p className="text-2xl font-bold">{posters}</p>
                  </div>
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-emerald-500/10">
                    <Pen className="h-5 w-5 text-emerald-400" />
                  </div>
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-muted-foreground">Regular Users</p>
                    <p className="text-2xl font-bold">{regularUsers}</p>
                  </div>
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-secondary">
                    <User className="h-5 w-5 text-muted-foreground" />
                  </div>
                </div>
              </CardContent>
            </Card>
          </>
        )}
      </div>

      {/* Users table */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">
            All Users
            <span className="ml-2 text-sm font-normal text-muted-foreground">
              ({loading ? "…" : `${users.length} shown`})
            </span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <TableSkeleton />
          ) : users.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">
              No users found. Make sure the backend is running.
            </p>
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
                        <div>
                          <p className="font-medium">
                            {user.displayName ?? user.email.split("@")[0]}
                          </p>
                          <p className="text-xs text-muted-foreground">
                            {user.email}
                          </p>
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
                          user.roles.map((role) => (
                            <span key={role}>{roleBadge(role)}</span>
                          ))
                        )}
                      </div>
                    </TableCell>
                    <TableCell className="text-right">
                      {user.projectsAssigned}
                    </TableCell>
                    <TableCell className="text-right">
                      {user.updatesPosted}
                    </TableCell>
                    <TableCell className="text-right text-sm text-muted-foreground">
                      {formatDate(user.createdAt)}
                    </TableCell>
                    <TableCell>
                      <UserRoleActions user={user} onRefresh={load} />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
