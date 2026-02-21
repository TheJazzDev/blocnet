import { IsDateString, IsOptional } from 'class-validator';

export class AckMeRadarDto {
  @IsOptional()
  @IsDateString()
  seenAt?: string;
}
