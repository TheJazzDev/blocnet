import { UpdateUrgency } from '@prisma/client';
import {
  ArrayMaxSize,
  IsArray,
  IsDateString,
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

  /**
   * When the window this update describes closes, as an ISO 8601 string.
   *
   * Optional, and most updates will not carry one. A past date is accepted on
   * purpose: a hunter may be reporting a window that has already shut, and the
   * app states that ("Window closed 9 days ago") rather than hiding it.
   */
  @IsOptional()
  @IsDateString()
  deadlineAt?: string | null;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @IsUUID('4', { each: true })
  secondaryTagIds?: string[];
}
