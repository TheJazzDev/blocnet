import { Type } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';

export class GetAdminEdgeOverviewQuery {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(30)
  windowDays?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(5)
  @Max(100)
  decisionsLimit?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(3)
  @Max(20)
  projectsLimit?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(3)
  @Max(30)
  reasonLimit?: number;
}
