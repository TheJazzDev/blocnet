import {
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';

const evmAddressPattern = /^0x[a-fA-F0-9]{40}$/;

export class CreateInternalTransferDto {
  @IsString()
  @MinLength(1)
  amount!: string;

  @ValidateIf((value: CreateInternalTransferDto) => !value.toAddress)
  @IsUUID()
  toUserId?: string;

  @ValidateIf((value: CreateInternalTransferDto) => !value.toUserId)
  @IsString()
  @Matches(evmAddressPattern, { message: 'toAddress must be a valid EVM address' })
  toAddress?: string;

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
