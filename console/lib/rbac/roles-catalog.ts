import type {
  AdminPanelRole,
  GovernanceRoleDefinition,
  SpaceRoleDefinition,
} from './types';

export const GOVERNANCE_ROLE_PRIORITY: Record<AdminPanelRole, number> = {
  owner: 4,
  dev: 3,
  admin: 2,
  moderator: 1,
};

export const GOVERNANCE_ROLES: GovernanceRoleDefinition[] = [
  {
    role: 'owner',
    label: 'Owner',
    description:
      'Highest authority with full governance and configuration control.',
    order: 1,
  },
  {
    role: 'dev',
    label: 'Dev',
    description:
      'Engineering governance role with elevated operational and debugging access.',
    order: 2,
  },
  {
    role: 'admin',
    label: 'Admin',
    description: 'Operational administrator with broad management privileges.',
    order: 3,
  },
  {
    role: 'moderator',
    label: 'Moderator',
    description:
      'Content and operations reviewer with limited mutation permissions.',
    order: 4,
  },
];

export const SPACE_ROLES: SpaceRoleDefinition[] = [
  {
    role: 'user',
    label: 'User',
    description: 'Base platform identity role. Every account has user access.',
  },
  {
    role: 'core_team',
    label: 'Core Team',
    description:
      'Board/team visibility role for ecosystem members; does not grant hunter capability.',
  },
  {
    role: 'hunter',
    label: 'Hunter',
    description:
      'Space/capability role for user-hunter flows, not admin governance.',
  },
];
