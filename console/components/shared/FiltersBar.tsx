'use client';

import * as React from 'react';
import { cn } from '@/lib/utils';

export interface FiltersBarProps extends React.HTMLAttributes<HTMLDivElement> {
  left?: React.ReactNode;
  right?: React.ReactNode;
}

export function FiltersBar({ left, right, className, ...rest }: FiltersBarProps) {
  return (
    <div
      className={cn(
        'flex flex-col gap-3 rounded-lg border border-border/60 bg-muted/30 p-3 md:flex-row md:items-center md:justify-between',
        className,
      )}
      {...rest}
    >
      <div className="flex flex-wrap items-center gap-2">{left}</div>
      <div className="flex flex-wrap items-center gap-2">{right}</div>
    </div>
  );
}

