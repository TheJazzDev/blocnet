import {
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

/** `@username` / `username`, or a profile id (UUID). */
const recipientPattern =
  /^(?:@?[a-zA-Z0-9_]{3,24}|[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$/;

/** Member-to-member BNP transfer (`POST /tips/transfers`). */
export class CreatePointsTransferDto {
  @IsString()
  @Matches(recipientPattern, {
    message: 'recipient must be a @username or a profile id',
  })
  recipient!: string;

  /** Whole atomic units (BNP has 3 decimals: "1500" = 1.5 BNP). */
  @IsString()
  @Matches(/^\d{1,30}$/, {
    message: 'amountAtomic must be a positive whole number of atomic units',
  })
  amountAtomic!: string;

  @IsOptional()
  @IsString()
  @MaxLength(220)
  note?: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  idempotencyKey!: string;
}
