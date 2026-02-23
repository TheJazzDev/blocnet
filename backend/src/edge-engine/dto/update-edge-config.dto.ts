import { IsBoolean, IsOptional } from 'class-validator';

export class UpdateEdgeConfigDto {
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;
}
