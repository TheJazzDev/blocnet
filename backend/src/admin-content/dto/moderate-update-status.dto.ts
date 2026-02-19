import { UpdateStatus } from '@prisma/client';
import { IsEnum, IsString, MaxLength, MinLength } from 'class-validator';

export class ModerateUpdateStatusDto {
  @IsEnum(UpdateStatus)
  status!: UpdateStatus;

  @IsString()
  @MinLength(3)
  @MaxLength(500)
  reason!: string;
}
