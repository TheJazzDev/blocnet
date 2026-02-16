import { UpdateUrgency } from '@prisma/client';
import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, IsString, Min } from 'class-validator';

export class ListUpdatesQuery {
  @IsOptional()
  @IsString()
  projectId?: string;

  @IsOptional()
  @IsEnum(UpdateUrgency)
  urgency?: UpdateUrgency;

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
