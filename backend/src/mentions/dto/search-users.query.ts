import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min, MinLength } from 'class-validator';

export class SearchUsersQuery {
  @ApiProperty({ description: 'Search query string', example: 'john' })
  @IsString()
  @MinLength(1)
  q: string;

  @ApiProperty({ description: 'Maximum results', required: false, default: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;
}
