import { ApplicationTargetRole } from '@prisma/client';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional } from 'class-validator';

/** Query string for `GET /admin-applications/mine`. */
export class ListMyApplicationsQueryDto {
  @ApiPropertyOptional({
    enum: ApplicationTargetRole,
    description: 'Only return applications for this role',
    example: ApplicationTargetRole.hunter,
  })
  @IsOptional()
  @IsEnum(ApplicationTargetRole)
  targetRole?: ApplicationTargetRole;
}
