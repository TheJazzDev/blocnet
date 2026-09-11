import { SetMetadata } from '@nestjs/common';
import { AppRole } from '../enums/role.enum';

export const ROLES_KEY = 'roles';
export const Roles = (...roles: AppRole[]) => SetMetadata(ROLES_KEY, roles);

export const ROLES_DENIED_MESSAGE_KEY = 'rolesDeniedMessage';

/**
 * Overrides the generic "Insufficient role permissions" 403 message for a
 * handler (or controller) so clients can show something specific.
 */
export const RolesDeniedMessage = (message: string) =>
  SetMetadata(ROLES_DENIED_MESSAGE_KEY, message);
