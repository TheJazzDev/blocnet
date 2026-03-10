import { IsEnum, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export enum CommunityAppealDecisionEnum {
  OVERTURN = 'overturn',
  UPHOLD = 'uphold',
  PARTIAL = 'partial',
}

export class ReviewCommunityAppealDto {
  @IsEnum(CommunityAppealDecisionEnum)
  @IsNotEmpty()
  decision: CommunityAppealDecisionEnum;

  @IsString()
  @IsOptional()
  @MaxLength(2000)
  reviewNotes?: string;
}
