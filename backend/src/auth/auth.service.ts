import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RoleName } from '@prisma/client';
import { createRemoteJWKSet, jwtVerify } from 'jose';
import { AppRole } from '../common/enums/role.enum';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { roleNameToAppRole } from '../common/types/role-map';
import { PrismaService } from '../prisma/prisma.service';

type JwtPayload = {
  sub?: string;
  email?: string;
  user_metadata?: Record<string, unknown>;
};

@Injectable()
export class AuthService {
  private readonly jwks?: ReturnType<typeof createRemoteJWKSet>;

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    const jwksUrl = this.configService.get<string>('SUPABASE_JWKS_URL');
    if (jwksUrl) {
      this.jwks = createRemoteJWKSet(new URL(jwksUrl));
    }
  }

  async authenticateRequest(token: string): Promise<AuthUser> {
    const payload = await this.verifyToken(token);
    const userId = payload.sub;

    if (!userId) {
      throw new UnauthorizedException('Invalid token payload');
    }

    // Extract username from Supabase user_metadata (set at signup)
    const rawUsername = payload.user_metadata?.['username'];
    const username =
      typeof rawUsername === 'string' && rawUsername.trim().length > 0
        ? rawUsername.trim().toLowerCase()
        : undefined;

    await this.prisma.profile.upsert({
      where: { id: userId },
      update: { email: payload.email ?? `${userId}@unknown.local` },
      create: {
        id: userId,
        email: payload.email ?? `${userId}@unknown.local`,
        // Only set username on profile creation — it must not change after signup
        ...(username ? { username } : {}),
      },
    });

    let roleRows = await this.prisma.userRole.findMany({
      where: { userId },
      select: { role: true },
    });

    if (roleRows.length === 0) {
      await this.prisma.userRole.create({
        data: {
          userId,
          role: RoleName.user,
        },
      });
      roleRows = [{ role: RoleName.user }];
    }

    return {
      id: userId,
      email: payload.email ?? null,
      roles: roleRows.map((row) => roleNameToAppRole(row.role)),
    };
  }

  async verifySession(token: string): Promise<AuthUser> {
    return this.authenticateRequest(token);
  }

  private async verifyToken(token: string): Promise<JwtPayload> {
    const jwtSecret = this.configService.get<string>('SUPABASE_JWT_SECRET');

    try {
      if (jwtSecret) {
        const secret = new TextEncoder().encode(jwtSecret);
        const { payload } = await jwtVerify(token, secret);
        return payload as JwtPayload;
      }

      if (this.jwks) {
        const { payload } = await jwtVerify(token, this.jwks);
        return payload as JwtPayload;
      }

      throw new UnauthorizedException(
        'SUPABASE_JWT_SECRET or SUPABASE_JWKS_URL must be configured',
      );
    } catch {
      throw new UnauthorizedException('Failed to verify auth token');
    }
  }

  toRolePriority(roles: AppRole[]): number {
    if (roles.includes(AppRole.OWNER)) return 4;
    if (roles.includes(AppRole.ADMIN)) return 3;
    if (roles.includes(AppRole.MODERATOR)) return 2;
    if (roles.includes(AppRole.HUNTER)) return 1;
    return 1;
  }
}
