import { PostUrgency } from '@prisma/client';
import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, IsString, Min } from 'class-validator';

export class ListPostsQuery {
  @IsOptional()
  @IsString()
  projectId?: string;

  @IsOptional()
  @IsEnum(PostUrgency)
  urgency?: PostUrgency;

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
