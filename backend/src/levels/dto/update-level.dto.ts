import {
  IsString,
  IsNumber,
  IsOptional,
  IsBoolean,
  Min,
} from 'class-validator';

export class UpdateLevelDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  iconUrl?: string;

  @IsOptional()
  @IsString()
  requiredBnp?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  requiredComments?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  requiredDaysActive?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  requiredQuests?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  requiredUpdates?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  requiredProjects?: number;

  @IsOptional()
  @IsString()
  color?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsNumber()
  sortOrder?: number;
}
