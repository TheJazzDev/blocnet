import { IsOptional, IsString, MaxLength } from 'class-validator';

export class ClaimMiningDto {
  @IsOptional()
  @IsString()
  @MaxLength(128)
  idempotencyKey?: string;
}
