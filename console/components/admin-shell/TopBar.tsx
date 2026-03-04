'use client';

import Image from 'next/image';
import { Menu, X } from 'lucide-react';
import { Button } from '@/components/ui/button';

export function TopBar({
  mobileOpen,
  onToggleMobile,
}: {
  mobileOpen: boolean;
  onToggleMobile: () => void;
}) {
  return (
    <div className='flex h-14 items-center gap-3 border-b border-border/70 bg-background/80 px-4 backdrop-blur-sm lg:hidden'>
      <Button variant='ghost' size='icon' onClick={onToggleMobile}>
        {mobileOpen ? <X className='h-5 w-5' /> : <Menu className='h-5 w-5' />}
      </Button>
      <div className='flex items-center gap-2'>
        <div className='flex h-7 w-7 items-center justify-center'>
          <Image src='/logo2.png' alt='Blocnet' width={28} height={28} priority />
        </div>
        <span className='text-sm font-bold'>Blocnet Console</span>
      </div>
    </div>
  );
}

