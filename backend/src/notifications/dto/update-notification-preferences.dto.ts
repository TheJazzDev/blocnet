import {
  DigestCadence,
  NotificationCategory,
  NotificationType,
} from '@prisma/client';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

export class UpdateCategoryPreferenceDto {
  @IsEnum(NotificationCategory)
  category!: NotificationCategory;

  @IsBoolean()
  enabled!: boolean;
}

export class UpdateTypeOverrideDto {
  @IsEnum(NotificationType)
  type!: NotificationType;

  @IsBoolean()
  enabled!: boolean;
}

export class UpdateNotificationPreferencesDto {
  @IsOptional()
  @IsBoolean()
  masterEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  digestEmailEnabled?: boolean;

  @IsOptional()
  @IsEnum(DigestCadence)
  digestCadence?: DigestCadence;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(23)
  digestHourLocal?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(59)
  digestMinuteLocal?: number;

  @IsOptional()
  @IsString()
  timezone?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(16)
  @ValidateNested({ each: true })
  @Type(() => UpdateCategoryPreferenceDto)
  categories?: UpdateCategoryPreferenceDto[];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(64)
  @ValidateNested({ each: true })
  @Type(() => UpdateTypeOverrideDto)
  typeOverrides?: UpdateTypeOverrideDto[];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(64)
  @IsEnum(NotificationType, { each: true })
  clearTypeOverrides?: NotificationType[];
}
