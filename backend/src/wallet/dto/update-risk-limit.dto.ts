import { IsBoolean, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class UpdateRiskLimitDto {
  @IsOptional()
  @IsString()
  @MaxLength(300)
  description?: string;

  @IsOptional()
  @IsBoolean()
  requiresKyc?: boolean;

  @IsOptional()
  @IsString()
  @MinLength(1)
  maxWithdrawalPerTx?: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  maxWithdrawalPerDay?: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  maxInternalTransferPerDay?: string;
}
