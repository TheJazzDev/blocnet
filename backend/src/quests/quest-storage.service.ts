import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { randomUUID } from 'crypto';

export type UploadedQuestProofFile = {
  buffer: Buffer;
  mimetype: string;
  size: number;
};

const QUEST_PROOF_MAX_BYTES = 8 * 1024 * 1024;
const ALLOWED_QUEST_PROOF_MIME_TYPES = new Set([
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
  'image/heic-sequence',
  'image/heif-sequence',
]);

@Injectable()
export class QuestStorageService {
  private readonly logger = new Logger(QuestStorageService.name);
  private readonly supabaseUrl: string;
  private readonly supabaseQuestProofsBucket: string;
  private readonly supabaseStorageClient: SupabaseClient | null;

  constructor(private readonly configService: ConfigService) {
    this.supabaseUrl = this.configService.get<string>('SUPABASE_URL') ?? '';
    this.supabaseQuestProofsBucket =
      this.configService.get<string>('SUPABASE_QUEST_PROOFS_BUCKET') ||
      'quest-proofs';
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

  async uploadProofImage(
    userId: string,
    questId: string,
    file: UploadedQuestProofFile,
  ): Promise<string> {
    const resolvedMimeType = this.resolveProofMimeType(file);
    if (!resolvedMimeType) {
      throw new BadRequestException(
        'Unsupported proof format. Use JPEG, PNG, WEBP, HEIC, or HEIF.',
      );
    }
    if (file.size > QUEST_PROOF_MAX_BYTES) {
      throw new BadRequestException('Proof image must be 8MB or smaller');
    }

    const storageClient = this.requireSupabaseStorageClient();
    const extension = this.fileExtensionForMimeType(resolvedMimeType);
    const objectPath = `${userId}/${questId}/${Date.now()}-${randomUUID()}.${extension}`;
    const bucket = storageClient.storage.from(this.supabaseQuestProofsBucket);

    const { error: uploadError } = await bucket.upload(
      objectPath,
      file.buffer,
      {
        contentType: resolvedMimeType,
        upsert: false,
      },
    );

    if (uploadError) {
      this.logger.error(
        `Failed to upload quest proof: ${uploadError.message}`,
        uploadError,
      );
      throw new BadRequestException('Failed to upload proof image');
    }

    const {
      data: { publicUrl },
    } = bucket.getPublicUrl(objectPath);

    return publicUrl;
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
      case 'image/heic-sequence':
        return 'heic';
      case 'image/heif':
      case 'image/heif-sequence':
        return 'heif';
      default:
        return 'bin';
    }
  }

  private resolveProofMimeType(file: UploadedQuestProofFile): string | null {
    const normalized = file.mimetype.trim().toLowerCase().split(';')[0];
    if (ALLOWED_QUEST_PROOF_MIME_TYPES.has(normalized)) {
      return normalized;
    }
    return this.detectProofMimeTypeFromBuffer(file.buffer);
  }

  private detectProofMimeTypeFromBuffer(buffer: Buffer): string | null {
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

    // HEIC/HEIF are ISO BMFF containers with an `ftyp` box and brand markers.
    if (buffer.length >= 12 && buffer.toString('ascii', 4, 8) === 'ftyp') {
      const brand = buffer.toString('ascii', 8, 12).toLowerCase();
      if (
        brand == 'heic' ||
        brand == 'heix' ||
        brand == 'hevc' ||
        brand == 'hevx'
      ) {
        return 'image/heic';
      }
      if (brand == 'mif1' || brand == 'msf1') {
        return 'image/heif';
      }
    }

    return null;
  }
}
