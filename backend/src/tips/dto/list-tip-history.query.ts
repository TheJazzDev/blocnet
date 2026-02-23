import { Transform } from 'class-transformer';
import { IsIn, IsInt, IsOptional, IsString, Matches, Max, Min } from 'class-validator';

const currencyCodePattern = /^[A-Z0-9]{2,12}$/;

export class ListTipHistoryQuery {
  @IsOptional()
  @IsString()
  @IsIn(['all', 'sent', 'received'])
  direction?: 'all' | 'sent' | 'received';

  @IsOptional()
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim().toUpperCase() : value,
  )
  @IsString()
  @Matches(currencyCodePattern)
  currencyCode?: string;

  @IsOptional()
  @Transform(({ value }) =>
    value === undefined ? undefined : Number.parseInt(value, 10),
  )
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;

  @IsOptional()
  @Transform(({ value }) =>
    value === undefined ? undefined : Number.parseInt(value, 10),
  )
  @IsInt()
  @Min(0)
  offset?: number;
}

