import { RoleName } from '@prisma/client';
import { AppRole } from '../enums/role.enum';

export function roleNameToAppRole(role: RoleName): AppRole {
  switch (role) {
    case RoleName.owner:
      return AppRole.OWNER;
    case RoleName.dev:
      return AppRole.DEV;
    case RoleName.admin:
      return AppRole.ADMIN;
    case RoleName.community_admin:
      return AppRole.COMMUNITY_ADMIN;
    case RoleName.community_moderator:
      return AppRole.COMMUNITY_MODERATOR;
    case RoleName.moderator:
      // Legacy moderator records are treated as community moderators.
      return AppRole.COMMUNITY_MODERATOR;
    case RoleName.core_team:
      return AppRole.CORE_TEAM;
    case RoleName.hunter:
      return AppRole.HUNTER;
    case RoleName.user:
      return AppRole.USER;
    default:
      return AppRole.USER;
  }
}

export function appRoleToRoleName(role: AppRole): RoleName {
  switch (role) {
    case AppRole.OWNER:
      return RoleName.owner;
    case AppRole.DEV:
      return RoleName.dev;
    case AppRole.ADMIN:
      return RoleName.admin;
    case AppRole.COMMUNITY_ADMIN:
      return RoleName.community_admin;
    case AppRole.COMMUNITY_MODERATOR:
      return RoleName.community_moderator;
    case AppRole.CORE_TEAM:
      return RoleName.core_team;
    case AppRole.HUNTER:
      return RoleName.hunter;
    case AppRole.USER:
      return RoleName.user;
    default:
      return RoleName.user;
  }
}
