import { ProjectStatus } from '@prisma/client';
import { IsEnum, IsString, MaxLength, MinLength } from 'class-validator';

export class ModerateProjectStatusDto {
  @IsEnum(ProjectStatus)
  status!: ProjectStatus;

  @IsString()
  @MinLength(3)
  @MaxLength(500)
  reason!: string;
}
