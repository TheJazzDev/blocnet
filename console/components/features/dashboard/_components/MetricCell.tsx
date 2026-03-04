'use client';

type MetricCellProps = {
  label: string;
  value: string;
  hint: string;
};

export function MetricCell({ label, value, hint }: MetricCellProps) {
  return (
    <div className='rounded-lg border p-2'>
      <p className='text-[12px] text-muted-foreground'>{label}</p>
      <p className='text-sm font-semibold'>{value}</p>
      {hint ? <p className='text-[12px] text-muted-foreground'>{hint}</p> : null}
    </div>
  );
}
