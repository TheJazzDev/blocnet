import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, IsUrl } from 'class-validator';

export class SubmitQuestProofDto {
  @ApiProperty({ required: false })
  @IsUrl()
  @IsOptional()
  proofUrl?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  proofText?: string;

  @ApiProperty({ required: false })
  @IsUrl()
  @IsOptional()
  screenshot?: string;
}

export class VerifyQuestDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  submissionId: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  rejectionReason?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  reviewNotes?: string;
}

export class RevokeQuestSubmissionDto {
  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  reviewNotes?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  revocationReason?: string;
}
