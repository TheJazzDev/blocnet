import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RoleName, type AdminTotpCredential } from '@prisma/client';
import {
  createCipheriv,
  createDecipheriv,
  createHash,
  randomBytes,
} from 'crypto';
import { AppRole } from '../common/enums/role.enum';
import { PrismaService } from '../prisma/prisma.service';
import {
  buildOtpAuthUrl,
  generateTotpSecret,
  verifyTotpCode,
} from './totp.util';

const DEFAULT_POLICY_ID = 'default';
const ENROLLMENT_TTL_MS = 10 * 60 * 1000;
const RECOVERY_CODE_COUNT = 10;
const RECOVERY_CODE_SEGMENT_LENGTH = 4;
const RECOVERY_CODE_SEGMENTS = 3;
const SESSION_EXTENSION_LEEWAY_MS = 30 * 60 * 1000;

export type AdminTwoFactorPreflight = {
  eligible: boolean;
  totpEnabled: boolean;
  recoveryCodesRemaining: number;
  policyRequired: boolean;
  challengeRequired: boolean;
};

export type AdminTwoFactorPolicyState = {
  id: string;
  require2faForAdminPanel: boolean;
  updatedById: string | null;
  updatedAt: Date;
};

export type AdminTwoFactorSessionResult = {
  sessionToken: string;
  expiresAt: Date;
};

@Injectable()
export class AdminTwoFactorService {
  private readonly logger = new Logger(AdminTwoFactorService.name);
  private readonly encryptionKey: Buffer;
  private readonly sessionTtlHours: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {
    this.encryptionKey = this.resolveEncryptionKey();
    this.sessionTtlHours = this.resolveSessionTtlHours();
  }

  async getPreflight(
    userId: string,
    roles: AppRole[],
  ): Promise<AdminTwoFactorPreflight> {
    this.assertVaultAvailable();

    if (!this.isAdminPanelEligible(roles)) {
      return {
        eligible: false,
        totpEnabled: false,
        recoveryCodesRemaining: 0,
        policyRequired: false,
        challengeRequired: false,
      };
    }

    const [policy, credential, remaining] = await Promise.all([
      this.getPolicy(),
      this.prisma.adminTotpCredential.findUnique({
        where: { userId },
        select: { userId: true },
      }),
      this.prisma.adminTotpRecoveryCode.count({
        where: {
          userId,
          consumedAt: null,
        },
      }),
    ]);

    const totpEnabled = Boolean(credential);
    const policyRequired = policy.require2faForAdminPanel;

    return {
      eligible: true,
      totpEnabled,
      recoveryCodesRemaining: remaining,
      policyRequired,
      challengeRequired: totpEnabled,
    };
  }

  shouldEnforceChallengeForAdminPanel(
    userId: string,
    roles: AppRole[],
  ): boolean {
    this.assertVaultAvailable();

    if (!this.isAdminPanelEligible(roles)) {
      return false;
    }

    return true;
  }

  async startEnrollment(input: {
    userId: string;
    email: string | null;
    roles: AppRole[];
  }): Promise<{
    secret: string;
    otpAuthUrl: string;
    issuer: string;
    accountName: string;
    expiresAt: Date;
  }> {
    this.assertVaultAvailable();
    this.assertEligible(input.roles);

    const existingCredential = await this.prisma.adminTotpCredential.findUnique(
      {
        where: { userId: input.userId },
        select: { userId: true },
      },
    );

    if (existingCredential) {
      throw new BadRequestException('TOTP is already enabled for this account');
    }

    const secret = generateTotpSecret();
    const encrypted = this.encrypt(secret);
    const expiresAt = new Date(Date.now() + ENROLLMENT_TTL_MS);

    await this.prisma.adminTotpEnrollmentChallenge.upsert({
      where: { userId: input.userId },
      update: {
        secretCipher: encrypted.cipher,
        secretIv: encrypted.iv,
        secretAuthTag: encrypted.authTag,
        expiresAt,
      },
      create: {
        userId: input.userId,
        secretCipher: encrypted.cipher,
        secretIv: encrypted.iv,
        secretAuthTag: encrypted.authTag,
        expiresAt,
      },
    });

    const issuer = this.resolveTotpIssuer();
    const accountName = this.resolveTotpAccountName(input.email, input.userId);

    return {
      secret,
      issuer,
      accountName,
      otpAuthUrl: buildOtpAuthUrl({
        issuer,
        accountName,
        secret,
      }),
      expiresAt,
    };
  }

  async confirmEnrollment(input: {
    userId: string;
    roles: AppRole[];
    code: string;
  }): Promise<{
    enabled: true;
    recoveryCodes: string[];
    sessionToken: string;
    sessionExpiresAt: Date;
  }> {
    this.assertVaultAvailable();
    this.assertEligible(input.roles);

    const challenge = await this.prisma.adminTotpEnrollmentChallenge.findUnique(
      {
        where: { userId: input.userId },
      },
    );

    if (!challenge) {
      throw new BadRequestException('No active TOTP enrollment challenge');
    }

    if (challenge.expiresAt.getTime() <= Date.now()) {
      await this.prisma.adminTotpEnrollmentChallenge.delete({
        where: { userId: input.userId },
      });
      throw new BadRequestException('TOTP enrollment challenge has expired');
    }

    const secret = this.decrypt({
      secretCipher: challenge.secretCipher,
      secretIv: challenge.secretIv,
      secretAuthTag: challenge.secretAuthTag,
    });

    const normalizedCode = this.normalizeCode(input.code);
    if (!verifyTotpCode({ secret, token: normalizedCode })) {
      throw new BadRequestException('Invalid verification code');
    }

    const encryptedSecret = this.encrypt(secret);
    const recoveryCodes = this.generateRecoveryCodes();

    const session = await this.prisma.$transaction(async (tx) => {
      await tx.adminTotpCredential.upsert({
        where: { userId: input.userId },
        update: {
          secretCipher: encryptedSecret.cipher,
          secretIv: encryptedSecret.iv,
          secretAuthTag: encryptedSecret.authTag,
          enabledAt: new Date(),
          lastUsedAt: new Date(),
        },
        create: {
          userId: input.userId,
          secretCipher: encryptedSecret.cipher,
          secretIv: encryptedSecret.iv,
          secretAuthTag: encryptedSecret.authTag,
          enabledAt: new Date(),
          lastUsedAt: new Date(),
        },
      });

      await tx.adminTotpEnrollmentChallenge.delete({
        where: { userId: input.userId },
      });

      await tx.adminTotpRecoveryCode.deleteMany({
        where: { userId: input.userId },
      });

      await tx.adminTotpRecoveryCode.createMany({
        data: recoveryCodes.map((code) => ({
          userId: input.userId,
          codeHash: this.hashRecoveryCode(code),
        })),
      });

      await tx.adminTwoFactorSession.deleteMany({
        where: {
          userId: input.userId,
          revokedAt: null,
        },
      });

      const sessionToken = this.generateSessionToken();
      const tokenHash = this.hashSessionToken(sessionToken);
      const expiresAt = this.computeSessionExpiry();

      await tx.adminTwoFactorSession.create({
        data: {
          userId: input.userId,
          tokenHash,
          expiresAt,
        },
      });

      return {
        sessionToken,
        expiresAt,
      };
    });

    return {
      enabled: true,
      recoveryCodes,
      sessionToken: session.sessionToken,
      sessionExpiresAt: session.expiresAt,
    };
  }

  async verifyLoginChallenge(input: {
    userId: string;
    roles: AppRole[];
    code?: string;
    recoveryCode?: string;
  }): Promise<AdminTwoFactorSessionResult> {
    this.assertVaultAvailable();
    this.assertEligible(input.roles);

    const preflight = await this.getPreflight(input.userId, input.roles);
    if (!preflight.challengeRequired) {
      throw new BadRequestException(
        'Two-factor challenge is not required for this account',
      );
    }

    await this.assertValidFactor({
      userId: input.userId,
      code: input.code,
      recoveryCode: input.recoveryCode,
      consumeRecovery: true,
    });

    return this.createSession(input.userId);
  }

  async regenerateRecoveryCodes(input: {
    userId: string;
    roles: AppRole[];
    code?: string;
    recoveryCode?: string;
  }): Promise<{ recoveryCodes: string[] }> {
    this.assertVaultAvailable();
    this.assertEligible(input.roles);

    const credential = await this.getCredentialOrThrow(input.userId);

    await this.assertValidFactor({
      userId: input.userId,
      code: input.code,
      recoveryCode: input.recoveryCode,
      consumeRecovery: true,
      credential,
    });

    const recoveryCodes = this.generateRecoveryCodes();

    await this.prisma.$transaction(async (tx) => {
      await tx.adminTotpRecoveryCode.deleteMany({
        where: { userId: input.userId },
      });

      await tx.adminTotpRecoveryCode.createMany({
        data: recoveryCodes.map((code) => ({
          userId: input.userId,
          codeHash: this.hashRecoveryCode(code),
        })),
      });
    });

    return { recoveryCodes };
  }

  async disableTotp(input: {
    userId: string;
    roles: AppRole[];
    code?: string;
    recoveryCode?: string;
  }): Promise<{ disabled: true }> {
    this.assertVaultAvailable();
    this.assertEligible(input.roles);

    const policy = await this.getPolicy();
    if (policy.require2faForAdminPanel) {
      throw new ForbiddenException(
        'Cannot disable TOTP while admin console 2FA policy is enforced',
      );
    }

    const credential = await this.getCredentialOrThrow(input.userId);

    await this.assertValidFactor({
      userId: input.userId,
      code: input.code,
      recoveryCode: input.recoveryCode,
      consumeRecovery: true,
      credential,
    });

    await this.prisma.$transaction(async (tx) => {
      await tx.adminTotpCredential.delete({ where: { userId: input.userId } });
      await tx.adminTotpEnrollmentChallenge.deleteMany({
        where: { userId: input.userId },
      });
      await tx.adminTotpRecoveryCode.deleteMany({
        where: { userId: input.userId },
      });
      await tx.adminTwoFactorSession.deleteMany({
        where: { userId: input.userId },
      });
    });

    return { disabled: true };
  }

  async validateSession(input: {
    userId: string;
    sessionToken: string;
    roles: AppRole[];
  }): Promise<{ valid: boolean; required: boolean; expiresAt: Date | null }> {
    this.assertVaultAvailable();

    const required = this.shouldEnforceChallengeForAdminPanel(
      input.userId,
      input.roles,
    );

    if (!required) {
      return { valid: true, required: false, expiresAt: null };
    }

    const sessionToken = input.sessionToken.trim();
    if (!sessionToken) {
      return { valid: false, required: true, expiresAt: null };
    }

    const tokenHash = this.hashSessionToken(sessionToken);

    const row = await this.prisma.adminTwoFactorSession.findFirst({
      where: {
        userId: input.userId,
        tokenHash,
        revokedAt: null,
        expiresAt: { gt: new Date() },
      },
      select: {
        id: true,
        expiresAt: true,
      },
    });

    if (row) {
      const remainingMs = row.expiresAt.getTime() - Date.now();
      if (remainingMs <= SESSION_EXTENSION_LEEWAY_MS) {
        const extendedExpiresAt = this.computeSessionExpiry();
        await this.prisma.adminTwoFactorSession.update({
          where: { id: row.id },
          data: { expiresAt: extendedExpiresAt },
        });
        return {
          valid: true,
          required: true,
          expiresAt: extendedExpiresAt,
        };
      }
    }

    return {
      valid: Boolean(row),
      required: true,
      expiresAt: row?.expiresAt ?? null,
    };
  }

  async getPolicy(): Promise<AdminTwoFactorPolicyState> {
    this.assertVaultAvailable();

    const row = await this.prisma.adminSecurityPolicy.upsert({
      where: { id: DEFAULT_POLICY_ID },
      update: {},
      create: {
        id: DEFAULT_POLICY_ID,
        require2faForAdminPanel: false,
        updatedById: null,
      },
    });

    return {
      id: row.id,
      require2faForAdminPanel: row.require2faForAdminPanel,
      updatedById: row.updatedById,
      updatedAt: row.updatedAt,
    };
  }

  async updatePolicy(input: {
    actorId: string;
    require2faForAdminPanel: boolean;
  }): Promise<AdminTwoFactorPolicyState> {
    this.assertVaultAvailable();

    if (input.require2faForAdminPanel) {
      await this.assertNoEligibleUserMissingTotp();
    }

    const row = await this.prisma.adminSecurityPolicy.upsert({
      where: { id: DEFAULT_POLICY_ID },
      update: {
        require2faForAdminPanel: input.require2faForAdminPanel,
        updatedById: input.actorId,
      },
      create: {
        id: DEFAULT_POLICY_ID,
        require2faForAdminPanel: input.require2faForAdminPanel,
        updatedById: input.actorId,
      },
    });

    return {
      id: row.id,
      require2faForAdminPanel: row.require2faForAdminPanel,
      updatedById: row.updatedById,
      updatedAt: row.updatedAt,
    };
  }

  async getPolicySummary(): Promise<{
    eligibleUsers: number;
    enabledUsers: number;
    missingUsers: number;
  }> {
    this.assertVaultAvailable();

    const eligibleRows = await this.prisma.userRole.findMany({
      where: {
        role: {
          in: [
            RoleName.owner,
            RoleName.dev,
            RoleName.admin,
          ],
        },
      },
      select: { userId: true },
      distinct: ['userId'],
    });

    const eligibleUserIds = eligibleRows.map((entry) => entry.userId);

    if (eligibleUserIds.length === 0) {
      return {
        eligibleUsers: 0,
        enabledUsers: 0,
        missingUsers: 0,
      };
    }

    const enabledRows = await this.prisma.adminTotpCredential.findMany({
      where: {
        userId: {
          in: eligibleUserIds,
        },
      },
      select: { userId: true },
      distinct: ['userId'],
    });

    return {
      eligibleUsers: eligibleUserIds.length,
      enabledUsers: enabledRows.length,
      missingUsers: eligibleUserIds.length - enabledRows.length,
    };
  }

  private async assertNoEligibleUserMissingTotp(): Promise<void> {
    const eligibleRows = await this.prisma.userRole.findMany({
      where: {
        role: {
          in: [
            RoleName.owner,
            RoleName.dev,
            RoleName.admin,
          ],
        },
      },
      select: { userId: true },
      distinct: ['userId'],
    });

    const eligibleUserIds = eligibleRows.map((entry) => entry.userId);

    if (eligibleUserIds.length === 0) {
      return;
    }

    const credentialRows = await this.prisma.adminTotpCredential.findMany({
      where: {
        userId: {
          in: eligibleUserIds,
        },
      },
      select: { userId: true },
      distinct: ['userId'],
    });

    const enabledSet = new Set(credentialRows.map((entry) => entry.userId));
    const missingIds = eligibleUserIds.filter((id) => !enabledSet.has(id));

    if (missingIds.length === 0) {
      return;
    }

    const missingProfiles = await this.prisma.profile.findMany({
      where: {
        id: {
          in: missingIds,
        },
      },
      select: {
        email: true,
      },
      take: 5,
      orderBy: { email: 'asc' },
    });

    const sampleEmails = missingProfiles.map((entry) => entry.email).join(', ');
    throw new BadRequestException(
      sampleEmails.length > 0
        ? `Cannot enforce admin console 2FA yet. ${missingIds.length} eligible account(s) are missing TOTP (sample: ${sampleEmails}).`
        : `Cannot enforce admin console 2FA yet. ${missingIds.length} eligible account(s) are missing TOTP.`,
    );
  }

  private async assertValidFactor(input: {
    userId: string;
    code?: string;
    recoveryCode?: string;
    consumeRecovery: boolean;
    credential?: AdminTotpCredential;
  }): Promise<void> {
    const normalizedCode = this.normalizeOptionalCode(input.code);
    const normalizedRecovery = this.normalizeOptionalRecoveryCode(
      input.recoveryCode,
    );

    if (!normalizedCode && !normalizedRecovery) {
      throw new BadRequestException(
        'Provide either a TOTP code or a recovery code',
      );
    }

    if (normalizedCode && normalizedRecovery) {
      throw new BadRequestException('Provide only one factor at a time');
    }

    if (normalizedCode) {
      const credential =
        input.credential ?? (await this.getCredentialOrThrow(input.userId));
      const secret = this.decrypt({
        secretCipher: credential.secretCipher,
        secretIv: credential.secretIv,
        secretAuthTag: credential.secretAuthTag,
      });

      if (!verifyTotpCode({ secret, token: normalizedCode })) {
        throw new BadRequestException('Invalid verification code');
      }

      await this.prisma.adminTotpCredential.update({
        where: { userId: input.userId },
        data: {
          lastUsedAt: new Date(),
        },
      });

      return;
    }

    const recoveryCodeHash = this.hashRecoveryCode(normalizedRecovery!);

    if (input.consumeRecovery) {
      const result = await this.prisma.adminTotpRecoveryCode.updateMany({
        where: {
          userId: input.userId,
          codeHash: recoveryCodeHash,
          consumedAt: null,
        },
        data: {
          consumedAt: new Date(),
        },
      });

      if (result.count === 0) {
        throw new BadRequestException('Invalid recovery code');
      }
      return;
    }

    const existing = await this.prisma.adminTotpRecoveryCode.findFirst({
      where: {
        userId: input.userId,
        codeHash: recoveryCodeHash,
        consumedAt: null,
      },
      select: {
        id: true,
      },
    });

    if (!existing) {
      throw new BadRequestException('Invalid recovery code');
    }
  }

  private async getCredentialOrThrow(
    userId: string,
  ): Promise<AdminTotpCredential> {
    const credential = await this.prisma.adminTotpCredential.findUnique({
      where: { userId },
    });

    if (!credential) {
      throw new BadRequestException('TOTP is not enabled for this account');
    }

    return credential;
  }

  private async createSession(
    userId: string,
  ): Promise<AdminTwoFactorSessionResult> {
    const sessionToken = this.generateSessionToken();
    const tokenHash = this.hashSessionToken(sessionToken);
    const expiresAt = this.computeSessionExpiry();

    await this.prisma.adminTwoFactorSession.create({
      data: {
        userId,
        tokenHash,
        expiresAt,
      },
    });

    return {
      sessionToken,
      expiresAt,
    };
  }

  private computeSessionExpiry(): Date {
    return new Date(Date.now() + this.sessionTtlHours * 60 * 60 * 1000);
  }

  private generateSessionToken(): string {
    return randomBytes(32).toString('base64url');
  }

  private generateRecoveryCodes(): string[] {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    const totalChars = RECOVERY_CODE_SEGMENT_LENGTH * RECOVERY_CODE_SEGMENTS;

    const values: string[] = [];
    while (values.length < RECOVERY_CODE_COUNT) {
      const bytes = randomBytes(totalChars);
      let code = '';

      for (const byte of bytes) {
        code += alphabet[byte % alphabet.length];
      }

      const segments: string[] = [];
      for (
        let index = 0;
        index < code.length;
        index += RECOVERY_CODE_SEGMENT_LENGTH
      ) {
        segments.push(code.slice(index, index + RECOVERY_CODE_SEGMENT_LENGTH));
      }

      const candidate = segments.join('-');
      if (!values.includes(candidate)) {
        values.push(candidate);
      }
    }

    return values;
  }

  private normalizeCode(code: string): string {
    return code.trim().replace(/\s+/g, '');
  }

  private normalizeOptionalCode(code: string | undefined): string | null {
    if (!code) return null;
    const normalized = this.normalizeCode(code);
    return normalized.length > 0 ? normalized : null;
  }

  private normalizeOptionalRecoveryCode(
    code: string | undefined,
  ): string | null {
    if (!code) return null;

    const normalized = code
      .trim()
      .toUpperCase()
      .replace(/\s+/g, '')
      .replace(/[^A-Z0-9]/g, '');

    return normalized.length > 0 ? normalized : null;
  }

  private hashSessionToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

  private hashRecoveryCode(code: string): string {
    return createHash('sha256')
      .update(`recovery:${code}:${this.encryptionKey.toString('hex')}`)
      .digest('hex');
  }

  private isAdminPanelEligible(roles: AppRole[]): boolean {
    return roles.some((role) => this.isGovernanceRole(role));
  }

  private isGovernanceRole(role: AppRole): boolean {
    return (
      role === AppRole.OWNER ||
      role === AppRole.DEV ||
      role === AppRole.ADMIN
    );
  }

  private assertEligible(roles: AppRole[]): void {
    if (!this.isAdminPanelEligible(roles)) {
      throw new ForbiddenException(
        'Only owner/dev/admin accounts can use admin console 2FA',
      );
    }
  }

  private resolveSessionTtlHours(): number {
    const raw = this.configService.get<number | string>(
      'ADMIN_2FA_SESSION_TTL_HOURS',
    );

    if (typeof raw === 'number' && Number.isFinite(raw) && raw > 0) {
      return Math.trunc(raw);
    }

    if (typeof raw === 'string') {
      const parsed = Number(raw);
      if (Number.isFinite(parsed) && parsed > 0) {
        return Math.trunc(parsed);
      }
    }

    return 24 * 7;
  }

  private resolveTotpIssuer(): string {
    const envLabel = this.isProductionDeployment() ? 'PROD' : 'DEV';
    return `Blocnet Console (${envLabel})`;
  }

  private resolveTotpAccountName(email: string | null, userId: string): string {
    const normalizedEmail = email?.trim();
    if (normalizedEmail && normalizedEmail.length > 0) {
      return normalizedEmail;
    }
    return userId;
  }

  private resolveEncryptionKey(): Buffer {
    const raw = (
      this.configService.get<string>('ADMIN_TOTP_ENCRYPTION_KEY') ?? ''
    ).trim();

    if (raw.length > 0) {
      if (/^[A-Fa-f0-9]{64}$/.test(raw)) {
        return Buffer.from(raw, 'hex');
      }

      this.logger.error(
        'ADMIN_TOTP_ENCRYPTION_KEY is invalid (expected 64-char hex)',
      );
      return Buffer.alloc(0);
    }

    if (this.isProductionDeployment()) {
      this.logger.error('ADMIN_TOTP_ENCRYPTION_KEY is required in production');
      return Buffer.alloc(0);
    }

    this.logger.warn(
      'Using derived development key for admin TOTP; configure ADMIN_TOTP_ENCRYPTION_KEY before production.',
    );

    return createHash('sha256').update('blocnet.dev.admin-totp').digest();
  }

  private isProductionDeployment(): boolean {
    const deployment = this.resolveDeploymentEnvironment();
    return deployment === 'production' || deployment === 'prod';
  }

  private resolveDeploymentEnvironment(): string {
    const candidates = [
      this.configService.get<string>('APP_ENV'),
      this.configService.get<string>('VERCEL_ENV'),
      this.configService.get<string>('RAILWAY_ENVIRONMENT'),
      this.configService.get<string>('NODE_ENV'),
    ];

    for (const candidate of candidates) {
      const normalized = candidate?.trim().toLowerCase();
      if (normalized) {
        return normalized;
      }
    }

    return 'development';
  }

  private assertVaultAvailable(): void {
    if (this.encryptionKey.length !== 32) {
      throw new ServiceUnavailableException(
        'Admin 2FA is unavailable: encryption key is not configured',
      );
    }
  }

  private encrypt(plaintext: string): {
    cipher: string;
    iv: string;
    authTag: string;
  } {
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', this.encryptionKey, iv);
    const ciphertext = Buffer.concat([
      cipher.update(plaintext, 'utf8'),
      cipher.final(),
    ]);
    const authTag = cipher.getAuthTag();

    return {
      cipher: ciphertext.toString('base64'),
      iv: iv.toString('base64'),
      authTag: authTag.toString('base64'),
    };
  }

  private decrypt(input: {
    secretCipher: string;
    secretIv: string;
    secretAuthTag: string;
  }): string {
    const decipher = createDecipheriv(
      'aes-256-gcm',
      this.encryptionKey,
      Buffer.from(input.secretIv, 'base64'),
    );

    decipher.setAuthTag(Buffer.from(input.secretAuthTag, 'base64'));

    const plaintext = Buffer.concat([
      decipher.update(Buffer.from(input.secretCipher, 'base64')),
      decipher.final(),
    ]);

    return plaintext.toString('utf8');
  }
}
