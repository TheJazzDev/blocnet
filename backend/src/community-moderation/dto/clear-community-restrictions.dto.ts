import { IsOptional, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';

export class ClearCommunityRestrictionsDto {
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  reason!: string;

  @IsOptional()
  @IsUUID('4')
  reportId?: string;
}
