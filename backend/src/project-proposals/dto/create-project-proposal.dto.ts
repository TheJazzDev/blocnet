import { IsOptional, IsString, IsUrl, IsUUID, MaxLength } from 'class-validator';

export class CreateProjectProposalDto {
  @IsString()
  @MaxLength(120)
  name!: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  symbol?: string;

  @IsOptional()
  @IsUrl()
  @MaxLength(500)
  websiteUrl?: string;

  @IsString()
  @MaxLength(3000)
  description!: string;

  @IsUUID()
  primaryTagId!: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  reason?: string;
}
