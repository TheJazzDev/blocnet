import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { randomUUID } from 'crypto';

export type UploadedLevelIconFile = {
  buffer: Buffer;
  mimetype: string;
  size: number;
};

const LEVEL_ICON_MAX_BYTES = 3 * 1024 * 1024;
const ALLOWED_LEVEL_ICON_MIME_TYPES = new Set([
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
  'image/svg+xml',
]);

@Injectable()
export class LevelIconStorageService {
  private readonly logger = new Logger(LevelIconStorageService.name);
  private readonly supabaseUrl: string;
  private readonly supabaseLevelBadgesBucket: string;
  private readonly supabaseStorageClient: SupabaseClient | null;

  constructor(private readonly configService: ConfigService) {
    this.supabaseUrl = (
      this.configService.get<string>('SUPABASE_URL') ?? ''
    ).replace(/\/+$/, '');
    this.supabaseLevelBadgesBucket =
      this.configService.get<string>('SUPABASE_LEVEL_BADGES_BUCKET') ||
      'level-badges';
    const serviceRoleKey =
      this.configService.get<string>('SUPABASE_SECRET_KEY') ||
      this.configService.get<string>('SUPABASE_SERVICE_ROLE_KEY');

    if (this.supabaseUrl && serviceRoleKey) {
      this.supabaseStorageClient = createClient(
        this.supabaseUrl,
        serviceRoleKey,
        {
          auth: {
            autoRefreshToken: false,
            persistSession: false,
          },
        },
      );
    } else {
      this.supabaseStorageClient = null;
    }
  }

  async uploadLevelIcon(
    levelId: string,
    file: UploadedLevelIconFile,
  ): Promise<string> {
    const resolvedMimeType = this.resolveIconMimeType(file);
    if (!resolvedMimeType) {
      throw new BadRequestException(
        'Unsupported icon format. Use SVG, PNG, JPEG, or WEBP.',
      );
    }
    if (file.size > LEVEL_ICON_MAX_BYTES) {
      throw new BadRequestException('Level icon must be 3MB or smaller');
    }

    const storageClient = this.requireSupabaseStorageClient();
    const extension = this.fileExtensionForMimeType(resolvedMimeType);
    const objectPath = `levels/${levelId}/${Date.now()}-${randomUUID()}.${extension}`;
    const bucket = storageClient.storage.from(this.supabaseLevelBadgesBucket);

    const { error: uploadError } = await bucket.upload(
      objectPath,
      file.buffer,
      {
        contentType: resolvedMimeType,
        upsert: true,
      },
    );

    if (uploadError) {
      this.logger.error(
        `Failed to upload level icon: ${uploadError.message}`,
        uploadError,
      );
      throw new BadRequestException('Failed to upload level icon');
    }

    const {
      data: { publicUrl },
    } = bucket.getPublicUrl(objectPath);

    return publicUrl;
  }

  async deletePreviousLevelIconIfManaged(
    previousIconUrl: string | null,
    currentIconUrl: string | null,
  ): Promise<void> {
    if (!previousIconUrl) {
      return;
    }

    const previousPath =
      this.extractManagedLevelIconObjectPath(previousIconUrl);
    if (!previousPath) {
      return;
    }

    if (currentIconUrl) {
      const currentPath = this.extractManagedLevelIconObjectPath(currentIconUrl);
      if (currentPath === previousPath) {
        return;
      }
    }

    await this.deleteLevelIconObjectPath(previousPath, 'previous');
  }

  async deleteManagedLevelIconIfManaged(iconUrl: string | null): Promise<void> {
    if (!iconUrl) {
      return;
    }

    const path = this.extractManagedLevelIconObjectPath(iconUrl);
    if (!path) {
      return;
    }

    await this.deleteLevelIconObjectPath(path, 'uploaded');
  }

  private requireSupabaseStorageClient(): SupabaseClient {
    if (this.supabaseStorageClient) {
      return this.supabaseStorageClient;
    }

    throw new InternalServerErrorException(
      'Supabase storage is not configured. Set SUPABASE_SECRET_KEY.',
    );
  }

  private async deleteLevelIconObjectPath(
    objectPath: string,
    label: 'previous' | 'uploaded',
  ): Promise<void> {
    try {
      const { error } = await this.requireSupabaseStorageClient()
        .storage.from(this.supabaseLevelBadgesBucket)
        .remove([objectPath]);

      if (error) {
        this.logger.warn(
          `Failed to delete ${label} level icon "${objectPath}": ${error.message}`,
        );
      }
    } catch (error) {
      this.logger.warn(
        `Failed to delete ${label} level icon "${objectPath}": ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  private extractManagedLevelIconObjectPath(iconUrl: string): string | null {
    if (!this.supabaseUrl) {
      return null;
    }

    const publicPrefix = `${this.supabaseUrl}/storage/v1/object/public/${this.supabaseLevelBadgesBucket}/`;
    if (iconUrl.startsWith(publicPrefix)) {
      return decodeURIComponent(iconUrl.slice(publicPrefix.length).split('?')[0] ?? '');
    }

    const signedPrefix = `${this.supabaseUrl}/storage/v1/object/sign/${this.supabaseLevelBadgesBucket}/`;
    if (iconUrl.startsWith(signedPrefix)) {
      return decodeURIComponent(iconUrl.slice(signedPrefix.length).split('?')[0] ?? '');
    }

    return null;
  }

  private fileExtensionForMimeType(mimeType: string): string {
    switch (mimeType) {
      case 'image/jpeg':
      case 'image/jpg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'image/svg+xml':
        return 'svg';
      default:
        return 'bin';
    }
  }

  private resolveIconMimeType(file: UploadedLevelIconFile): string | null {
    const normalized = file.mimetype.trim().toLowerCase().split(';')[0];
    if (ALLOWED_LEVEL_ICON_MIME_TYPES.has(normalized)) {
      return normalized;
    }
    return this.detectIconMimeTypeFromBuffer(file.buffer);
  }

  private detectIconMimeTypeFromBuffer(buffer: Buffer): string | null {
    if (
      buffer.length >= 3 &&
      buffer[0] === 0xff &&
      buffer[1] === 0xd8 &&
      buffer[2] === 0xff
    ) {
      return 'image/jpeg';
    }

    if (
      buffer.length >= 8 &&
      buffer[0] === 0x89 &&
      buffer[1] === 0x50 &&
      buffer[2] === 0x4e &&
      buffer[3] === 0x47 &&
      buffer[4] === 0x0d &&
      buffer[5] === 0x0a &&
      buffer[6] === 0x1a &&
      buffer[7] === 0x0a
    ) {
      return 'image/png';
    }

    if (
      buffer.length >= 12 &&
      buffer.toString('ascii', 0, 4) === 'RIFF' &&
      buffer.toString('ascii', 8, 12) === 'WEBP'
    ) {
      return 'image/webp';
    }

    const prefix = buffer
      .subarray(0, 512)
      .toString('utf8')
      .trimStart()
      .toLowerCase();
    if (prefix.startsWith('<svg')) {
      return 'image/svg+xml';
    }

    return null;
  }
}
