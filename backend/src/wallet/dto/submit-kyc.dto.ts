import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class SubmitKycDto {
  @IsString()
  @MinLength(2)
  @MaxLength(120)
  fullName!: string;

  @IsString()
  @MinLength(2)
  @MaxLength(120)
  country!: string;

  @IsString()
  @MinLength(2)
  @MaxLength(80)
  documentType!: string;

  @IsString()
  @MinLength(2)
  @MaxLength(8)
  documentNumberLast4!: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  documentUrl?: string;
}
