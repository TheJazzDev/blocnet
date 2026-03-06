import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, IsString, Min } from 'class-validator';
import {
  COMMUNITY_REPORT_STATUS,
  COMMUNITY_REPORT_TARGET_TYPE,
  type CommunityReportStatus,
  type CommunityReportTargetType,
} from '../community-moderation.types';

export class ListCommunityReportsQuery {
  @IsOptional()
  @IsString()
  q?: string;

  @IsOptional()
  @IsEnum(COMMUNITY_REPORT_STATUS)
  status?: CommunityReportStatus;

  @IsOptional()
  @IsEnum(COMMUNITY_REPORT_TARGET_TYPE)
  targetType?: CommunityReportTargetType;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  offset?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number;
}
