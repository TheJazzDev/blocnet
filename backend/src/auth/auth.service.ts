import {
  Injectable,
  InternalServerErrorException,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NotificationType, RoleName } from '@prisma/client';
import { randomBytes } from 'crypto';
import { createRemoteJWKSet, jwtVerify } from 'jose';
import { AppRole } from '../common/enums/role.enum';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { roleNameToAppRole } from '../common/types/role-map';
import { NotificationsService } from '../notifications/notifications.service';
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
    private readonly notificationsService: NotificationsService,
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
    const metadataUsername =
      typeof rawUsername === 'string' && rawUsername.trim().length > 0
        ? rawUsername.trim().toLowerCase()
        : undefined;
    const usernameSeed =
      this.normalizeUsernameCandidate(metadataUsername) ??
      this.normalizeUsernameCandidate(payload.email?.split('@')[0]) ??
      this.normalizeUsernameCandidate(userId);
    const signupReferralCode = this.extractReferralCodeFromMetadata(
      payload.user_metadata,
    );

    const existingProfile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: {
        id: true,
        isDeactivated: true,
        referralCode: true,
        username: true,
      },
    });
    if (existingProfile?.isDeactivated) {
      throw new UnauthorizedException('Account is deactivated');
    }

    let createdProfile = false;
    if (!existingProfile) {
      const ensuredUsername = await this.generateUniqueUsername(usernameSeed);
      const referrer = signupReferralCode
        ? await this.prisma.profile.findUnique({
            where: { referralCode: signupReferralCode },
            select: { id: true },
          })
        : null;

      await this.prisma.profile.create({
        data: {
          id: userId,
          email: payload.email ?? `${userId}@unknown.local`,
          referralCode: await this.generateUniqueReferralCode(),
          username: ensuredUsername,
          ...(referrer && referrer.id !== userId
            ? {
                referredById: referrer.id,
                referredAt: new Date(),
              }
            : {}),
        },
      });
      createdProfile = true;
    } else {
      const ensuredUsername = existingProfile.username
        ? null
        : await this.generateUniqueUsername(usernameSeed, userId);
      await this.prisma.profile.update({
        where: { id: userId },
        data: {
          email: payload.email ?? `${userId}@unknown.local`,
          ...(ensuredUsername ? { username: ensuredUsername } : {}),
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

    if (createdProfile) {
      try {
        await this.notificationsService.notifyMany(
          [
            {
              userId,
              type: NotificationType.system,
              actorUserId: null,
              title: 'Account created',
              body: 'Your account has been created successfully.',
              deeplink: '/profile',
              dedupeKey: `auth.signup:${userId}`,
            },
          ],
          { push: true },
        );
      } catch (error) {
        this.logger.warn(
          `Account-created notification failed for user ${userId}: ${
            error instanceof Error ? error.message : String(error)
          }`,
        );
      }
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
    if (roles.includes(AppRole.OWNER)) return 5;
    if (roles.includes(AppRole.DEV)) return 4;
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

  private normalizeUsernameCandidate(value?: string | null): string | null {
    if (!value) return null;

    const cleaned = value
      .trim()
      .toLowerCase()
      .replace(/^@+/, '')
      .replace(/[^a-z0-9_]+/g, '_')
      .replace(/_+/g, '_')
      .replace(/^_+|_+$/g, '');

    if (!cleaned) return null;

    const bounded =
      cleaned.length > 24 ? cleaned.slice(0, 24) : cleaned.padEnd(3, '0');
    return bounded;
  }

  private async generateUniqueUsername(
    seed: string | null,
    excludeUserId?: string,
  ): Promise<string> {
    const baseSeed = seed ?? `user_${randomBytes(4).toString('hex')}`;
    const normalizedBase =
      this.normalizeUsernameCandidate(baseSeed) ?? 'user000';
    const roomForSuffix = 24 - 4;
    const truncatedBase = normalizedBase.slice(0, Math.max(roomForSuffix, 3));

    for (let attempt = 0; attempt < 100; attempt += 1) {
      const suffix = attempt === 0 ? '' : `_${attempt + 1}`;
      const candidate = `${truncatedBase}${suffix}`.slice(0, 24);
      const existing = await this.prisma.profile.findUnique({
        where: { username: candidate },
        select: { id: true },
      });
      if (!existing || (excludeUserId && existing.id === excludeUserId)) {
        return candidate;
      }
    }

    throw new InternalServerErrorException('Unable to assign username');
  }

  private extractReferralCodeFromMetadata(
    metadata?: Record<string, unknown>,
  ): string | null {
    if (!metadata) return null;

    const candidate =
      metadata['referralCode'] ??
      metadata['referral_code'] ??
      metadata['referrerCode'] ??
      metadata['referrer_code'];

    if (typeof candidate !== 'string') return null;

    const normalized = candidate.trim().toUpperCase();
    if (!normalized) return null;
    return normalized;
  }
}
