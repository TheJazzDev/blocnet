import {
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';
import {
  COMMUNITY_REPORT_TARGET_TYPE,
  type CommunityReportTargetType,
} from '../community-moderation.types';

export class CreateCommunityReportDto {
  @IsEnum(COMMUNITY_REPORT_TARGET_TYPE)
  targetType!: CommunityReportTargetType;

  @IsUUID('4')
  targetId!: string;

  @IsString()
  @MinLength(3)
  @MaxLength(200)
  reason!: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  details?: string;
}
