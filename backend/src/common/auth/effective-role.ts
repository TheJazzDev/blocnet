import { AppRole } from '../enums/role.enum';

export type AdminGovernanceRole =
  | AppRole.OWNER
  | AppRole.DEV
  | AppRole.ADMIN;

export interface EffectiveRoleResolution {
  effectiveRoles: AppRole[];
  realRoles: AppRole[];
  actingAsRole: AdminGovernanceRole | null;
}

const ADMIN_GOVERNANCE_ROLES: AdminGovernanceRole[] = [
  AppRole.OWNER,
  AppRole.DEV,
  AppRole.ADMIN,
];

const ROLE_PRIORITY: Record<AdminGovernanceRole, number> = {
  [AppRole.OWNER]: 3,
  [AppRole.DEV]: 2,
  [AppRole.ADMIN]: 1,
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
    case 'dev':
      return AppRole.DEV;
    case 'admin':
      return AppRole.ADMIN;
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
      return [AppRole.OWNER, AppRole.DEV, AppRole.ADMIN];
    case AppRole.DEV:
      return [AppRole.DEV, AppRole.ADMIN];
    case AppRole.ADMIN:
      return [AppRole.ADMIN];
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
