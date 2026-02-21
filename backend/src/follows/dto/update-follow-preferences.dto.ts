import { UpdateUrgency } from '@prisma/client';
import { IsDateString, IsEnum, IsOptional } from 'class-validator';

export class UpdateFollowPreferencesDto {
  @IsOptional()
  @IsEnum(UpdateUrgency)
  alertMinUrgency?: UpdateUrgency;

  @IsOptional()
  @IsDateString()
  mutedUntil?: string | null;
}
