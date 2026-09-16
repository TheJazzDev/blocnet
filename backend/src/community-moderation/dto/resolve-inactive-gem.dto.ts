import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsString, MaxLength, MinLength } from 'class-validator';

export const INACTIVE_GEM_OUTCOMES = [
  'hunter_contacted',
  'no_action',
  'escalated',
] as const;

export type InactiveGemOutcome = (typeof INACTIVE_GEM_OUTCOMES)[number];

/**
 * Closing the open inactivity reports on a gem.
 *
 * There is deliberately no "reassign" outcome: taking a gem from a hunter is
 * a decision a person makes in the console (PRODUCT.md). `escalated` is how a
 * moderator hands it there.
 */
export class ResolveInactiveGemDto {
  @ApiProperty({ enum: INACTIVE_GEM_OUTCOMES })
  @IsIn(INACTIVE_GEM_OUTCOMES)
  outcome!: InactiveGemOutcome;

  @ApiProperty({ minLength: 3, maxLength: 500 })
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  note!: string;
}
