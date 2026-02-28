import { AppRole } from '../common/enums/role.enum';

export type AdminGovernanceRole =
  | AppRole.OWNER
  | AppRole.ADMIN
  | AppRole.MODERATOR;

export type RoleCapabilitySectionId =
  | 'overview'
  | 'content'
  | 'wallet'
  | 'engagement'
  | 'access'
  | 'system';

export interface GovernanceRoleDefinition {
  role: AdminGovernanceRole;
  label: string;
  description: string;
  order: number;
}

export interface RoleCapabilityDefinition {
  key: string;
  label: string;
  description: string;
  section: RoleCapabilitySectionId;
  roles: AdminGovernanceRole[];
}

export interface CapabilitySectionDefinition {
  id: RoleCapabilitySectionId;
  label: string;
  description: string;
}

export const GOVERNANCE_ROLES: GovernanceRoleDefinition[] = [
  {
    role: AppRole.OWNER,
    label: 'Owner',
    description:
      'Highest authority with full governance and configuration control.',
    order: 1,
  },
  {
    role: AppRole.ADMIN,
    label: 'Admin',
    description: 'Operational administrator with broad management privileges.',
    order: 2,
  },
  {
    role: AppRole.MODERATOR,
    label: 'Moderator',
    description:
      'Content and operations reviewer with limited mutation permissions.',
    order: 3,
  },
];

export const SPACE_ROLE_NOTES = [
  {
    role: AppRole.USER,
    label: 'User',
    description: 'Base platform identity role. Every account has user access.',
  },
  {
    role: AppRole.CORE_TEAM,
    label: 'Core Team',
    description:
      'Board/team visibility role for ecosystem members; does not grant hunter capability.',
  },
  {
    role: AppRole.HUNTER,
    label: 'Hunter',
    description:
      'Space/capability role used for user-hunter experiences, not admin governance.',
  },
] as const;

export const CAPABILITY_SECTIONS: CapabilitySectionDefinition[] = [
  {
    id: 'overview',
    label: 'Overview',
    description: 'Dashboard visibility and top-level operational context.',
  },
  {
    id: 'content',
    label: 'Content',
    description: 'Projects, updates, comments, community, and tag operations.',
  },
  {
    id: 'wallet',
    label: 'Wallet',
    description: 'Wallet health, users, KYC/withdrawals, and risk controls.',
  },
  {
    id: 'engagement',
    label: 'Engagement',
    description: 'Mining configuration, metrics, and referral administration.',
  },
  {
    id: 'access',
    label: 'Access',
    description:
      'User lifecycle management, role management, and applications.',
  },
  {
    id: 'system',
    label: 'System',
    description: 'Audit visibility, notifications, and global settings.',
  },
];

export const ROLE_CAPABILITIES: RoleCapabilityDefinition[] = [
  {
    key: 'overview.dashboard.view',
    label: 'View Dashboard',
    description: 'Access dashboard statistics, activity, and health summaries.',
    section: 'overview',
    roles: [AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR],
  },
  {
    key: 'content.projects.moderate',
    label: 'Moderate Projects',
    description: 'Review and change project status for moderation workflows.',
    section: 'content',
    roles: [AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR],
  },
  {
    key: 'content.projects.pause',
    label: 'Pause Projects',
    description:
      'Set project status to paused (reserved for owner/admin authority).',
    section: 'content',
    roles: [AppRole.OWNER, AppRole.ADMIN],
  },
  {
    key: 'content.updates.moderate',
    label: 'Moderate Updates',
    description: 'Review and update visibility status of project updates.',
    section: 'content',
    roles: [AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR],
  },
  {
    key: 'content.comments.moderate',
    label: 'Moderate Comments',
    description: 'Review and moderate update comments across the platform.',
    section: 'content',
    roles: [AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR],
  },
  {
    key: 'content.community.moderate',
    label: 'Moderate Community',
    description: 'Review and moderate community posts and community comments.',
    section: 'content',
    roles: [AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR],
  },
  {
    key: 'content.tags.manage',
    label: 'Manage Tags',
    description: 'Create and update primary/secondary taxonomy tags.',
    section: 'content',
    roles: [AppRole.OWNER, AppRole.ADMIN],
  },
  {
    key: 'wallet.health.view',
    label: 'View Wallet Health',
    description: 'See wallet provider and settlement health indicators.',
    section: 'wallet',
    roles: [AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR],
  },
  {
    key: 'wallet.users.view',
    label: 'View Wallet Users',
    description: 'Browse wallet users, balances, and account risk context.',
    section: 'wallet',
    roles: [AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR],
  },
  {
    key: 'wallet.withdrawals.review',
    label: 'Review Withdrawals',
    description: 'Approve or reject withdrawal requests.',
    section: 'wallet',
    roles: [AppRole.OWNER, AppRole.ADMIN],
  },
  {
    key: 'wallet.kyc.review',
    label: 'Review KYC',
    description: 'Approve or reject wallet KYC submissions.',
    section: 'wallet',
    roles: [AppRole.OWNER, AppRole.ADMIN],
  },
  {
    key: 'wallet.settings.mutate',
    label: 'Mutate Wallet Settings',
    description: 'Edit wallet risk limits, fee configs, and asset pricing.',
    section: 'wallet',
    roles: [AppRole.OWNER, AppRole.ADMIN],
  },
  {
    key: 'engagement.mining.view',
    label: 'View Mining Config/Metrics',
    description: 'Read mining configuration and mining metrics.',
    section: 'engagement',
    roles: [AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR],
  },
  {
    key: 'engagement.mining.mutate',
    label: 'Mutate Mining Config',
    description: 'Update mining coefficients and related operational settings.',
    section: 'engagement',
    roles: [AppRole.OWNER, AppRole.ADMIN],
  },
  {
    key: 'engagement.referrals.bind',
    label: 'Bind Referrals',
    description: 'Run admin referral bind overrides.',
    section: 'engagement',
    roles: [AppRole.OWNER, AppRole.ADMIN],
  },
  {
    key: 'access.users.view',
    label: 'View Users',
    description: 'Search users and inspect profile/account status.',
    section: 'access',
    roles: [AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR],
  },
  {
    key: 'access.users.edit_profile',
    label: 'Edit User Profiles',
    description: 'Edit profile fields for managed users.',
    section: 'access',
    roles: [AppRole.OWNER, AppRole.ADMIN],
  },
  {
    key: 'access.users.deactivate',
    label: 'Deactivate Users',
    description: 'Deactivate user accounts and revoke sessions.',
    section: 'access',
    roles: [AppRole.OWNER, AppRole.ADMIN],
  },
  {
    key: 'access.users.reactivate',
    label: 'Reactivate Users',
    description: 'Reactivate deactivated user accounts.',
    section: 'access',
    roles: [AppRole.OWNER],
  },
  {
    key: 'access.users.hard_delete',
    label: 'Hard Delete Users',
    description: 'Permanently remove user accounts and linked records.',
    section: 'access',
    roles: [AppRole.OWNER],
  },
  {
    key: 'access.roles.admin.manage',
    label: 'Manage Admin Role',
    description: 'Grant or revoke admin role assignments.',
    section: 'access',
    roles: [AppRole.OWNER],
  },
  {
    key: 'access.roles.owner.manage',
    label: 'Manage Owner Role',
    description: 'Grant or revoke owner role assignments.',
    section: 'access',
    roles: [AppRole.OWNER],
  },
  {
    key: 'access.roles.moderator.manage',
    label: 'Manage Moderator Role',
    description: 'Grant or revoke moderator role assignments.',
    section: 'access',
    roles: [AppRole.OWNER, AppRole.ADMIN],
  },
  {
    key: 'access.roles.core_team.manage',
    label: 'Manage Core Team Role',
    description: 'Grant or revoke core team role assignments.',
    section: 'access',
    roles: [AppRole.OWNER],
  },
  {
    key: 'access.roles.hunter.manage',
    label: 'Manage Hunter Role',
    description: 'Grant or revoke hunter role assignments.',
    section: 'access',
    roles: [AppRole.OWNER, AppRole.ADMIN],
  },
  {
    key: 'access.applications.admin.review',
    label: 'Review Admin Applications',
    description: 'Approve or reject admin role applications.',
    section: 'access',
    roles: [AppRole.OWNER],
  },
  {
    key: 'access.applications.proposal.review',
    label: 'Review Project Proposals',
    description: 'Approve or reject project proposals.',
    section: 'access',
    roles: [AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR],
  },
  {
    key: 'system.audit_log.view',
    label: 'View Audit Log',
    description: 'Read audit events across admin operations.',
    section: 'system',
    roles: [AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR],
  },
  {
    key: 'system.notifications.send',
    label: 'Send Notifications',
    description: 'Broadcast push and in-app notifications.',
    section: 'system',
    roles: [AppRole.OWNER, AppRole.ADMIN],
  },
  {
    key: 'system.social_credentials.manage',
    label: 'Manage Social Credentials',
    description:
      'Manage encrypted social media account credentials (owner only).',
    section: 'system',
    roles: [AppRole.OWNER],
  },
  {
    key: 'system.settings.mutate',
    label: 'Mutate Settings',
    description: 'Update global admin panel configuration settings.',
    section: 'system',
    roles: [AppRole.OWNER],
  },
];
