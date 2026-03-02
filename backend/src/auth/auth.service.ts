import {
  Injectable,
  InternalServerErrorException,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RoleName } from '@prisma/client';
import { randomBytes } from 'crypto';
import { createRemoteJWKSet, jwtVerify } from 'jose';
import { AppRole } from '../common/enums/role.enum';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { roleNameToAppRole } from '../common/types/role-map';
import { PrismaService } from '../prisma/prisma.service';
import { WalletProvisioningService } from '../wallet/wallet-provisioning.service';

type JwtPayload = {
  sub?: string;
  email?: string;
  user_metadata?: Record<string, unknown>;
};

const JWKS_FETCH_TIMEOUT_MS = 8000;
const JWT_VERIFY_TIMEOUT_MS = 8000;

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private readonly jwks?: ReturnType<typeof createRemoteJWKSet>;

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
    private readonly walletProvisioningService: WalletProvisioningService,
  ) {
    const jwksUrl = this.configService.get<string>('SUPABASE_JWKS_URL');
    if (jwksUrl) {
      this.jwks = createRemoteJWKSet(new URL(jwksUrl), {
        timeoutDuration: JWKS_FETCH_TIMEOUT_MS,
      });
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

    const existingProfile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: { id: true, isDeactivated: true, referralCode: true },
    });
    if (existingProfile?.isDeactivated) {
      throw new UnauthorizedException('Account is deactivated');
    }

    if (!existingProfile) {
      await this.prisma.profile.create({
        data: {
          id: userId,
          email: payload.email ?? `${userId}@unknown.local`,
          referralCode: await this.generateUniqueReferralCode(),
          // Only set username on profile creation — it must not change after signup
          ...(username ? { username } : {}),
        },
      });
    } else {
      await this.prisma.profile.update({
        where: { id: userId },
        data: {
          email: payload.email ?? `${userId}@unknown.local`,
          ...(existingProfile.referralCode
            ? {}
            : { referralCode: await this.generateUniqueReferralCode() }),
        },
      });
    }

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

    // Wallet provisioning is best-effort to avoid blocking auth flows.
    void this.walletProvisioningService
      .ensureWalletForUser(userId)
      .catch(() => undefined);

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
    if (!this.jwks) {
      throw new UnauthorizedException('JWKS not configured');
    }

    try {
      const verification = await Promise.race([
        jwtVerify(token, this.jwks),
        new Promise<never>((_, reject) =>
          setTimeout(
            () =>
              reject(new UnauthorizedException('Token verification timed out')),
            JWT_VERIFY_TIMEOUT_MS,
          ),
        ),
      ]);

      return verification.payload as JwtPayload;
    } catch (error) {
      const message =
        error instanceof Error
          ? error.message
          : 'unknown auth verification error';
      this.logger.warn(`Token verification failed: ${message}`);

      if (error instanceof UnauthorizedException) {
        throw error;
      }
      throw new UnauthorizedException('Invalid or expired token');
    }
  }

  toRolePriority(roles: AppRole[]): number {
    if (roles.includes(AppRole.OWNER)) return 4;
    if (roles.includes(AppRole.ADMIN)) return 3;
    if (roles.includes(AppRole.MODERATOR)) return 2;
    if (roles.includes(AppRole.HUNTER)) return 1;
    return 1;
  }

  private async generateUniqueReferralCode(): Promise<string> {
    for (let attempt = 0; attempt < 20; attempt += 1) {
      const code = this.createReferralCodeCandidate(8);
      const existing = await this.prisma.profile.findUnique({
        where: { referralCode: code },
        select: { id: true },
      });
      if (!existing) {
        return code;
      }
    }

    throw new InternalServerErrorException('Unable to assign referral code');
  }

  private createReferralCodeCandidate(length: number): string {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    const bytes = randomBytes(length);
    let code = '';

    for (let index = 0; index < bytes.length; index += 1) {
      code += alphabet[bytes[index] % alphabet.length];
    }

    return code;
  }
}
