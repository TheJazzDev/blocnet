import { Transform } from 'class-transformer';
import {
  IsInt,
  IsNotIn,
  IsString,
  IsUUID,
  Length,
  Max,
  Min,
} from 'class-validator';

export const MAX_BNP_ADJUSTMENT = 1_000_000;

/** F-66: an owner/admin credit (positive) or debit (negative) of whole BNP. */
export class CreateBnpAdjustmentDto {
  @IsInt()
  @Min(-MAX_BNP_ADJUSTMENT)
  @Max(MAX_BNP_ADJUSTMENT)
  @IsNotIn([0], { message: 'amount must not be zero' })
  amount!: number;

  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @Length(10, 500)
  reason!: string;

  @IsUUID()
  idempotencyKey!: string;
}
