'use client';

import Link from 'next/link';
import { ChevronDown } from 'lucide-react';
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from '@/components/ui/collapsible';
import { cn } from '@/lib/utils';
import { isNavItemActive, type NavGroup } from './sidebar-nav-items';

type SidebarNavGroupProps = {
  group: NavGroup;
  pathname: string;
  open: boolean;
  onOpenChange: (open: boolean) => void;
};

export function SidebarNavGroup({
  group,
  pathname,
  open,
  onOpenChange,
}: SidebarNavGroupProps) {
  const containsActive = group.items.some((item) =>
    isNavItemActive(item, pathname),
  );

  return (
    <Collapsible open={open} onOpenChange={onOpenChange}>
      <CollapsibleTrigger
        className={cn(
          'flex w-full items-center justify-between rounded-md px-3 py-1.5 text-[10px] font-semibold uppercase tracking-[0.08em] transition-colors',
          containsActive ? 'text-primary' : 'text-primary/70 hover:text-primary',
        )}>
        <span>{group.label}</span>
        <span className='flex items-center gap-1.5'>
          {!open && containsActive && (
            <span
              aria-label='Contains the current page'
              className='h-1.5 w-1.5 rounded-full bg-primary'
            />
          )}
          <ChevronDown
            className={cn(
              'h-3.5 w-3.5 transition-transform duration-200',
              open && 'rotate-180',
            )}
          />
        </span>
      </CollapsibleTrigger>
      <CollapsibleContent className='space-y-1 pt-1'>
        {group.items.map((item) => {
          const isActive = isNavItemActive(item, pathname);
          return (
            <Link
              key={item.href}
              href={item.href}
              aria-current={isActive ? 'page' : undefined}
              className={cn(
                'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
                isActive
                  ? 'bg-linear-to-r from-primary/15 to-teal-400/10 text-primary'
                  : 'text-muted-foreground hover:bg-linear-to-r hover:from-primary/12 hover:to-cyan-400/12 hover:text-foreground',
              )}>
              <item.icon className='h-4 w-4 shrink-0' />
              {item.label}
            </Link>
          );
        })}
      </CollapsibleContent>
    </Collapsible>
  );
}
