import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class SearchUsersQuery {
  @ApiProperty({
    description: 'Search query string',
    example: 'john',
    required: false,
  })
  @IsOptional()
  @IsString()
  q?: string;

  @ApiProperty({ description: 'Maximum results', required: false, default: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;
}
