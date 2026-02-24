import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUrl,
  Min,
} from 'class-validator';
import { BadgeCategory, BadgeRarity } from '@prisma/client';

export class UpdateBadgeDto {
  @ApiPropertyOptional({ example: 'founding-member' })
  @IsOptional()
  @IsString()
  slug?: string;

  @ApiPropertyOptional({ example: 'Founding Member' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({
    example: 'Awarded to users who joined during beta',
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    example: 'https://cdn.blocnet.com/badges/founding-member.png',
  })
  @IsOptional()
  @IsUrl()
  imageUrl?: string;

  @ApiPropertyOptional({ enum: BadgeCategory, example: BadgeCategory.special })
  @IsOptional()
  @IsEnum(BadgeCategory)
  category?: BadgeCategory;

  @ApiPropertyOptional({ enum: BadgeRarity, example: BadgeRarity.legendary })
  @IsOptional()
  @IsEnum(BadgeRarity)
  rarity?: BadgeRarity;

  @ApiPropertyOptional({ example: 1000 })
  @IsOptional()
  @IsInt()
  @Min(0)
  pointsRequirement?: number;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @ApiPropertyOptional({ example: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;
}
