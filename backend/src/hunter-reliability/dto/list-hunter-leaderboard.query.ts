import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, Matches, Max, Min } from 'class-validator';

export const LEADERBOARD_DEFAULT_LIMIT = 20;
export const LEADERBOARD_MAX_LIMIT = 50;

export class ListHunterLeaderboardQuery {
  @ApiPropertyOptional({
    default: LEADERBOARD_DEFAULT_LIMIT,
    minimum: 1,
    maximum: LEADERBOARD_MAX_LIMIT,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(LEADERBOARD_MAX_LIMIT)
  limit?: number;

  @ApiPropertyOptional({
    description: 'Opaque cursor from a previous page’s `nextCursor`.',
  })
  @IsOptional()
  @Matches(/^\d{1,6}$/, { message: 'cursor is invalid' })
  cursor?: string;
}
