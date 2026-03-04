import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AdminTwoFactorService } from '../../admin-security/admin-two-factor.service';
import {
  resolveEffectiveRoles,
  type EffectiveRoleResolution,
} from '../auth/effective-role';
import { ROLES_KEY } from '../decorators/roles.decorator';
import { AppRole } from '../enums/role.enum';
import type { AuthUser } from '../interfaces/auth-user.interface';

const GOVERNANCE_ROLE_IMPLICATIONS: Record<AppRole, AppRole[]> = {
  [AppRole.OWNER]: [AppRole.OWNER, AppRole.DEV, AppRole.ADMIN, AppRole.MODERATOR],
  [AppRole.DEV]: [AppRole.DEV, AppRole.ADMIN, AppRole.MODERATOR],
  [AppRole.ADMIN]: [AppRole.ADMIN, AppRole.MODERATOR],
  [AppRole.MODERATOR]: [AppRole.MODERATOR],
  [AppRole.CORE_TEAM]: [AppRole.CORE_TEAM],
  [AppRole.HUNTER]: [AppRole.HUNTER],
  [AppRole.USER]: [AppRole.USER],
};

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly adminTwoFactorService: AdminTwoFactorService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<{
      user?: AuthUser;
      headers: Record<string, string | string[] | undefined>;
    }>();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('User context is missing');
    }

    const viewAsHeader = request.headers['x-admin-view-as-role'];
    const requestedRole = Array.isArray(viewAsHeader)
      ? viewAsHeader[0]
      : viewAsHeader;

    const resolved: EffectiveRoleResolution = resolveEffectiveRoles(
      user.roles,
      requestedRole,
    );

    request.user = {
      ...user,
      roles: resolved.effectiveRoles,
      realRoles: resolved.realRoles,
      actingAsRole: resolved.actingAsRole,
    };

    const requiredRoles = this.reflector.getAllAndOverride<AppRole[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    const effectiveUser = request.user;
    if (!effectiveUser) {
      throw new ForbiddenException('User context is missing');
    }

    const hasPermission = requiredRoles.some((requiredRole) =>
      effectiveUser.roles.some((role) =>
        this.isRoleAllowedForRequirement(role, requiredRole),
      ),
    );

    if (!hasPermission) {
      throw new ForbiddenException('Insufficient role permissions');
    }

    const adminPanelHeader = request.headers['x-admin-panel-request'];
    const isAdminPanelRequest = Array.isArray(adminPanelHeader)
      ? adminPanelHeader[0] === '1'
      : adminPanelHeader === '1';

    const includesGovernanceRole = requiredRoles.some(
      (role) =>
        role === AppRole.OWNER ||
        role === AppRole.DEV ||
        role === AppRole.ADMIN ||
        role === AppRole.MODERATOR,
    );

    if (isAdminPanelRequest && includesGovernanceRole) {
      const shouldEnforce =
        this.adminTwoFactorService.shouldEnforceChallengeForAdminPanel(
          effectiveUser.id,
          effectiveUser.realRoles ?? effectiveUser.roles,
        );

      if (shouldEnforce) {
        const sessionHeader = request.headers['x-admin-2fa-session'];
        const sessionToken = Array.isArray(sessionHeader)
          ? (sessionHeader[0] ?? '').trim()
          : (sessionHeader ?? '').trim();

        if (!sessionToken) {
          throw new ForbiddenException(
            'Two-factor authentication is required for admin console access',
          );
        }

        const validation = await this.adminTwoFactorService.validateSession({
          userId: effectiveUser.id,
          roles: effectiveUser.realRoles ?? effectiveUser.roles,
          sessionToken,
        });

        if (!validation.valid) {
          throw new ForbiddenException(
            'Two-factor authentication is required for admin console access',
          );
        }
      }
    }

    return true;
  }

  private isRoleAllowedForRequirement(
    userRole: AppRole,
    requiredRole: AppRole,
  ): boolean {
    const impliedRoles =
      GOVERNANCE_ROLE_IMPLICATIONS[userRole] ?? [userRole];
    return impliedRoles.includes(requiredRole);
  }
}
