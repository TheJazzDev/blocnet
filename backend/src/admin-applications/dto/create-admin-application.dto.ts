import { ApplicationTargetRole } from '@prisma/client';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateAdminApplicationDto {
  @IsOptional()
  @IsEnum(ApplicationTargetRole)
  targetRole?: ApplicationTargetRole;

  @IsString()
  @MaxLength(2000)
  reason!: string;
}
