"use client";

import { ArrowLeft, Loader2, RotateCcw, Trash2, AlertTriangle } from "lucide-react";
import Link from "next/link";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import type { AdminUserDetail } from "@/lib/api-client";

type UserDetailsHeaderProps = {
  user: AdminUserDetail;
  actorIsOwner: boolean;
  canManageAccount: boolean;
  targetIsSelf: boolean;
  actionLoading: string | null;
  onRefresh: () => void;
  onDeactivate: () => void;
  onReactivate: () => void;
  onHardDelete: () => void;
};

const ROLE_PRIORITY: Record<string, number> = {
  owner: 9,
  dev: 8,
  admin: 7,
  core_team: 6,
  community_admin: 5,
  community_moderator: 4,
  moderator: 4,
  hunter: 3,
  user: 1,
};

function sortRolesTopToLowest(roles: string[]): string[] {
  return [...roles].sort((a, b) => {
    const priorityDiff = (ROLE_PRIORITY[b] ?? 0) - (ROLE_PRIORITY[a] ?? 0);
    if (priorityDiff !== 0) return priorityDiff;
    return a.localeCompare(b);
  });
}

function roleBadge(role: string) {
  switch (role) {
    case "owner":
      return <Badge className="border-primary/35 bg-primary/15 text-primary text-xs">Owner</Badge>;
    case "core_team":
      return <Badge className="border-sky-500/25 bg-sky-500/10 text-sky-300 text-xs">Core Team</Badge>;
    case "admin":
      return <Badge className="border-teal-500/35 bg-teal-500/10 text-teal-300 text-xs">Admin</Badge>;
    case "dev":
      return <Badge className="border-cyan-500/35 bg-cyan-500/10 text-cyan-300 text-xs">Dev</Badge>;
    case "community_admin":
      return (
        <Badge className="border-indigo-500/30 bg-indigo-500/10 text-indigo-300 text-xs">
          Community Admin
        </Badge>
      );
    case "community_moderator":
    case "moderator":
      return (
        <Badge className="border-amber-500/20 bg-amber-500/10 text-amber-300 text-xs">
          Community Moderator
        </Badge>
      );
    case "hunter":
      return <Badge className="border-emerald-500/20 bg-emerald-500/10 text-emerald-300 text-xs">Hunter</Badge>;
    default:
      return <Badge variant="secondary" className="text-xs">User</Badge>;
  }
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

export function UserDetailsHeader({
  user,
  actorIsOwner,
  canManageAccount,
  targetIsSelf,
  actionLoading,
  onRefresh,
  onDeactivate,
  onReactivate,
  onHardDelete,
}: UserDetailsHeaderProps) {
  const sortedRoles = sortRolesTopToLowest(user.roles);

  return (
    <div className="sticky top-0 z-10 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 border-b pb-4 sm:pb-6">
      <div className="flex items-center justify-between mb-3 sm:mb-4">
        <Button variant="outline" size="sm" asChild>
          <Link href="/users">
            <ArrowLeft className="mr-2 h-3 w-3 sm:h-4 sm:w-4" />
            <span className="text-xs sm:text-sm">Back to Users</span>
          </Link>
        </Button>
        <Button variant="outline" size="sm" onClick={onRefresh}>
          <RotateCcw className="h-3 w-3 sm:h-4 sm:w-4" />
        </Button>
      </div>

      <Card>
        <CardContent className="p-4 sm:p-6">
          <div className="flex flex-col sm:flex-row gap-4 sm:gap-6">
            {/* Avatar and Identity */}
            <div className="flex items-start gap-3 sm:gap-4">
              <Avatar className="h-16 w-16 sm:h-20 sm:w-20 shrink-0">
                {user.avatarUrl ? (
                  <AvatarImage src={user.avatarUrl} alt={user.displayName ?? user.email} />
                ) : null}
                <AvatarFallback className="text-lg sm:text-xl">
                  {getInitials(user.displayName, user.email)}
                </AvatarFallback>
              </Avatar>
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2 flex-wrap">
                  <h1 className="text-lg sm:text-xl md:text-2xl font-bold truncate">
                    {user.displayName ?? "Unnamed User"}
                  </h1>
                  {user.isDeactivated ? (
                    <Badge className="bg-red-500/15 text-red-300 text-xs shrink-0">Deactivated</Badge>
                  ) : (
                    <Badge className="bg-emerald-500/15 text-emerald-300 text-xs shrink-0">Active</Badge>
                  )}
                </div>
                <p className="text-xs sm:text-sm text-muted-foreground mt-1">{user.email}</p>
                {user.username && (
                  <p className="text-xs sm:text-sm text-muted-foreground">@{user.username}</p>
                )}
                <div className="flex flex-wrap gap-1.5 mt-2">
                  {sortedRoles.map((role) => (
                    <span key={role}>{roleBadge(role)}</span>
                  ))}
                </div>
              </div>
            </div>

            {/* Quick Stats */}
            <div className="grid grid-cols-3 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4 sm:ml-auto">
              <div className="text-center sm:text-right">
                <p className="text-xl sm:text-2xl font-bold">{user.counts.followers}</p>
                <p className="text-xs text-muted-foreground">Followers</p>
              </div>
              <div className="text-center sm:text-right">
                <p className="text-xl sm:text-2xl font-bold">{user.counts.updates}</p>
                <p className="text-xs text-muted-foreground">Updates</p>
              </div>
              <div className="text-center sm:text-right">
                <p className="text-xl sm:text-2xl font-bold">{user.counts.badges}</p>
                <p className="text-xs text-muted-foreground">Badges</p>
              </div>
            </div>
          </div>

          {/* Primary Badge */}
          {user.primaryBadge && (
            <div className="mt-4 pt-4 border-t">
              <div className="flex items-center gap-2">
                <span className="text-xs text-muted-foreground">Primary Badge:</span>
                <Badge variant="outline" className="text-xs">
                  {user.primaryBadge.name}
                </Badge>
                <Badge className="bg-purple-500/10 text-purple-300 border-purple-500/20 text-xs">
                  {user.primaryBadge.rarity}
                </Badge>
              </div>
            </div>
          )}

          {/* Quick Actions */}
          {(canManageAccount || actorIsOwner) && (
            <div className="flex flex-wrap gap-2 mt-4 pt-4 border-t">
              {canManageAccount && !targetIsSelf && !user.isDeactivated && (
                <Button
                  variant="destructive"
                  size="sm"
                  disabled={Boolean(actionLoading)}
                  onClick={onDeactivate}
                >
                  {actionLoading === "deactivate" ? (
                    <Loader2 className="mr-2 h-3 w-3 sm:h-4 sm:w-4 animate-spin" />
                  ) : (
                    <Trash2 className="mr-2 h-3 w-3 sm:h-4 sm:w-4" />
                  )}
                  <span className="text-xs sm:text-sm">Deactivate</span>
                </Button>
              )}

              {actorIsOwner && !targetIsSelf && user.isDeactivated && (
                <>
                  <Button
                    variant="outline"
                    size="sm"
                    disabled={Boolean(actionLoading)}
                    onClick={onReactivate}
                  >
                    {actionLoading === "reactivate" ? (
                      <Loader2 className="mr-2 h-3 w-3 sm:h-4 sm:w-4 animate-spin" />
                    ) : (
                      <RotateCcw className="mr-2 h-3 w-3 sm:h-4 sm:w-4" />
                    )}
                    <span className="text-xs sm:text-sm">Reactivate</span>
                  </Button>
                  <Button
                    variant="destructive"
                    size="sm"
                    disabled={Boolean(actionLoading)}
                    onClick={onHardDelete}
                  >
                    {actionLoading === "hard-delete" ? (
                      <Loader2 className="mr-2 h-3 w-3 sm:h-4 sm:w-4 animate-spin" />
                    ) : (
                      <AlertTriangle className="mr-2 h-3 w-3 sm:h-4 sm:w-4" />
                    )}
                    <span className="text-xs sm:text-sm">Hard Delete</span>
                  </Button>
                </>
              )}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
