export type AdminPanelRole = 'owner' | 'dev' | 'admin';
export type SpaceRole =
  | 'user'
  | 'core_team'
  | 'community_admin'
  | 'community_moderator'
  | 'hunter'
  | 'moderator';
export type RoleCapabilitySectionId =
  | 'overview'
  | 'content'
  | 'wallet'
  | 'engagement'
  | 'access'
  | 'system';

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
