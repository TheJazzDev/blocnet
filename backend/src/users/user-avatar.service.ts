import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { randomUUID } from 'crypto';

export type UploadedAvatarFile = {
  buffer: Buffer;
  mimetype: string;
  size: number;
};

const AVATAR_MAX_BYTES = 5 * 1024 * 1024;
const AVATAR_SIGNED_URL_TTL_SECONDS = 60 * 60 * 24 * 365;
const AVATAR_SIGNED_URL_TIMEOUT_MS = 4000;
const ALLOWED_AVATAR_MIME_TYPES = new Set([
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
]);

@Injectable()
export class UserAvatarService {
  private readonly logger = new Logger(UserAvatarService.name);
  private readonly supabaseUrl: string;
  private readonly supabaseAvatarsBucket: string;
  private readonly supabaseStorageClient: SupabaseClient | null;

  constructor(private readonly configService: ConfigService) {
    this.supabaseUrl = this.configService.get<string>('SUPABASE_URL') ?? '';
    this.supabaseAvatarsBucket =
      this.configService.get<string>('SUPABASE_AVATARS_BUCKET') || 'avatars';
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

  async uploadAvatar(
    userId: string,
    file: UploadedAvatarFile,
  ): Promise<string> {
    if (!file) {
      throw new BadRequestException('Avatar file is required');
    }
    const resolvedMimeType = this.resolveAvatarMimeType(file);
    if (!resolvedMimeType) {
      throw new BadRequestException(
        'Unsupported avatar format. Use JPEG, PNG, WEBP, or HEIC.',
      );
    }
    if (file.size > AVATAR_MAX_BYTES) {
      throw new BadRequestException('Avatar must be 5MB or smaller');
    }

    const storageClient = this.requireSupabaseStorageClient();
    const extension = this.fileExtensionForMimeType(resolvedMimeType);
    const objectPath = `${userId}/${Date.now()}-${randomUUID()}.${extension}`;
    const bucket = storageClient.storage.from(this.supabaseAvatarsBucket);

    const { error: uploadError } = await bucket.upload(
      objectPath,
      file.buffer,
      {
        contentType: resolvedMimeType,
        upsert: false,
      },
    );

    if (uploadError) {
      this.logger.error(`Failed to upload avatar: ${uploadError.message}`);
      throw new BadRequestException('Failed to upload avatar image');
    }

    const {
      data: { publicUrl },
    } = bucket.getPublicUrl(objectPath);

    const signedUrl = await this.createSignedAvatarUrl(objectPath);
    return signedUrl ?? publicUrl;
  }

  async deletePreviousAvatarIfManaged(
    previousAvatarUrl: string | null,
    currentAvatarUrl: string | null, // To avoid deleting what we just uploaded if paths overlap (unlikely with UUIDs but good practice)
  ): Promise<void> {
    if (!previousAvatarUrl) {
      return;
    }

    const previousPath = this.extractManagedAvatarObjectPath(
      previousAvatarUrl,
      {
        includeSigned: true,
      },
    );

    // If we couldn't parse a path, it's not managed by us
    if (!previousPath) {
      return;
    }

    // Check if we are accidentally trying to delete the new one
    if (currentAvatarUrl) {
      const currentPath = this.extractManagedAvatarObjectPath(
        currentAvatarUrl,
        { includeSigned: true },
      );
      if (currentPath === previousPath) {
        return;
      }
    }

    try {
      await this.requireSupabaseStorageClient()
        .storage.from(this.supabaseAvatarsBucket)
        .remove([previousPath]);
    } catch (error) {
      this.logger.warn(
        `Failed to delete previous avatar: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  async resolveAvatarAccessUrl(
    avatarUrl: string | null,
  ): Promise<string | null> {
    if (!avatarUrl) {
      return null;
    }

    const objectPath = this.extractManagedAvatarObjectPath(avatarUrl, {
      includeSigned: false,
    });
    if (!objectPath) {
      return avatarUrl;
    }

    const signedUrl = await this.createSignedAvatarUrl(objectPath);
    return signedUrl ?? avatarUrl;
  }

  isManagedPublicAvatarUrl(avatarUrl: string): boolean {
    if (!this.supabaseUrl) {
      return false;
    }
    const publicPrefix = `${this.supabaseUrl}/storage/v1/object/public/${this.supabaseAvatarsBucket}/`;
    return avatarUrl.startsWith(publicPrefix);
  }

  private requireSupabaseStorageClient(): SupabaseClient {
    if (this.supabaseStorageClient) {
      return this.supabaseStorageClient;
    }

    throw new InternalServerErrorException(
      'Supabase storage is not configured. Set SUPABASE_SECRET_KEY.',
    );
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
      case 'image/heic':
        return 'heic';
      case 'image/heif':
        return 'heif';
      default:
        return 'bin';
    }
  }

  private resolveAvatarMimeType(file: UploadedAvatarFile): string | null {
    const normalized = file.mimetype.trim().toLowerCase().split(';')[0];
    if (ALLOWED_AVATAR_MIME_TYPES.has(normalized)) {
      return normalized;
    }
    return this.detectAvatarMimeTypeFromBuffer(file.buffer);
  }

  private detectAvatarMimeTypeFromBuffer(buffer: Buffer): string | null {
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

    if (buffer.length >= 12 && buffer.toString('ascii', 4, 8) === 'ftyp') {
      const brand = buffer.toString('ascii', 8, 12).toLowerCase();
      if (brand.startsWith('heic') || brand.startsWith('hevc')) {
        return 'image/heic';
      }
      if (brand.startsWith('heif') || brand === 'mif1' || brand === 'msf1') {
        return 'image/heif';
      }
    }

    return null;
  }

  private extractManagedAvatarObjectPath(
    avatarUrl: string,
    opts: { includeSigned?: boolean } = {},
  ): string | null {
    if (!this.supabaseUrl) {
      return null;
    }

    const publicPrefix = `${this.supabaseUrl}/storage/v1/object/public/${this.supabaseAvatarsBucket}/`;
    if (avatarUrl.startsWith(publicPrefix)) {
      return decodeURIComponent(
        avatarUrl.slice(publicPrefix.length).split('?')[0] ?? '',
      );
    }

    if (opts.includeSigned ?? true) {
      const signedPrefix = `${this.supabaseUrl}/storage/v1/object/sign/${this.supabaseAvatarsBucket}/`;
      if (avatarUrl.startsWith(signedPrefix)) {
        return decodeURIComponent(
          avatarUrl.slice(signedPrefix.length).split('?')[0] ?? '',
        );
      }
    }

    return null;
  }

  private async createSignedAvatarUrl(
    objectPath: string,
  ): Promise<string | null> {
    if (!this.supabaseStorageClient) {
      return null;
    }

    let result: {
      data: { signedUrl: string } | null;
      error: { message: string } | null;
    } | null = null;
    try {
      result = await Promise.race([
        this.supabaseStorageClient.storage
          .from(this.supabaseAvatarsBucket)
          .createSignedUrl(objectPath, AVATAR_SIGNED_URL_TTL_SECONDS),
        new Promise<null>((resolve) =>
          setTimeout(() => resolve(null), AVATAR_SIGNED_URL_TIMEOUT_MS),
        ),
      ]);
    } catch (error) {
      this.logger.warn(
        `Avatar signed URL request failed for "${objectPath}": ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
      return null;
    }

    if (!result) {
      this.logger.warn(
        `Avatar signed URL request timed out after ${AVATAR_SIGNED_URL_TIMEOUT_MS}ms for "${objectPath}"`,
      );
      return null;
    }

    const { data, error } = result;

    if (error || !data?.signedUrl) {
      if (error?.message) {
        this.logger.warn(
          `Avatar signed URL generation failed for "${objectPath}": ${error.message}`,
        );
      }
      return null;
    }

    const signedUrl = data.signedUrl.trim();
    if (!signedUrl) {
      return null;
    }
    if (signedUrl.startsWith('http://') || signedUrl.startsWith('https://')) {
      return signedUrl;
    }
    if (signedUrl.startsWith('/object/')) {
      return `${this.supabaseUrl}/storage/v1${signedUrl}`;
    }
    if (signedUrl.startsWith('/')) {
      return `${this.supabaseUrl}${signedUrl}`;
    }
    if (signedUrl.startsWith('storage/')) {
      return `${this.supabaseUrl}/${signedUrl}`;
    }
    if (signedUrl.startsWith('object/')) {
      return `${this.supabaseUrl}/storage/v1/${signedUrl}`;
    }
    return `${this.supabaseUrl}/storage/v1/object/sign/${this.supabaseAvatarsBucket}/${signedUrl}`;
  }
}
