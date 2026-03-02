import { Transform } from 'class-transformer';
import { IsIn, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class SearchPublicProfilesQuery {
  @IsOptional()
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim() : undefined,
  )
  @IsString()
  q?: string;

  @IsOptional()
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : undefined,
  )
  @IsString()
  @IsIn(['all', 'hunter', 'user'])
  role?: 'all' | 'hunter' | 'user';

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
