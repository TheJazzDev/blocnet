import { ChainEnvironment, WalletAsset } from '@prisma/client';
import { IsEnum, IsOptional, Matches } from 'class-validator';

export class ReprocessDepositByTxHashDto {
  @Matches(/^0x[a-fA-F0-9]{64}$/, {
    message: 'txHash must be a valid EVM transaction hash',
  })
  txHash!: string;

  @IsOptional()
  @IsEnum(ChainEnvironment)
  chainEnvironment?: ChainEnvironment;

  @IsOptional()
  @IsEnum(WalletAsset)
  asset?: WalletAsset;
}
