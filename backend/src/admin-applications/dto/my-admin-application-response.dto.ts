import { ApplicationStatus, ApplicationTargetRole } from '@prisma/client';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * One of the caller's own role applications, as returned by
 * `GET /admin-applications/mine`. Reviewer identity is deliberately omitted.
 */
export class MyAdminApplicationResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ enum: ApplicationTargetRole })
  targetRole!: ApplicationTargetRole;

  @ApiProperty({ enum: ApplicationStatus })
  status!: ApplicationStatus;

  @ApiProperty({ description: 'The reason the applicant submitted' })
  reason!: string;

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt!: Date;

  @ApiPropertyOptional({
    type: String,
    format: 'date-time',
    nullable: true,
    description: 'Set once an owner has approved or rejected the application',
  })
  reviewedAt!: Date | null;
}
