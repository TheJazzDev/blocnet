import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthService } from '../../auth/auth.service';
import { ALLOW_DEACTIVATED_KEY } from '../decorators/allow-deactivated.decorator';

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private readonly authService: AuthService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<{
      headers: Record<string, string | string[] | undefined>;
      user?: unknown;
    }>();
    const authorization = request.headers.authorization;

    if (!authorization) {
      throw new UnauthorizedException('Missing Authorization header');
    }

    const token = Array.isArray(authorization)
      ? authorization[0]?.replace('Bearer ', '').trim()
      : authorization.replace('Bearer ', '').trim();

    if (!token) {
      throw new UnauthorizedException('Missing bearer token');
    }

    const allowDeactivated =
      this.reflector.getAllAndOverride<boolean>(ALLOW_DEACTIVATED_KEY, [
        context.getHandler(),
        context.getClass(),
      ]) === true;

    request.user = await this.authService.authenticateRequest(token, {
      allowDeactivated,
    });
    return true;
  }
}
