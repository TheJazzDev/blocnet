'use client';

import { Badge } from '@/components/ui/badge';

export function boolBadge(
  enabled: boolean,
  trueLabel = 'Yes',
  falseLabel = 'No',
) {
  if (enabled) {
    return (
      <Badge className='bg-emerald-500/15 text-emerald-300'>{trueLabel}</Badge>
    );
  }
  return <Badge variant='secondary'>{falseLabel}</Badge>;
}

export function formatKeyLabel(value: string) {
  return value
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (char) => char.toUpperCase());
}

export function formatInteger(value: string | number | null | undefined) {
  if (value == null) return 'n/a';
  const parsed = typeof value === 'number' ? value : Number(value);
  if (!Number.isFinite(parsed)) return String(value);
  return parsed.toLocaleString('en-US', { maximumFractionDigits: 0 });
}

export function formatAmount(
  value: string | number | null | undefined,
  maxDecimals = 6,
) {
  if (value == null) return 'n/a';
  const parsed = typeof value === 'number' ? value : Number(value);
  if (!Number.isFinite(parsed)) return String(value);
  return parsed.toLocaleString('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: maxDecimals,
  });
}

export function renderCountGroup(
  title: string,
  values: Record<string, number>,
) {
  return (
    <div className='rounded-lg border p-3'>
      <p className='mb-2 text-xs font-medium uppercase tracking-wide text-muted-foreground'>
        {title}
      </p>
      <div className='space-y-1.5'>
        {Object.entries(values).map(([key, value]) => (
          <div key={key} className='flex items-center justify-between text-sm'>
            <span className='text-muted-foreground'>{formatKeyLabel(key)}</span>
            <span className='font-medium'>{formatInteger(value)}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
