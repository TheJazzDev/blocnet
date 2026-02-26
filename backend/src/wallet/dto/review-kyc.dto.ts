import { KycStatus } from '@prisma/client';
import {
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class ReviewKycDto {
  @IsEnum(KycStatus)
  status!: KycStatus;

  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(64)
  tier?: string;

  @IsString()
  @MinLength(3)
  @MaxLength(500)
  note!: string;
}
