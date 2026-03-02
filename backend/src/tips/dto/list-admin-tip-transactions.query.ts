import { Transform } from 'class-transformer';
import {
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  Max,
  Min,
} from 'class-validator';

const currencyCodePattern = /^[A-Z0-9]{2,12}$/;

export class ListAdminTipTransactionsQuery {
  @IsOptional()
  @IsString()
  q?: string;

  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toUpperCase() : undefined,
  )
  @IsString()
  @Matches(currencyCodePattern)
  currencyCode?: string;

  @IsOptional()
  @IsUUID()
  userId?: string;

  @IsOptional()
  @IsString()
  @IsIn(['all', 'sent', 'received'])
  direction?: 'all' | 'sent' | 'received';

  @IsOptional()
  @Transform(({ value }: { value: unknown }) => {
    if (value === undefined || value === null) return undefined;
    if (typeof value === 'number') return Math.trunc(value);
    if (typeof value === 'string') return Number.parseInt(value, 10);
    return undefined;
  })
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;

  @IsOptional()
  @Transform(({ value }: { value: unknown }) => {
    if (value === undefined || value === null) return undefined;
    if (typeof value === 'number') return Math.trunc(value);
    if (typeof value === 'string') return Number.parseInt(value, 10);
    return undefined;
  })
  @IsInt()
  @Min(0)
  offset?: number;
}
