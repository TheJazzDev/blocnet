import { SetMetadata } from '@nestjs/common';

export const ALLOW_DEACTIVATED_KEY = 'allowDeactivated';

/**
 * Lets a deactivated account through AuthGuard for this handler only.
 * AuthService rejects deactivated profiles by default, which would make
 * self-service reactivation unreachable.
 */
export const AllowDeactivated = () => SetMetadata(ALLOW_DEACTIVATED_KEY, true);
