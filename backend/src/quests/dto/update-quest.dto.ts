import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUrl,
  IsUUID,
  Min,
} from 'class-validator';
import {
  BadgeCategory,
  QuestType,
} from '@prisma/client';

export class UpdateQuestDto {
  @ApiPropertyOptional({ example: 'follow-on-x' })
  @IsOptional()
  @IsString()
  slug?: string;

  @ApiPropertyOptional({ example: 'Follow us on X' })
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional({
    example: 'Follow our official X account to stay updated',
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ enum: QuestType, example: QuestType.social_media })
  @IsOptional()
  @IsEnum(QuestType)
  type?: QuestType;

  @ApiPropertyOptional({ enum: BadgeCategory, example: BadgeCategory.social })
  @IsOptional()
  @IsEnum(BadgeCategory)
  category?: BadgeCategory;

  @ApiPropertyOptional({ example: 50 })
  @IsOptional()
  @IsInt()
  @Min(0)
  rewardPoints?: number;

  @ApiPropertyOptional({
    example: '123e4567-e89b-12d3-a456-426614174000',
    nullable: true,
  })
  @IsOptional()
  @IsUUID()
  rewardBadgeId?: string | null;

  @ApiPropertyOptional({ example: 'https://x.com/blocnet', nullable: true })
  @IsOptional()
  @IsUrl()
  targetUrl?: string | null;

  @ApiPropertyOptional({ example: 'follow_on_x', nullable: true })
  @IsOptional()
  @IsString()
  targetAction?: string | null;

  @ApiPropertyOptional({ example: 'manual' })
  @IsOptional()
  @IsString()
  verificationMethod?: string;

  @ApiPropertyOptional({
    example: 'Provide a screenshot showing you followed our account',
    nullable: true,
  })
  @IsOptional()
  @IsString()
  requiredProof?: string | null;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @ApiPropertyOptional({ example: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;

  @ApiPropertyOptional({
    example: '2024-12-31T23:59:59Z',
    nullable: true,
  })
  @IsOptional()
  @IsDateString()
  expiresAt?: string | null;
}
