import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class UpdateSocialCredentialDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(64)
  provider?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  accountLabel?: string;

  @IsOptional()
  @IsString()
  @MaxLength(160)
  username?: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(512)
  password?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}
