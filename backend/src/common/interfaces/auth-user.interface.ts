import { AppRole } from '../enums/role.enum';

export interface AuthUser {
  id: string;
  email: string | null;
  roles: AppRole[];
  realRoles?: AppRole[];
  actingAsRole?:
    | AppRole.OWNER
    | AppRole.DEV
    | AppRole.ADMIN
    | AppRole.MODERATOR
    | null;
}
