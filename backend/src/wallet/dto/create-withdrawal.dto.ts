import {
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { IsEnum } from 'class-validator';
import { WalletAsset } from '@prisma/client';

const evmAddressPattern = /^0x[a-fA-F0-9]{40}$/;

export class CreateWithdrawalDto {
  @IsString()
  @Matches(evmAddressPattern, {
    message: 'toAddress must be a valid EVM address',
  })
  toAddress!: string;

  @IsString()
  @MinLength(1)
  amount!: string;

  @IsOptional()
  @IsEnum(WalletAsset)
  asset?: WalletAsset;

  @IsString()
  @MinLength(3)
  @MaxLength(300)
  reason!: string;

  @IsOptional()
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  idempotencyKey?: string;
}
