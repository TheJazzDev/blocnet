import { Type } from 'class-transformer';
import {
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

export class ApplyCommunityMuteDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(720)
  durationHours!: number;

  @IsString()
  @MinLength(3)
  @MaxLength(500)
  reason!: string;

  @IsOptional()
  @IsUUID('4')
  reportId?: string;
}
