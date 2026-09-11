'use client';

import Image from 'next/image';
import { useMemo } from 'react';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Separator } from '@/components/ui/separator';
import type { AdminEnvironment } from '@/lib/environment';
import type { AdminPanelRole } from '@/lib/rbac';
import { EnvironmentBadge } from './EnvironmentBadge';
import { SidebarNavGroup } from './SidebarNavGroup';
import { SidebarUserMenu, type SidebarUser } from './SidebarUserMenu';
import { buildNavItems } from './sidebar-nav-items';
import { useSidebarGroups } from './use-sidebar-groups';

export type { SidebarUser } from './SidebarUserMenu';

export function SidebarContent({
  pathname,
  onSignOut,
  user,
  topRole,
  roleOptions,
  environment,
  onChangeRoleView,
  onResetRoleView,
}: {
  pathname: string;
  onSignOut: () => void;
  user: SidebarUser;
  topRole: AdminPanelRole | null;
  roleOptions: AdminPanelRole[];
  environment: AdminEnvironment;
  onChangeRoleView: (role: AdminPanelRole | null) => void;
  onResetRoleView: () => void;
}) {
  const navGroups = useMemo(
    () => buildNavItems(user.effectiveRoles),
    [user.effectiveRoles],
  );
  const groupState = useSidebarGroups(navGroups, pathname);

  return (
    <>
      <div className='flex items-center gap-2.5 px-4 py-5'>
        <div className='flex h-8 w-8 shrink-0 items-center justify-center'>
          <Image
            src='/logo2.png'
            alt='Blocnet'
            width={32}
            height={32}
            priority
          />
        </div>
        <div className='flex min-w-0 flex-1 items-center justify-between gap-2'>
          <h1 className='truncate text-sm font-bold tracking-tight'>
            Blocnet Console
          </h1>
          <EnvironmentBadge environment={environment} />
        </div>
      </div>
      <Separator />
      <ScrollArea className='min-h-0 flex-1 px-3 py-3'>
        <nav aria-label='Console navigation' className='space-y-2'>
          {navGroups.map((group) => (
            <SidebarNavGroup
              key={group.label}
              group={group}
              pathname={pathname}
              open={groupState.isOpen(group.label)}
              onOpenChange={(open) => groupState.setOpen(group.label, open)}
            />
          ))}
        </nav>
      </ScrollArea>
      <Separator />
      <SidebarUserMenu
        user={user}
        topRole={topRole}
        roleOptions={roleOptions}
        onChangeRoleView={onChangeRoleView}
        onResetRoleView={onResetRoleView}
        onSignOut={onSignOut}
      />
    </>
  );
}
