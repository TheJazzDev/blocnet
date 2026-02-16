import { UpdateStatus, UpdateUrgency } from '@prisma/client';
import {
  ArrayMaxSize,
  IsArray,
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class UpdateUpdateDto {
  @IsOptional()
  @IsString()
  @MaxLength(140)
  title?: string;

  @IsOptional()
  @IsString()
  @MaxLength(15000)
  contentMd?: string;

  @IsOptional()
  @IsEnum(UpdateUrgency)
  urgency?: UpdateUrgency;

  @IsOptional()
  @IsEnum(UpdateStatus)
  status?: UpdateStatus;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @IsUUID('4', { each: true })
  secondaryTagIds?: string[];
}
