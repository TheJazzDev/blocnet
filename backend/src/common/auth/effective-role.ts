import { AppRole } from '../enums/role.enum';

export type AdminGovernanceRole =
  | AppRole.OWNER
  | AppRole.ADMIN
  | AppRole.MODERATOR;

export interface EffectiveRoleResolution {
  effectiveRoles: AppRole[];
  realRoles: AppRole[];
  actingAsRole: AdminGovernanceRole | null;
}

const ADMIN_GOVERNANCE_ROLES: AdminGovernanceRole[] = [
  AppRole.OWNER,
  AppRole.ADMIN,
  AppRole.MODERATOR,
];

const ROLE_PRIORITY: Record<AdminGovernanceRole, number> = {
  [AppRole.OWNER]: 3,
  [AppRole.ADMIN]: 2,
  [AppRole.MODERATOR]: 1,
};

function normalizeGovernanceRole(
  value: string | null | undefined,
): AdminGovernanceRole | null {
  if (!value) {
    return null;
  }

  const normalized = value.trim().toLowerCase();
  switch (normalized) {
    case 'owner':
      return AppRole.OWNER;
    case 'admin':
      return AppRole.ADMIN;
    case 'moderator':
      return AppRole.MODERATOR;
    default:
      return null;
  }
}

export function getAdminGovernanceRole(
  roles: AppRole[],
): AdminGovernanceRole | null {
  let best: AdminGovernanceRole | null = null;

  for (const role of roles) {
    if (!ADMIN_GOVERNANCE_ROLES.includes(role as AdminGovernanceRole)) {
      continue;
    }

    const governanceRole = role as AdminGovernanceRole;
    if (!best || ROLE_PRIORITY[governanceRole] > ROLE_PRIORITY[best]) {
      best = governanceRole;
    }
  }

  return best;
}

function getAllowedViewAsTargets(
  governanceRole: AdminGovernanceRole | null,
): AdminGovernanceRole[] {
  switch (governanceRole) {
    case AppRole.OWNER:
      return [AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR];
    case AppRole.ADMIN:
      return [AppRole.ADMIN, AppRole.MODERATOR];
    case AppRole.MODERATOR:
      return [AppRole.MODERATOR];
    default:
      return [];
  }
}

export function resolveEffectiveRoles(
  realRoles: AppRole[],
  requestedRole: string | null | undefined,
): EffectiveRoleResolution {
  const uniqueRealRoles = Array.from(new Set(realRoles));
  const topGovernanceRole = getAdminGovernanceRole(uniqueRealRoles);
  const requestedGovernanceRole = normalizeGovernanceRole(requestedRole);
  const allowedTargets = getAllowedViewAsTargets(topGovernanceRole);

  if (
    !requestedGovernanceRole ||
    !allowedTargets.includes(requestedGovernanceRole) ||
    requestedGovernanceRole === topGovernanceRole
  ) {
    return {
      effectiveRoles: uniqueRealRoles,
      realRoles: uniqueRealRoles,
      actingAsRole: null,
    };
  }

  const nonGovernanceRoles = uniqueRealRoles.filter(
    (role) => !ADMIN_GOVERNANCE_ROLES.includes(role as AdminGovernanceRole),
  );

  return {
    effectiveRoles: Array.from(
      new Set([...nonGovernanceRoles, requestedGovernanceRole]),
    ),
    realRoles: uniqueRealRoles,
    actingAsRole: requestedGovernanceRole,
  };
}
