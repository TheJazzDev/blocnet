import { Transform } from 'class-transformer';
import { IsString, MaxLength } from 'class-validator';

function toTrimmedString(value: unknown): string | undefined {
  if (typeof value !== 'string') {
    return value as never;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

export class AdminBindReferralDto {
  @IsString()
  @MaxLength(255)
  @Transform(({ value }) => toTrimmedString(value))
  userIdOrEmail!: string;

  @IsString()
  @MaxLength(32)
  @Transform(({ value }) => toTrimmedString(value)?.toUpperCase())
  code!: string;
}
