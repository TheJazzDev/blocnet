import { CAPABILITY_SECTIONS, GOVERNANCE_ROLES, ROLE_CAPABILITIES, SPACE_ROLES } from './constants';
import { canAccessAdminPanel, hasRole } from './governance';
import type { AdminPanelRole, RoleCapabilityDefinition, RoleMatrixSection, RolesMatrixResponse } from './types';

export function canManageAdmins(roles: string[]): boolean {
  return hasRole(roles, 'owner') || hasRole(roles, 'dev');
}

export function canManageDevs(roles: string[]): boolean {
  return hasRole(roles, 'owner');
}

export function canManageModerators(roles: string[]): boolean {
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

export function canViewOpsEvents(roles: string[]): boolean {
  return hasRole(roles, 'owner') || hasRole(roles, 'dev');
}

export function canManageSocialCredentials(roles: string[]): boolean {
  return hasRole(roles, 'owner');
}

export function isModeratorOnly(roles: string[]): boolean {
  return (
    hasRole(roles, 'moderator') &&
    !hasRole(roles, 'owner') &&
    !hasRole(roles, 'dev') &&
    !hasRole(roles, 'admin')
  );
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
