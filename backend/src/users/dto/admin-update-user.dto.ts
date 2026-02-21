import { Transform } from 'class-transformer';
import { IsOptional, IsString, Matches, MaxLength } from 'class-validator';

function toOptionalTrimmedString(value: unknown): string | null | undefined {
  if (value === undefined) {
    return undefined;
  }
  if (value === null) {
    return null;
  }
  if (typeof value !== 'string') {
    return value as never;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

export class AdminUpdateUserDto {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  @Transform(({ value }) => toOptionalTrimmedString(value))
  displayName?: string | null;

  @IsOptional()
  @IsString()
  @Matches(/^[a-z0-9_]{3,24}$/)
  @Transform(({ value }) => {
    const normalized = toOptionalTrimmedString(value);
    return typeof normalized === 'string'
      ? normalized.toLowerCase()
      : normalized;
  })
  username?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(2048)
  @Transform(({ value }) => toOptionalTrimmedString(value))
  avatarUrl?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(300)
  @Transform(({ value }) => toOptionalTrimmedString(value))
  bio?: string | null;
}
