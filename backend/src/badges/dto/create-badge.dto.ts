import { ApiProperty } from '@nestjs/swagger';
import { BadgeCategory, BadgeRarity } from '@prisma/client';
import {
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUrl,
  Min,
} from 'class-validator';

export class CreateBadgeDto {
  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  slug?: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiProperty()
  @IsUrl()
  @IsNotEmpty()
  imageUrl: string;

  @ApiProperty({ enum: BadgeCategory })
  @IsEnum(BadgeCategory)
  category: BadgeCategory;

  @ApiProperty({ enum: BadgeRarity })
  @IsEnum(BadgeRarity)
  rarity: BadgeRarity;

  @ApiProperty({ required: false, default: 0 })
  @IsInt()
  @Min(0)
  @IsOptional()
  pointsRequirement?: number;

  @ApiProperty({ required: false, default: 0 })
  @IsInt()
  @Min(0)
  @IsOptional()
  sortOrder?: number;
}
