"use client";

import { useMemo } from "react";
import { Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import type { AdminUserDetail } from "@/lib/api-client";
import { PermissionGate } from "./PermissionGate";
import {
  buildRoleActionEntries,
  ROLE_DESCRIPTIONS,
  roleBadge,
  sortRolesTopToLowest,
} from "./roles-section-utils";

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
  onPromoteToCommunityAdmin: () => Promise<void>;
  onDemoteCommunityAdmin: () => Promise<void>;
  onPromoteToCommunityModerator: () => Promise<void>;
  onDemoteCommunityModerator: () => Promise<void>;
  onPromoteToHunter: () => Promise<void>;
  onDemoteHunter: () => Promise<void>;
};

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
  onPromoteToCommunityAdmin,
  onDemoteCommunityAdmin,
  onPromoteToCommunityModerator,
  onDemoteCommunityModerator,
  onPromoteToHunter,
  onDemoteHunter,
}: RolesSectionProps) {
  const roleButtons = useMemo(() => {
    return buildRoleActionEntries({
      userRoles: user.roles,
      actorRoles,
      actorIsOwner,
      targetIsSelf,
      canManageRoles,
      onPromoteToOwner,
      onDemoteOwner,
      onPromoteToCoreTeam,
      onDemoteCoreTeam,
      onPromoteToAdmin,
      onDemoteAdmin,
      onPromoteToCommunityAdmin,
      onDemoteCommunityAdmin,
      onPromoteToCommunityModerator,
      onDemoteCommunityModerator,
      onPromoteToHunter,
      onDemoteHunter,
    });
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
    onPromoteToCommunityAdmin,
    onDemoteCommunityAdmin,
    onPromoteToCommunityModerator,
    onDemoteCommunityModerator,
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
            {ROLE_DESCRIPTIONS.map((role) => (
              <p key={role.key}>
                <strong className={role.className}>{role.label}</strong> {role.copy}
              </p>
            ))}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
