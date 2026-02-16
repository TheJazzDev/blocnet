import { IsOptional, IsString } from 'class-validator';

export class VerifySessionDto {
  @IsOptional()
  @IsString()
  accessToken?: string;
}
