import { WalletAsset } from '@prisma/client';
import {
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class UpdateWalletRuntimeConfigDto {
  @IsOptional()
  @IsBoolean()
  walletEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  depositsEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  withdrawalsEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  depositRealtimeEnabled?: boolean;

  @IsOptional()
  @IsString()
  bscRpcUrl?: string | null;

  @IsOptional()
  @IsString()
  bscRpcWsUrl?: string | null;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(400)
  depositConfirmations?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(400)
  withdrawalConfirmations?: number;

  @IsOptional()
  @IsBoolean()
  walletAssetBntEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  walletAssetBnbEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  walletAssetUsdtEnabled?: boolean;

  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsEnum(WalletAsset, { each: true })
  withdrawalEnabledAssets?: WalletAsset[];
}
