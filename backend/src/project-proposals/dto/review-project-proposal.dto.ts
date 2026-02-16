import { ProjectProposalStatus } from '@prisma/client';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

export class ReviewProjectProposalDto {
  @IsEnum(ProjectProposalStatus)
  status!: ProjectProposalStatus;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;
}
