export type AdminGovernanceRole = "owner" | "dev" | "admin";

export interface GovernanceRoleDefinition {
  role: AdminGovernanceRole;
  label: string;
  description: string;
  order: number;
}

export interface RoleCapabilitySection {
  id: "overview" | "content" | "wallet" | "engagement" | "access" | "system";
  label: string;
  description: string;
}

export interface RoleCapability {
  key: string;
  label: string;
  description: string;
  section: RoleCapabilitySection["id"];
  roles: AdminGovernanceRole[];
}

export interface RoleMatrixSection extends RoleCapabilitySection {
  capabilities: RoleCapability[];
}

export interface SpaceRoleDefinition {
  role:
    | "user"
    | "core_team"
    | "community_admin"
    | "community_moderator"
    | "hunter"
    | "moderator";
  label: string;
  description: string;
}

export interface RolesMatrixResponse {
  governanceRoles: GovernanceRoleDefinition[];
  sections: RoleMatrixSection[];
  spaceRoles: SpaceRoleDefinition[];
}
