import { AppRole } from '../enums/role.enum';

export interface AuthUser {
  id: string;
  email: string | null;
  roles: AppRole[];
}
