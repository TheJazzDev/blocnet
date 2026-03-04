import { GOVERNANCE_ROLE_PRIORITY } from './constants';
import type { AdminPanelRole } from './types';

export function hasRole(roles: string[], role: string): boolean {
  return roles.includes(role);
}

export function normalizeAdminPanelRole(
  value: string | null | undefined,
): AdminPanelRole | null {
  if (!value) return null;
  const normalized = value.trim().toLowerCase();
  if (
    normalized === 'owner' ||
    normalized === 'dev' ||
    normalized === 'admin' ||
    normalized === 'moderator'
  ) {
    return normalized;
  }
  return null;
}

export function getAdminGovernanceRole(roles: string[]): AdminPanelRole | null {
  let selected: AdminPanelRole | null = null;

  for (const role of roles) {
    const normalized = normalizeAdminPanelRole(role);
    if (!normalized) continue;

    if (
      !selected ||
      GOVERNANCE_ROLE_PRIORITY[normalized] > GOVERNANCE_ROLE_PRIORITY[selected]
    ) {
      selected = normalized;
    }
  }

  return selected;
}

export function getRoleViewOptions(realRoles: string[]): AdminPanelRole[] {
  const topRole = getAdminGovernanceRole(realRoles);
  switch (topRole) {
    case 'owner':
      return ['owner', 'dev', 'admin', 'moderator'];
    case 'dev':
      return ['dev', 'admin', 'moderator'];
    case 'admin':
      return ['admin', 'moderator'];
    case 'moderator':
      return ['moderator'];
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

  const nonGovernanceRoles = uniqueRealRoles.filter(
    (role) => !normalizeAdminPanelRole(role),
  );
  return Array.from(new Set([...nonGovernanceRoles, requested]));
}

export function canAccessAdminPanel(roles: string[]): boolean {
  return roles.some(
    (role) =>
      role === 'owner' ||
      role === 'dev' ||
      role === 'admin' ||
      role === 'moderator',
  );
}

export function formatRoleLabel(role: AdminPanelRole): string {
  if (role === 'owner') return 'Owner';
  if (role === 'dev') return 'Dev';
  if (role === 'admin') return 'Admin';
  return 'Moderator';
}
