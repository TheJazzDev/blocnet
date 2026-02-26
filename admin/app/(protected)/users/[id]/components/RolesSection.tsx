"use client";

import { useMemo } from "react";
import { Loader2 } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import type { AdminUserDetail } from "@/lib/api-client";
import { canManageAdmins, canManageHunters, canManageModerators } from "@/lib/rbac";
import { PermissionGate } from "./PermissionGate";

type RolesSectionProps = {
  user: AdminUserDetail;
  actorRoles: string[];
  actorIsOwner: boolean;
  targetIsSelf: boolean;
  canManageRoles: boolean;
  actionLoading: string | null;
  onPromoteToOwner: () => Promise<void>;
  onDemoteOwner: () => Promise<void>;
  onPromoteToCoreTeam: () => Promise<void>;
  onDemoteCoreTeam: () => Promise<void>;
  onPromoteToAdmin: () => Promise<void>;
  onDemoteAdmin: () => Promise<void>;
  onPromoteToModerator: () => Promise<void>;
  onDemoteModerator: () => Promise<void>;
  onPromoteToHunter: () => Promise<void>;
  onDemoteHunter: () => Promise<void>;
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

function roleBadge(role: string) {
  switch (role) {
    case "owner":
      return (
        <Badge className="border-primary/35 bg-primary/15 text-primary text-xs sm:text-sm">
          Owner
        </Badge>
      );
    case "core_team":
      return (
        <Badge className="border-sky-500/25 bg-sky-500/10 text-sky-300 text-xs sm:text-sm">
          Core Team
        </Badge>
      );
    case "admin":
      return (
        <Badge className="border-teal-500/35 bg-teal-500/10 text-teal-300 text-xs sm:text-sm">
          Admin
        </Badge>
      );
    case "moderator":
      return (
        <Badge className="border-amber-500/20 bg-amber-500/10 text-amber-300 text-xs sm:text-sm">
          Moderator
        </Badge>
      );
    case "hunter":
      return (
        <Badge className="border-emerald-500/20 bg-emerald-500/10 text-emerald-300 text-xs sm:text-sm">
          Hunter
        </Badge>
      );
    default:
      return (
        <Badge variant="secondary" className="text-xs sm:text-sm">
          User
        </Badge>
      );
  }
}

export function RolesSection({
  user,
  actorRoles,
  actorIsOwner,
  targetIsSelf,
  canManageRoles,
  actionLoading,
  onPromoteToOwner,
  onDemoteOwner,
  onPromoteToCoreTeam,
  onDemoteCoreTeam,
  onPromoteToAdmin,
  onDemoteAdmin,
  onPromoteToModerator,
  onDemoteModerator,
  onPromoteToHunter,
  onDemoteHunter,
}: RolesSectionProps) {
  const roleButtons = useMemo(() => {
    if (!canManageRoles) return [];

    const entries: Array<{
      key: string;
      label: string;
      onClick: () => Promise<void>;
      destructive?: boolean;
      hasPermission: boolean;
      requiredRole?: string;
    }> = [];

    // Owner role (only owner can grant/revoke, not to self)
    const canManageOwnerRole = actorIsOwner && !targetIsSelf;
    if (user.roles.includes("owner")) {
      entries.push({
        key: "revoke-owner",
        label: "Revoke Owner",
        destructive: true,
        onClick: onDemoteOwner,
        hasPermission: canManageOwnerRole,
        requiredRole: "Owner",
      });
    } else {
      entries.push({
        key: "grant-owner",
        label: "Grant Owner",
        onClick: onPromoteToOwner,
        hasPermission: canManageOwnerRole,
        requiredRole: "Owner",
      });
    }

    // Core Team role (only owner can manage)
    const canManageCoreTeamRole = actorIsOwner;
    if (user.roles.includes("core_team")) {
      entries.push({
        key: "revoke-core-team",
        label: "Revoke Core Team",
        destructive: true,
        onClick: onDemoteCoreTeam,
        hasPermission: canManageCoreTeamRole,
        requiredRole: "Owner",
      });
    } else {
      entries.push({
        key: "grant-core-team",
        label: "Grant Core Team",
        onClick: onPromoteToCoreTeam,
        hasPermission: canManageCoreTeamRole,
        requiredRole: "Owner",
      });
    }

    // Admin role
    const canManageAdminRole = canManageAdmins(actorRoles) && !targetIsSelf;
    if (user.roles.includes("admin")) {
      entries.push({
        key: "revoke-admin",
        label: "Revoke Admin",
        destructive: true,
        onClick: onDemoteAdmin,
        hasPermission: canManageAdminRole,
        requiredRole: "Owner",
      });
    } else {
      entries.push({
        key: "grant-admin",
        label: "Grant Admin",
        onClick: onPromoteToAdmin,
        hasPermission: canManageAdminRole,
        requiredRole: "Owner",
      });
    }

    // Moderator role
    const canManageModeratorRole = canManageModerators(actorRoles) && !targetIsSelf;
    if (user.roles.includes("moderator")) {
      entries.push({
        key: "revoke-moderator",
        label: "Revoke Moderator",
        destructive: true,
        onClick: onDemoteModerator,
        hasPermission: canManageModeratorRole,
        requiredRole: "Owner or Admin",
      });
    } else {
      entries.push({
        key: "grant-moderator",
        label: "Grant Moderator",
        onClick: onPromoteToModerator,
        hasPermission: canManageModeratorRole,
        requiredRole: "Owner or Admin",
      });
    }

    // Hunter role
    const canManageHunterRole = canManageHunters(actorRoles);
    if (user.roles.includes("hunter")) {
      entries.push({
        key: "revoke-hunter",
        label: "Revoke Hunter",
        destructive: true,
        onClick: onDemoteHunter,
        hasPermission: canManageHunterRole,
        requiredRole: "Owner or Admin",
      });
    } else {
      entries.push({
        key: "grant-hunter",
        label: "Grant Hunter",
        onClick: onPromoteToHunter,
        hasPermission: canManageHunterRole,
        requiredRole: "Owner or Admin",
      });
    }

    return entries;
  }, [
    actorIsOwner,
    actorRoles,
    canManageRoles,
    targetIsSelf,
    user.roles,
    onPromoteToOwner,
    onDemoteOwner,
    onPromoteToCoreTeam,
    onDemoteCoreTeam,
    onPromoteToAdmin,
    onDemoteAdmin,
    onPromoteToModerator,
    onDemoteModerator,
    onPromoteToHunter,
    onDemoteHunter,
  ]);

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-sm sm:text-base">Roles & Permissions</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Current Roles */}
        <div>
          <h4 className="text-xs sm:text-sm font-semibold mb-2">Current Roles</h4>
          <div className="flex flex-wrap gap-2">
            {sortRolesTopToLowest(user.roles).map((role) => (
              <span key={role}>{roleBadge(role)}</span>
            ))}
          </div>
        </div>

        <div className="border-t pt-4" />

        {/* Role Management Actions */}
        {canManageRoles && (
          <div>
            <h4 className="text-xs sm:text-sm font-semibold mb-3">Manage Roles</h4>
            <div className="grid gap-2 sm:grid-cols-2">
              {roleButtons.map((entry) => (
                <PermissionGate
                  key={entry.key}
                  hasPermission={entry.hasPermission}
                  requiredRole={entry.requiredRole}
                  showLock={true}
                >
                  <Button
                    size="sm"
                    variant={entry.destructive ? "destructive" : "outline"}
                    disabled={!entry.hasPermission || Boolean(actionLoading)}
                    onClick={entry.onClick}
                    className="w-full text-xs sm:text-sm"
                  >
                    {actionLoading === entry.key ? (
                      <Loader2 className="mr-2 h-3 w-3 sm:h-4 sm:w-4 animate-spin" />
                    ) : null}
                    {entry.label}
                  </Button>
                </PermissionGate>
              ))}
            </div>
          </div>
        )}

        {!canManageRoles && (
          <p className="text-xs sm:text-sm text-muted-foreground">
            You cannot modify roles for this account.
          </p>
        )}

        {/* Role Descriptions */}
        <div className="border-t pt-4">
          <h4 className="text-xs sm:text-sm font-semibold mb-2">Role Descriptions</h4>
          <div className="space-y-2 text-xs sm:text-sm text-muted-foreground">
            <p>
              <strong className="text-primary">Owner:</strong> Full system access, can manage all
              users and permissions
            </p>
            <p>
              <strong className="text-sky-300">Core Team:</strong> Trusted team members with
              elevated privileges
            </p>
            <p>
              <strong className="text-teal-300">Admin:</strong> Can manage users, content, and
              moderate the platform
            </p>
            <p>
              <strong className="text-amber-300">Moderator:</strong> Can moderate content and
              manage community
            </p>
            <p>
              <strong className="text-emerald-300">Hunter:</strong> Can hunt and verify projects
            </p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
