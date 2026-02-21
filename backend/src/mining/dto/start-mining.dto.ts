import { IsOptional, IsString, MaxLength } from 'class-validator';

export class StartMiningDto {
  @IsOptional()
  @IsString()
  @MaxLength(128)
  idempotencyKey?: string;
}
