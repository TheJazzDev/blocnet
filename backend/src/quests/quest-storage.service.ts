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
  'image/png',
  'image/webp',
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
    if (!ALLOWED_QUEST_PROOF_MIME_TYPES.has(file.mimetype)) {
      throw new BadRequestException(
        'Unsupported proof format. Use JPEG, PNG, or WEBP.',
      );
    }
    if (file.size > QUEST_PROOF_MAX_BYTES) {
      throw new BadRequestException('Proof image must be 8MB or smaller');
    }

    const storageClient = this.requireSupabaseStorageClient();
    const extension = this.fileExtensionForMimeType(file.mimetype);
    const objectPath = `${userId}/${questId}/${Date.now()}-${randomUUID()}.${extension}`;
    const bucket = storageClient.storage.from(this.supabaseQuestProofsBucket);

    const { error: uploadError } = await bucket.upload(
      objectPath,
      file.buffer,
      {
        contentType: file.mimetype,
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
      default:
        return 'bin';
    }
  }
}
