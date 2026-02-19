import { ContentModerationStatus } from '@prisma/client';
import { IsEnum, IsString, MaxLength, MinLength } from 'class-validator';

export class ModerateCommunityCommentStatusDto {
  @IsEnum(ContentModerationStatus)
  status!: ContentModerationStatus;

  @IsString()
  @MinLength(3)
  @MaxLength(500)
  reason!: string;
}
