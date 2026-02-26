import { IsBoolean, IsOptional } from 'class-validator';

export class UpdateRuntimeFeatureFlagsDto {
  @IsOptional()
  @IsBoolean()
  alphaRadarEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  followPrefsEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  weeklyDigestEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  miningEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  referralsEnabled?: boolean;
}
