import { IsBoolean, IsOptional, IsString, MinLength } from 'class-validator';

export class UpdateWalletFeeDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  flatFee?: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  percentFee?: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  minFee?: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  maxFee?: string | null;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
