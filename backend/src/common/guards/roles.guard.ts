import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import {
  resolveEffectiveRoles,
  type EffectiveRoleResolution,
} from '../auth/effective-role';
import { ROLES_KEY } from '../decorators/roles.decorator';
import { AppRole } from '../enums/role.enum';
import type { AuthUser } from '../interfaces/auth-user.interface';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
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

    const hasPermission = effectiveUser.roles.some((role) =>
      requiredRoles.includes(role),
    );

    if (!hasPermission) {
      throw new ForbiddenException('Insufficient role permissions');
    }

    return true;
  }
}
