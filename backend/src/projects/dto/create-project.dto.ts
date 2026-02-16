import {
  ArrayMaxSize,
  IsArray,
  IsOptional,
  IsString,
  IsUrl,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class CreateProjectDto {
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
  @IsArray()
  @ArrayMaxSize(20)
  @IsUUID('4', { each: true })
  secondaryTagIds?: string[];
}
