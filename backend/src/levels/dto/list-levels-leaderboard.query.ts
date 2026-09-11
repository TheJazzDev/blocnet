import { Type } from 'class-transformer';
import { IsInt, IsOptional, Min } from 'class-validator';

/**
 * Query for `GET /levels/leaderboard`.
 *
 * Mirrors `ListMiningLeaderboardQuery` so both leaderboards validate and
 * paginate the same way: the global ValidationPipe (`transform: true`) coerces
 * the raw query strings to numbers and rejects anything that is not a whole
 * number in range with a 400 — previously `?limit=abc` reached Prisma as
 * `take: NaN` and surfaced as a 500.
 */
export class ListLevelsLeaderboardQuery {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  offset?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number;
}
