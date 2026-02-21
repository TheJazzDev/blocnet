import { IsBoolean, IsOptional, IsString, MinLength } from 'class-validator';

export class UpdateWalletAssetPriceDto {
  @IsOptional()
  @IsString()
  providerId?: string | null;

  @IsOptional()
  @IsString()
  @MinLength(1)
  fallbackUsdPrice?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
