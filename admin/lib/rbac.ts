export type AdminPanelRole = "owner" | "admin" | "moderator";
export type SpaceRole = "user" | "hunter";
export type RoleCapabilitySectionId =
  | "overview"
  | "content"
  | "wallet"
  | "engagement"
  | "access"
  | "system";

export interface GovernanceRoleDefinition {
  role: AdminPanelRole;
  label: string;
  description: string;
  order: number;
}

export interface SpaceRoleDefinition {
  role: SpaceRole;
  label: string;
  description: string;
}

export interface RoleCapabilityDefinition {
  key: string;
  label: string;
  description: string;
  section: RoleCapabilitySectionId;
  roles: AdminPanelRole[];
}

export interface RoleCapabilitySection {
  id: RoleCapabilitySectionId;
  label: string;
  description: string;
}

export interface RoleMatrixSection extends RoleCapabilitySection {
  capabilities: RoleCapabilityDefinition[];
}

export interface RolesMatrixResponse {
  governanceRoles: GovernanceRoleDefinition[];
  sections: RoleMatrixSection[];
  spaceRoles: SpaceRoleDefinition[];
}

export const ROLE_VIEW_COOKIE = "admin_view_as_role";

const GOVERNANCE_ROLE_PRIORITY: Record<AdminPanelRole, number> = {
  owner: 3,
  admin: 2,
  moderator: 1,
};

export const GOVERNANCE_ROLES: GovernanceRoleDefinition[] = [
  {
    role: "owner",
    label: "Owner",
    description: "Highest authority with full governance and configuration control.",
    order: 1,
  },
  {
    role: "admin",
    label: "Admin",
    description: "Operational administrator with broad management privileges.",
    order: 2,
  },
  {
    role: "moderator",
    label: "Moderator",
    description: "Content and operations reviewer with limited mutation permissions.",
    order: 3,
  },
];

export const SPACE_ROLES: SpaceRoleDefinition[] = [
  {
    role: "user",
    label: "User",
    description: "Base platform identity role. Every account has user access.",
  },
  {
    role: "hunter",
    label: "Hunter",
    description: "Space/capability role for user-hunter flows, not admin governance.",
  },
];

export const CAPABILITY_SECTIONS: RoleCapabilitySection[] = [
  {
    id: "overview",
    label: "Overview",
    description: "Dashboard visibility and top-level operational context.",
  },
  {
    id: "content",
    label: "Content",
    description: "Projects, updates, comments, community, and tag operations.",
  },
  {
    id: "wallet",
    label: "Wallet",
    description: "Wallet health, users, KYC/withdrawals, and risk controls.",
  },
  {
    id: "engagement",
    label: "Engagement",
    description: "Mining configuration, metrics, and referral administration.",
  },
  {
    id: "access",
    label: "Access",
    description: "User lifecycle management, role management, and applications.",
  },
  {
    id: "system",
    label: "System",
    description: "Audit visibility, notifications, and global settings.",
  },
];

export const ROLE_CAPABILITIES: RoleCapabilityDefinition[] = [
  {
    key: "overview.dashboard.view",
    label: "View Dashboard",
    description: "Access dashboard statistics, activity, and health summaries.",
    section: "overview",
    roles: ["owner", "admin", "moderator"],
  },
  {
    key: "content.projects.moderate",
    label: "Moderate Projects",
    description: "Review and change project status for moderation workflows.",
    section: "content",
    roles: ["owner", "admin", "moderator"],
  },
  {
    key: "content.projects.pause",
    label: "Pause Projects",
    description: "Set project status to paused (reserved for owner/admin authority).",
    section: "content",
    roles: ["owner", "admin"],
  },
  {
    key: "content.updates.moderate",
    label: "Moderate Updates",
    description: "Review and update visibility status of project updates.",
    section: "content",
    roles: ["owner", "admin", "moderator"],
  },
  {
    key: "content.comments.moderate",
    label: "Moderate Comments",
    description: "Review and moderate update comments across the platform.",
    section: "content",
    roles: ["owner", "admin", "moderator"],
  },
  {
    key: "content.community.moderate",
    label: "Moderate Community",
    description: "Review and moderate community posts and community comments.",
    section: "content",
    roles: ["owner", "admin", "moderator"],
  },
  {
    key: "content.tags.manage",
    label: "Manage Tags",
    description: "Create and update primary/secondary taxonomy tags.",
    section: "content",
    roles: ["owner", "admin"],
  },
  {
    key: "wallet.health.view",
    label: "View Wallet Health",
    description: "See wallet provider and settlement health indicators.",
    section: "wallet",
    roles: ["owner", "admin", "moderator"],
  },
  {
    key: "wallet.users.view",
    label: "View Wallet Users",
    description: "Browse wallet users, balances, and account risk context.",
    section: "wallet",
    roles: ["owner", "admin", "moderator"],
  },
  {
    key: "wallet.withdrawals.review",
    label: "Review Withdrawals",
    description: "Approve or reject withdrawal requests.",
    section: "wallet",
    roles: ["owner", "admin"],
  },
  {
    key: "wallet.kyc.review",
    label: "Review KYC",
    description: "Approve or reject wallet KYC submissions.",
    section: "wallet",
    roles: ["owner", "admin"],
  },
  {
    key: "wallet.settings.mutate",
    label: "Mutate Wallet Settings",
    description: "Edit wallet risk limits, fee configs, and asset pricing.",
    section: "wallet",
    roles: ["owner", "admin"],
  },
  {
    key: "engagement.mining.view",
    label: "View Mining Config/Metrics",
    description: "Read mining configuration and mining metrics.",
    section: "engagement",
    roles: ["owner", "admin", "moderator"],
  },
  {
    key: "engagement.mining.mutate",
    label: "Mutate Mining Config",
    description: "Update mining coefficients and related operational settings.",
    section: "engagement",
    roles: ["owner", "admin"],
  },
  {
    key: "engagement.referrals.bind",
    label: "Bind Referrals",
    description: "Run admin referral bind overrides.",
    section: "engagement",
    roles: ["owner", "admin"],
  },
  {
    key: "access.users.view",
    label: "View Users",
    description: "Search users and inspect profile/account status.",
    section: "access",
    roles: ["owner", "admin", "moderator"],
  },
  {
    key: "access.users.edit_profile",
    label: "Edit User Profiles",
    description: "Edit profile fields for managed users.",
    section: "access",
    roles: ["owner", "admin"],
  },
  {
    key: "access.users.deactivate",
    label: "Deactivate Users",
    description: "Deactivate user accounts and revoke sessions.",
    section: "access",
    roles: ["owner", "admin"],
  },
  {
    key: "access.users.reactivate",
    label: "Reactivate Users",
    description: "Reactivate deactivated user accounts.",
    section: "access",
    roles: ["owner"],
  },
  {
    key: "access.users.hard_delete",
    label: "Hard Delete Users",
    description: "Permanently remove user accounts and linked records.",
    section: "access",
    roles: ["owner"],
  },
  {
    key: "access.roles.admin.manage",
    label: "Manage Admin Role",
    description: "Grant or revoke admin role assignments.",
    section: "access",
    roles: ["owner"],
  },
  {
    key: "access.roles.moderator.manage",
    label: "Manage Moderator Role",
    description: "Grant or revoke moderator role assignments.",
    section: "access",
    roles: ["owner", "admin"],
  },
  {
    key: "access.roles.hunter.manage",
    label: "Manage Hunter Role",
    description: "Grant or revoke hunter role assignments.",
    section: "access",
    roles: ["owner", "admin"],
  },
  {
    key: "access.applications.admin.review",
    label: "Review Admin Applications",
    description: "Approve or reject admin role applications.",
    section: "access",
    roles: ["owner"],
  },
  {
    key: "access.applications.proposal.review",
    label: "Review Project Proposals",
    description: "Approve or reject project proposals.",
    section: "access",
    roles: ["owner", "admin", "moderator"],
  },
  {
    key: "system.audit_log.view",
    label: "View Audit Log",
    description: "Read audit events across admin operations.",
    section: "system",
    roles: ["owner", "admin", "moderator"],
  },
  {
    key: "system.notifications.send",
    label: "Send Notifications",
    description: "Broadcast push and in-app notifications.",
    section: "system",
    roles: ["owner", "admin"],
  },
  {
    key: "system.settings.mutate",
    label: "Mutate Settings",
    description: "Update global admin panel configuration settings.",
    section: "system",
    roles: ["owner"],
  },
];

export function hasRole(roles: string[], role: string): boolean {
  return roles.includes(role);
}

export function normalizeAdminPanelRole(
  value: string | null | undefined,
): AdminPanelRole | null {
  if (!value) return null;
  const normalized = value.trim().toLowerCase();
  if (normalized === "owner" || normalized === "admin" || normalized === "moderator") {
    return normalized;
  }
  return null;
}

export function getAdminGovernanceRole(roles: string[]): AdminPanelRole | null {
  let selected: AdminPanelRole | null = null;
  for (const role of roles) {
    const normalized = normalizeAdminPanelRole(role);
    if (!normalized) continue;
    if (!selected || GOVERNANCE_ROLE_PRIORITY[normalized] > GOVERNANCE_ROLE_PRIORITY[selected]) {
      selected = normalized;
    }
  }
  return selected;
}

export function getRoleViewOptions(realRoles: string[]): AdminPanelRole[] {
  const topRole = getAdminGovernanceRole(realRoles);
  switch (topRole) {
    case "owner":
      return ["owner", "admin", "moderator"];
    case "admin":
      return ["admin", "moderator"];
    case "moderator":
      return ["moderator"];
    default:
      return [];
  }
}

export function resolveEffectiveRoles(
  realRoles: string[],
  requestedViewRole: string | null | undefined,
): string[] {
  const uniqueRealRoles = Array.from(new Set(realRoles));
  const topRole = getAdminGovernanceRole(uniqueRealRoles);
  const requested = normalizeAdminPanelRole(requestedViewRole);
  const options = getRoleViewOptions(uniqueRealRoles);

  if (!requested || !options.includes(requested) || requested === topRole) {
    return uniqueRealRoles;
  }

  const nonGovernanceRoles = uniqueRealRoles.filter((role) => !normalizeAdminPanelRole(role));
  return Array.from(new Set([...nonGovernanceRoles, requested]));
}

export function canAccessAdminPanel(roles: string[]): boolean {
  return roles.some((role) => role === "owner" || role === "admin" || role === "moderator");
}

export function canManageAdmins(roles: string[]): boolean {
  return hasRole(roles, "owner");
}

export function canManageModerators(roles: string[]): boolean {
  return hasRole(roles, "owner") || hasRole(roles, "admin");
}

export function canManageHunters(roles: string[]): boolean {
  return hasRole(roles, "owner") || hasRole(roles, "admin");
}

export function canReviewAdminApplications(roles: string[]): boolean {
  return hasRole(roles, "owner");
}

export function canReviewProjectProposals(roles: string[]): boolean {
  return canAccessAdminPanel(roles);
}

export function canManageTags(roles: string[]): boolean {
  return hasRole(roles, "owner") || hasRole(roles, "admin");
}

export function canMutateSettings(roles: string[]): boolean {
  return hasRole(roles, "owner");
}

export function canSendNotifications(roles: string[]): boolean {
  return hasRole(roles, "owner") || hasRole(roles, "admin");
}

export function canMutateWallet(roles: string[]): boolean {
  return hasRole(roles, "owner") || hasRole(roles, "admin");
}

export function isModeratorOnly(roles: string[]): boolean {
  return hasRole(roles, "moderator") && !hasRole(roles, "owner") && !hasRole(roles, "admin");
}

export function getRoleCapabilities(role: AdminPanelRole | null): RoleCapabilityDefinition[] {
  if (!role) return [];
  return ROLE_CAPABILITIES.filter((entry) => entry.roles.includes(role));
}

export function getRoleCapabilitiesBySection(role: AdminPanelRole | null): RoleMatrixSection[] {
  const caps = getRoleCapabilities(role);
  return CAPABILITY_SECTIONS.map((section) => ({
    ...section,
    capabilities: caps.filter((capability) => capability.section === section.id),
  })).filter((section) => section.capabilities.length > 0);
}

export function diffRoleCapabilities(
  fromRole: AdminPanelRole | null,
  toRole: AdminPanelRole | null,
) {
  const fromKeys = new Set(getRoleCapabilities(fromRole).map((entry) => entry.key));
  const toKeys = new Set(getRoleCapabilities(toRole).map((entry) => entry.key));

  const gained = ROLE_CAPABILITIES.filter(
    (capability) => toKeys.has(capability.key) && !fromKeys.has(capability.key),
  );
  const removed = ROLE_CAPABILITIES.filter(
    (capability) => fromKeys.has(capability.key) && !toKeys.has(capability.key),
  );

  return { gained, removed };
}

export function buildLocalRolesMatrix(): RolesMatrixResponse {
  return {
    governanceRoles: GOVERNANCE_ROLES,
    sections: CAPABILITY_SECTIONS.map((section) => ({
      ...section,
      capabilities: ROLE_CAPABILITIES.filter((capability) => capability.section === section.id),
    })),
    spaceRoles: SPACE_ROLES,
  };
}

export function formatRoleLabel(role: AdminPanelRole): string {
  if (role === "owner") return "Owner";
  if (role === "admin") return "Admin";
  return "Moderator";
}
