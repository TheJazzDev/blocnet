import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

const toInt = ({ value }: { value: unknown }) => {
  if (value === undefined || value === null) return undefined;
  if (typeof value === 'number') return Math.trunc(value);
  if (typeof value === 'string') return Number.parseInt(value, 10);
  return undefined;
};

const toBool = ({ value }: { value: unknown }) => {
  if (value === undefined || value === null) return undefined;
  if (typeof value === 'boolean') return value;
  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase();
    if (normalized === 'true' || normalized === '1') return true;
    if (normalized === 'false' || normalized === '0') return false;
  }
  return value;
};

export const AUDIT_ACTION_FILTER_MAX_VALUES = 10;
export const AUDIT_ACTION_FILTER_MAX_LENGTH = 64;

/**
 * `action=a.b,c.d` (or repeated `action=` params) -> trimmed, de-duplicated
 * string array. Anything that is not a string is passed through so the
 * validators reject it.
 */
const toActionList = ({ value }: { value: unknown }) => {
  if (value === undefined || value === null) return undefined;
  const parts = Array.isArray(value) ? value : [value];
  if (!parts.every((part) => typeof part === 'string')) return value;
  const values = parts
    .flatMap((part) => part.split(','))
    .map((part) => part.trim());
  return [...new Set(values)];
};

export class ListAuditLogQuery {
  @ApiPropertyOptional({ minimum: 1, maximum: 500, default: 100 })
  @IsOptional()
  @Transform(toInt)
  @IsInt()
  @Min(1)
  @Max(500)
  limit?: number;

  @ApiPropertyOptional({ minimum: 0, default: 0 })
  @IsOptional()
  @Transform(toInt)
  @IsInt()
  @Min(0)
  offset?: number;

  @ApiPropertyOptional({
    default: true,
    description:
      'Set to false to drop read-only admin view events (actions ending in ".view"). Defaults to true for backward compatibility.',
  })
  @IsOptional()
  @Transform(toBool)
  @IsBoolean()
  includeViews?: boolean;

  @ApiPropertyOptional({
    type: String,
    example: 'admin.mining.config.update',
    description: `Exact action names to match, comma-separated (max ${AUDIT_ACTION_FILTER_MAX_VALUES} values, each max ${AUDIT_ACTION_FILTER_MAX_LENGTH} chars). Role visibility rules still apply.`,
  })
  @IsOptional()
  @Transform(toActionList)
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(AUDIT_ACTION_FILTER_MAX_VALUES)
  @IsString({ each: true })
  @IsNotEmpty({ each: true })
  @MaxLength(AUDIT_ACTION_FILTER_MAX_LENGTH, { each: true })
  @Matches(/^[A-Za-z0-9_.:-]+$/, {
    each: true,
    message:
      'each action may only contain letters, digits, ".", "_", ":" and "-"',
  })
  action?: string[];
}
