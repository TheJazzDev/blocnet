import {
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SocialCredential } from '@prisma/client';
import { createCipheriv, createDecipheriv, createHash, randomBytes } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { CreateSocialCredentialDto } from './dto/create-social-credential.dto';
import { UpdateSocialCredentialDto } from './dto/update-social-credential.dto';

type SerializedSocialCredential = {
  id: string;
  provider: string;
  accountLabel: string | null;
  username: string | null;
  notes: string | null;
  passwordMasked: string;
  createdById: string;
  updatedById: string | null;
  createdAt: Date;
  updatedAt: Date;
};

@Injectable()
export class SocialCredentialsService {
  private readonly logger = new Logger(SocialCredentialsService.name);
  private readonly encryptionKey: Buffer;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {
    this.encryptionKey = this.resolveEncryptionKey();
  }

  async list(): Promise<SerializedSocialCredential[]> {
    this.assertVaultAvailable();
    const rows = await this.prisma.socialCredential.findMany({
      orderBy: [{ provider: 'asc' }, { updatedAt: 'desc' }],
    });
    return rows.map((row) => this.serializeRow(row));
  }

  async revealPassword(id: string): Promise<{ id: string; password: string }> {
    this.assertVaultAvailable();
    const row = await this.prisma.socialCredential.findUnique({
      where: { id },
    });
    if (!row) {
      throw new NotFoundException('Credential not found');
    }

    return {
      id: row.id,
      password: this.decrypt(row),
    };
  }

  async create(
    actorId: string,
    dto: CreateSocialCredentialDto,
  ): Promise<SerializedSocialCredential> {
    this.assertVaultAvailable();
    const encrypted = this.encrypt(dto.password);
    const row = await this.prisma.socialCredential.create({
      data: {
        provider: this.normalizeProvider(dto.provider),
        accountLabel: this.normalizeNullable(dto.accountLabel),
        username: this.normalizeNullable(dto.username),
        notes: this.normalizeNullable(dto.notes),
        passwordCipher: encrypted.cipher,
        passwordIv: encrypted.iv,
        passwordAuthTag: encrypted.authTag,
        createdById: actorId,
        updatedById: actorId,
      },
    });
    return this.serializeRow(row);
  }

  async update(
    id: string,
    actorId: string,
    dto: UpdateSocialCredentialDto,
  ): Promise<SerializedSocialCredential> {
    this.assertVaultAvailable();
    const existing = await this.prisma.socialCredential.findUnique({
      where: { id },
    });
    if (!existing) {
      throw new NotFoundException('Credential not found');
    }

    const encrypted =
      dto.password === undefined ? null : this.encrypt(dto.password);

    const row = await this.prisma.socialCredential.update({
      where: { id },
      data: {
        ...(dto.provider === undefined
          ? {}
          : { provider: this.normalizeProvider(dto.provider) }),
        ...(dto.accountLabel === undefined
          ? {}
          : { accountLabel: this.normalizeNullable(dto.accountLabel) }),
        ...(dto.username === undefined
          ? {}
          : { username: this.normalizeNullable(dto.username) }),
        ...(dto.notes === undefined
          ? {}
          : { notes: this.normalizeNullable(dto.notes) }),
        ...(encrypted
          ? {
              passwordCipher: encrypted.cipher,
              passwordIv: encrypted.iv,
              passwordAuthTag: encrypted.authTag,
            }
          : {}),
        updatedById: actorId,
      },
    });
    return this.serializeRow(row);
  }

  async remove(id: string): Promise<{ id: string; deleted: true }> {
    this.assertVaultAvailable();
    const existing = await this.prisma.socialCredential.findUnique({
      where: { id },
      select: { id: true },
    });
    if (!existing) {
      throw new NotFoundException('Credential not found');
    }

    await this.prisma.socialCredential.delete({
      where: { id },
    });
    return { id, deleted: true };
  }

  private serializeRow(row: SocialCredential): SerializedSocialCredential {
    return {
      id: row.id,
      provider: row.provider,
      accountLabel: row.accountLabel,
      username: row.username,
      notes: row.notes,
      passwordMasked: '*****',
      createdById: row.createdById,
      updatedById: row.updatedById,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  private resolveEncryptionKey(): Buffer {
    const raw = (
      this.configService.get<string>(
        'ADMIN_SOCIAL_CREDENTIALS_ENCRYPTION_KEY',
      ) ?? ''
    ).trim();

    if (raw.length > 0) {
      if (/^[A-Fa-f0-9]{64}$/.test(raw)) {
        return Buffer.from(raw, 'hex');
      }
      this.logger.error(
        'ADMIN_SOCIAL_CREDENTIALS_ENCRYPTION_KEY is invalid (expected 64-char hex)',
      );
      return Buffer.alloc(0);
    }

    const nodeEnv =
      (this.configService.get<string>('NODE_ENV') ?? 'development').trim() ||
      'development';

    if (nodeEnv === 'production') {
      this.logger.error(
        'ADMIN_SOCIAL_CREDENTIALS_ENCRYPTION_KEY is required in production',
      );
      return Buffer.alloc(0);
    }

    this.logger.warn(
      'Using derived development key for social credential vault; configure ADMIN_SOCIAL_CREDENTIALS_ENCRYPTION_KEY before production.',
    );
    return createHash('sha256')
      .update('blocnet.dev.social-credentials')
      .digest();
  }

  private assertVaultAvailable(): void {
    if (this.encryptionKey.length !== 32) {
      throw new ServiceUnavailableException(
        'Social credential vault is unavailable: encryption key is not configured',
      );
    }
  }

  private encrypt(password: string): {
    cipher: string;
    iv: string;
    authTag: string;
  } {
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', this.encryptionKey, iv);
    const ciphertext = Buffer.concat([
      cipher.update(password, 'utf8'),
      cipher.final(),
    ]);
    const authTag = cipher.getAuthTag();

    return {
      cipher: ciphertext.toString('base64'),
      iv: iv.toString('base64'),
      authTag: authTag.toString('base64'),
    };
  }

  private decrypt(row: SocialCredential): string {
    const iv = Buffer.from(row.passwordIv, 'base64');
    const authTag = Buffer.from(row.passwordAuthTag, 'base64');
    const ciphertext = Buffer.from(row.passwordCipher, 'base64');

    const decipher = createDecipheriv('aes-256-gcm', this.encryptionKey, iv);
    decipher.setAuthTag(authTag);
    const plaintext = Buffer.concat([
      decipher.update(ciphertext),
      decipher.final(),
    ]);
    return plaintext.toString('utf8');
  }

  private normalizeProvider(provider: string): string {
    return provider.trim().toLowerCase();
  }

  private normalizeNullable(input?: string): string | null {
    if (input === undefined) return null;
    const normalized = input.trim();
    return normalized.length > 0 ? normalized : null;
  }
}
