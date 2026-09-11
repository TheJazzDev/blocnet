'use client';

import Image from 'next/image';
import { Menu, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
import type { AdminEnvironment } from '@/lib/environment';
import { EnvironmentBadge } from './EnvironmentBadge';

export function TopBar({
  mobileOpen,
  environment,
  onToggleMobile,
}: {
  mobileOpen: boolean;
  environment: AdminEnvironment;
  onToggleMobile: () => void;
}) {
  return (
    <div className='flex h-14 items-center gap-3 border-b border-border/70 bg-background/80 px-4 backdrop-blur-sm lg:hidden'>
      <Button variant='ghost' size='icon' onClick={onToggleMobile}>
        {mobileOpen ? <X className='h-5 w-5' /> : <Menu className='h-5 w-5' />}
      </Button>
      <div className='flex min-w-0 flex-1 items-center gap-2'>
        <div className='flex h-7 w-7 shrink-0 items-center justify-center'>
          <Image src='/logo2.png' alt='Blocnet' width={28} height={28} priority />
        </div>
        <span className='truncate text-sm font-bold'>Blocnet Console</span>
        <EnvironmentBadge environment={environment} />
      </div>
    </div>
  );
}
