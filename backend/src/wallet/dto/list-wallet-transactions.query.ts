import { Type } from 'class-transformer';
import { IsIn, IsInt, IsOptional, Min } from 'class-validator';
import { WalletAsset } from '@prisma/client';

/** On-chain assets plus off-chain BNP (read from the tip ledger). */
const TRANSACTION_ASSETS = [...Object.values(WalletAsset), 'BNP'];

export class ListWalletTransactionsQuery {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  offset?: number;

  @IsOptional()
  @IsIn(TRANSACTION_ASSETS)
  asset?: WalletAsset | 'BNP';
}
