import { ApiProperty } from '@nestjs/swagger';
import { BadgeCategory, QuestType } from '@prisma/client';
import {
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUrl,
  IsUUID,
  Min,
} from 'class-validator';

export class CreateQuestDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  slug: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiProperty({ enum: QuestType })
  @IsEnum(QuestType)
  type: QuestType;

  @ApiProperty({ enum: BadgeCategory })
  @IsEnum(BadgeCategory)
  category: BadgeCategory;

  @ApiProperty({ required: false, default: 0 })
  @IsInt()
  @Min(0)
  @IsOptional()
  rewardPoints?: number;

  @ApiProperty({ required: false })
  @IsUUID()
  @IsOptional()
  rewardBadgeId?: string;

  @ApiProperty({ required: false })
  @IsUrl()
  @IsOptional()
  targetUrl?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  targetAction?: string;

  @ApiProperty({ required: false, default: 'manual' })
  @IsString()
  @IsOptional()
  verificationMethod?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  requiredProof?: string;

  @ApiProperty({ required: false, default: 0 })
  @IsInt()
  @Min(0)
  @IsOptional()
  sortOrder?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  expiresAt?: Date;
}
