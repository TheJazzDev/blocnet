import type {
  AdminPanelRole,
  GovernanceRoleDefinition,
  SpaceRoleDefinition,
} from './types';

export const GOVERNANCE_ROLE_PRIORITY: Record<AdminPanelRole, number> = {
  owner: 3,
  dev: 2,
  admin: 1,
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
      'Community identity role for official team members in the public app.',
  },
  {
    role: 'community_admin',
    label: 'Community Admin',
    description:
      'Community identity role for trusted staff; does not grant console governance access.',
  },
  {
    role: 'community_moderator',
    label: 'Community Moderator',
    description:
      'Community identity role for moderators; does not grant console governance access.',
  },
  {
    role: 'hunter',
    label: 'Hunter',
    description:
      'Space/capability role for user-hunter flows, not admin governance.',
  },
  {
    role: 'moderator',
    label: 'Legacy Moderator',
    description:
      'Legacy compatibility role mapped into community moderator behavior during migration.',
  },
];
