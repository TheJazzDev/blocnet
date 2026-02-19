import { RoleName } from '@prisma/client';
import { AppRole } from '../enums/role.enum';

export function roleNameToAppRole(role: RoleName): AppRole {
  switch (role) {
    case RoleName.owner:
      return AppRole.OWNER;
    case RoleName.admin:
      return AppRole.ADMIN;
    case RoleName.moderator:
      return AppRole.MODERATOR;
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
    case AppRole.ADMIN:
      return RoleName.admin;
    case AppRole.MODERATOR:
      return RoleName.moderator;
    case AppRole.HUNTER:
      return RoleName.hunter;
    case AppRole.USER:
      return RoleName.user;
    default:
      return RoleName.user;
  }
}
