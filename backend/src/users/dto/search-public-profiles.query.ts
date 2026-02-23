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
