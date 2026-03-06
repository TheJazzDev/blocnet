import { IsEnum, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import {
  COMMUNITY_REPORT_STATUS,
  type CommunityReportStatus,
} from '../community-moderation.types';

export class ReviewCommunityReportDto {
  @IsEnum(COMMUNITY_REPORT_STATUS)
  status!: CommunityReportStatus;

  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  note?: string;
}
