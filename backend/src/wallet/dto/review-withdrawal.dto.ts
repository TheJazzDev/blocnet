import { IsEnum, IsString, MaxLength, MinLength } from 'class-validator';

export enum WithdrawalReviewDecision {
  approved = 'approved',
  rejected = 'rejected',
}

export class ReviewWithdrawalDto {
  @IsEnum(WithdrawalReviewDecision)
  status!: WithdrawalReviewDecision;

  @IsString()
  @MinLength(3)
  @MaxLength(500)
  reason!: string;
}
