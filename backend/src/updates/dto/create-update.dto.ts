import { UpdateUrgency } from '@prisma/client';
import {
  ArrayMaxSize,
  IsArray,
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class CreateUpdateDto {
  @IsString()
  @MaxLength(140)
  title!: string;

  @IsString()
  @MaxLength(15000)
  contentMd!: string;

  @IsEnum(UpdateUrgency)
  urgency!: UpdateUrgency;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @IsUUID('4', { each: true })
  secondaryTagIds?: string[];
}
