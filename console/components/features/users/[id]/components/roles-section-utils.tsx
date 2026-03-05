"use client";

import { Badge } from "@/components/ui/badge";
import {
  canManageAdmins,
  canManageCommunityAdmins,
  canManageCommunityModerators,
  canManageHunters,
} from "@/lib/rbac";

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

export type RoleActionEntry = {
  key: string;
  label: string;
  onClick: () => Promise<void>;
  destructive?: boolean;
  hasPermission: boolean;
  requiredRole?: string;
};

type BuildRoleActionEntriesArgs = {
  userRoles: string[];
  actorRoles: string[];
  actorIsOwner: boolean;
  targetIsSelf: boolean;
  canManageRoles: boolean;
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

export function sortRolesTopToLowest(roles: string[]): string[] {
  return [...roles].sort((a, b) => {
    const priorityDiff = (ROLE_PRIORITY[b] ?? 0) - (ROLE_PRIORITY[a] ?? 0);
    if (priorityDiff !== 0) return priorityDiff;
    return a.localeCompare(b);
  });
}

export function roleBadge(role: string) {
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
    case "dev":
      return (
        <Badge className="border-cyan-500/35 bg-cyan-500/10 text-cyan-300 text-xs sm:text-sm">
          Dev
        </Badge>
      );
    case "community_admin":
      return (
        <Badge className="border-indigo-500/25 bg-indigo-500/10 text-indigo-300 text-xs sm:text-sm">
          Community Admin
        </Badge>
      );
    case "community_moderator":
    case "moderator":
      return (
        <Badge className="border-amber-500/20 bg-amber-500/10 text-amber-300 text-xs sm:text-sm">
          Community Moderator
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

export const ROLE_DESCRIPTIONS = [
  {
    key: "owner",
    className: "text-primary",
    label: "Owner:",
    copy: "Full system access, can manage all users and permissions",
  },
  {
    key: "core_team",
    className: "text-sky-300",
    label: "Core Team:",
    copy: "Trusted team members with elevated privileges",
  },
  {
    key: "admin",
    className: "text-teal-300",
    label: "Admin:",
    copy: "Console governance role with operational privileges.",
  },
  {
    key: "community_admin",
    className: "text-indigo-300",
    label: "Community Admin:",
    copy: "Public community identity role; does not grant console access.",
  },
  {
    key: "community_moderator",
    className: "text-amber-300",
    label: "Community Moderator:",
    copy: "Public community moderation identity; no console governance access.",
  },
  {
    key: "hunter",
    className: "text-emerald-300",
    label: "Hunter:",
    copy: "Can hunt and verify projects",
  },
] as const;

export function buildRoleActionEntries({
  userRoles,
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
}: BuildRoleActionEntriesArgs): RoleActionEntry[] {
  if (!canManageRoles) return [];

  const entries: RoleActionEntry[] = [];

  const canManageOwnerRole = actorIsOwner && !targetIsSelf;
  if (userRoles.includes("owner")) {
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

  const canManageCoreTeamRole = actorIsOwner;
  if (userRoles.includes("core_team")) {
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

  const canManageAdminRole = canManageAdmins(actorRoles) && !targetIsSelf;
  if (userRoles.includes("admin")) {
    entries.push({
      key: "revoke-admin",
      label: "Revoke Admin",
      destructive: true,
      onClick: onDemoteAdmin,
      hasPermission: canManageAdminRole,
      requiredRole: "Owner or Dev",
    });
  } else {
    entries.push({
      key: "grant-admin",
      label: "Grant Admin",
      onClick: onPromoteToAdmin,
      hasPermission: canManageAdminRole,
      requiredRole: "Owner or Dev",
    });
  }

  const hasCommunityAdminRole =
    userRoles.includes("community_admin");
  const canManageCommunityAdminRole =
    canManageCommunityAdmins(actorRoles) && !targetIsSelf;
  if (hasCommunityAdminRole) {
    entries.push({
      key: "revoke-community-admin",
      label: "Revoke Community Admin",
      destructive: true,
      onClick: onDemoteCommunityAdmin,
      hasPermission: canManageCommunityAdminRole,
      requiredRole: "Owner, Dev, or Admin",
    });
  } else {
    entries.push({
      key: "grant-community-admin",
      label: "Grant Community Admin",
      onClick: onPromoteToCommunityAdmin,
      hasPermission: canManageCommunityAdminRole,
      requiredRole: "Owner, Dev, or Admin",
    });
  }

  const hasCommunityModeratorRole =
    userRoles.includes("community_moderator") || userRoles.includes("moderator");
  const canManageCommunityModeratorRole =
    canManageCommunityModerators(actorRoles) && !targetIsSelf;
  if (hasCommunityModeratorRole) {
    entries.push({
      key: "revoke-community-moderator",
      label: "Revoke Community Moderator",
      destructive: true,
      onClick: onDemoteCommunityModerator,
      hasPermission: canManageCommunityModeratorRole,
      requiredRole: "Owner, Dev, or Admin",
    });
  } else {
    entries.push({
      key: "grant-community-moderator",
      label: "Grant Community Moderator",
      onClick: onPromoteToCommunityModerator,
      hasPermission: canManageCommunityModeratorRole,
      requiredRole: "Owner, Dev, or Admin",
    });
  }

  const canManageHunterRole = canManageHunters(actorRoles);
  if (userRoles.includes("hunter")) {
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
}
