import {
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';
import { WalletAsset } from '@prisma/client';

const evmAddressPattern = /^0x[a-fA-F0-9]{40}$/;
const usernamePattern = /^@?[a-zA-Z0-9_]{3,24}$/;

export class CreateInternalTransferDto {
  @IsString()
  @MinLength(1)
  amount!: string;

  @IsOptional()
  @IsEnum(WalletAsset)
  asset?: WalletAsset;

  @ValidateIf(
    (value: CreateInternalTransferDto) =>
      !value.toAddress && !value.toUsername,
  )
  @IsUUID()
  toUserId?: string;

  @ValidateIf(
    (value: CreateInternalTransferDto) =>
      !value.toUserId && !value.toUsername,
  )
  @IsString()
  @Matches(evmAddressPattern, { message: 'toAddress must be a valid EVM address' })
  toAddress?: string;

  @ValidateIf(
    (value: CreateInternalTransferDto) =>
      !value.toUserId && !value.toAddress,
  )
  @IsString()
  @Matches(usernamePattern, {
    message:
      'toUsername must be a valid username (3-24 letters, numbers, underscores)',
  })
  toUsername?: string;

  @IsOptional()
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  idempotencyKey?: string;

  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(300)
  note?: string;
}
