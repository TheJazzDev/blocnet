import { ApplicationStatus } from '@prisma/client';
import { IsEnum } from 'class-validator';

export class ReviewAdminApplicationDto {
  @IsEnum(ApplicationStatus)
  status!: ApplicationStatus;
}
