import { Transform } from 'class-transformer';
import { IsIn, IsInt, IsISO8601, IsOptional, IsString, Max, Min } from 'class-validator';

export const OPS_EVENT_SOURCES = [
  'email',
  'wallet',
  'tips',
  'social',
  'auth',
  'notifications',
  'system',
] as const;

export const OPS_EVENT_PROVIDERS = [
  'resend',
  'supabase',
  'turnkey',
  'bsc',
  'x',
  'instagram',
  'tiktok',
  'youtube',
  'linkedin',
  'discord',
  'telegram',
  'internal',
  'unknown',
] as const;

export const OPS_EVENT_STATUSES = [
  'success',
  'warning',
  'error',
  'info',
] as const;

export type OpsEventSource = (typeof OPS_EVENT_SOURCES)[number];
export type OpsEventProvider = (typeof OPS_EVENT_PROVIDERS)[number];
export type OpsEventStatus = (typeof OPS_EVENT_STATUSES)[number];

export class ListOpsEventsQuery {
  @IsOptional()
  @IsString()
  q?: string;

  @IsOptional()
  @IsString()
  @IsIn(['all', ...OPS_EVENT_SOURCES])
  source?: 'all' | OpsEventSource;

  @IsOptional()
  @IsString()
  @IsIn(['all', ...OPS_EVENT_PROVIDERS])
  provider?: 'all' | OpsEventProvider;

  @IsOptional()
  @IsString()
  @IsIn(['all', ...OPS_EVENT_STATUSES])
  status?: 'all' | OpsEventStatus;

  @IsOptional()
  @IsISO8601()
  from?: string;

  @IsOptional()
  @IsISO8601()
  to?: string;

  @IsOptional()
  @Transform(({ value }) =>
    value === undefined ? undefined : Number.parseInt(value, 10),
  )
  @IsInt()
  @Min(1)
  @Max(200)
  limit?: number;

  @IsOptional()
  @Transform(({ value }) =>
    value === undefined ? undefined : Number.parseInt(value, 10),
  )
  @IsInt()
  @Min(0)
  offset?: number;
}
