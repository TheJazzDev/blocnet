import { IsOptional, IsString, Matches, MaxLength } from 'class-validator';

export class VerifyAdminTotpDto {
  @IsOptional()
  @IsString()
  @Matches(/^\d{6}$/)
  code?: string;

  @IsOptional()
  @IsString()
  @MaxLength(64)
  recoveryCode?: string;
}
