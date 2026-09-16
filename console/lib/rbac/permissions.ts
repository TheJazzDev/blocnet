import { CAPABILITY_SECTIONS, GOVERNANCE_ROLES, ROLE_CAPABILITIES, SPACE_ROLES } from './constants';
import { canAccessAdminPanel, hasRole } from './governance';
import type { AdminPanelRole, RoleCapabilityDefinition, RoleMatrixSection, RolesMatrixResponse } from './types';

export function canManageAdmins(roles: string[]): boolean {
  return hasRole(roles, 'owner') || hasRole(roles, 'dev');
}

export function canManageDevs(roles: string[]): boolean {
  return hasRole(roles, 'owner');
}

export function canManageCommunityAdmins(roles: string[]): boolean {
  return hasRole(roles, 'owner') || hasRole(roles, 'dev') || hasRole(roles, 'admin');
}

export function canManageCommunityModerators(roles: string[]): boolean {
  return hasRole(roles, 'owner') || hasRole(roles, 'dev') || hasRole(roles, 'admin');
}

export function canManageHunters(roles: string[]): boolean {
  return hasRole(roles, 'owner') || hasRole(roles, 'dev') || hasRole(roles, 'admin');
}

export function canReviewAdminApplications(roles: string[]): boolean {
  return hasRole(roles, 'owner');
}

export function canReviewProjectProposals(roles: string[]): boolean {
  return canAccessAdminPanel(roles);
}

export function canManageTags(roles: string[]): boolean {
  return hasRole(roles, 'owner') || hasRole(roles, 'dev') || hasRole(roles, 'admin');
}

export function canMutateSettings(roles: string[]): boolean {
  return hasRole(roles, 'owner') || hasRole(roles, 'dev') || hasRole(roles, 'admin');
}

export function canSendNotifications(roles: string[]): boolean {
  return hasRole(roles, 'owner') || hasRole(roles, 'dev') || hasRole(roles, 'admin');
}

export function canMutateWallet(roles: string[]): boolean {
  return hasRole(roles, 'owner') || hasRole(roles, 'dev') || hasRole(roles, 'admin');
}

/** Quests, quest reviews, badges and levels: every governance role, dev included. */
export function canManageGamification(roles: string[]): boolean {
  return hasRole(roles, 'owner') || hasRole(roles, 'dev') || hasRole(roles, 'admin');
}

export function canViewOpsEvents(roles: string[]): boolean {
  return hasRole(roles, 'owner') || hasRole(roles, 'dev');
}

export function canManageSocialCredentials(roles: string[]): boolean {
  return hasRole(roles, 'owner');
}

/** True when any of the roles is granted the capability in the catalog. */
export function hasCapability(roles: string[], capabilityKey: string): boolean {
  const capability = ROLE_CAPABILITIES.find((entry) => entry.key === capabilityKey);
  if (!capability) return false;
  return capability.roles.some((role) => hasRole(roles, role));
}

/** F-66: manual BNP credits/debits on a member. Owner and admin only. */
export function canAdjustMemberBnp(roles: string[]): boolean {
  return hasRole(roles, 'owner') || hasRole(roles, 'admin');
}

/** Mining config and metrics (`engagement.mining.view`). */
export function canViewMining(roles: string[]): boolean {
  return hasCapability(roles, 'engagement.mining.view');
}

/** Editing mining config (`engagement.mining.mutate`). */
export function canMutateMining(roles: string[]): boolean {
  return hasCapability(roles, 'engagement.mining.mutate');
}

/**
 * Mining config change history. It is read from `GET /audit-log`, which the
 * backend only serves to owner and admin, so dev-only sessions cannot see it.
 */
export function canViewMiningHistory(roles: string[]): boolean {
  return hasRole(roles, 'owner') || hasRole(roles, 'admin');
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

export function diffRoleCapabilities(fromRole: AdminPanelRole | null, toRole: AdminPanelRole | null) {
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
      capabilities: ROLE_CAPABILITIES.filter(
        (capability) => capability.section === section.id,
      ),
    })),
    spaceRoles: SPACE_ROLES,
  };
}
