'use client';

import { ChevronsUpDown, Eye, LogOut, RotateCcw } from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  formatRoleLabel,
  normalizeAdminPanelRole,
  type AdminPanelRole,
} from '@/lib/rbac';

export type SidebarUser = {
  id: string;
  email: string;
  displayName: string | null;
  effectiveRoles: string[];
  actingAsRole: AdminPanelRole | null;
};

type SidebarUserMenuProps = {
  user: SidebarUser;
  topRole: AdminPanelRole | null;
  roleOptions: AdminPanelRole[];
  onChangeRoleView: (role: AdminPanelRole | null) => void;
  onResetRoleView: () => void;
  onSignOut: () => void;
};

function roleSummary(
  topRole: AdminPanelRole | null,
  actingAsRole: AdminPanelRole | null,
): string | null {
  if (!topRole) return null;
  if (actingAsRole && actingAsRole !== topRole) {
    return `${formatRoleLabel(topRole)} · viewing as ${formatRoleLabel(actingAsRole)}`;
  }
  return formatRoleLabel(topRole);
}

/**
 * One-row sidebar footer: the user card opens a compact menu holding the
 * "View As Role" switcher and "Return to Real Role"; sign out sits beside it.
 */
export function SidebarUserMenu({
  user,
  topRole,
  roleOptions,
  onChangeRoleView,
  onResetRoleView,
  onSignOut,
}: SidebarUserMenuProps) {
  const selectedRole = user.actingAsRole ?? topRole;
  const canSwitchRole = roleOptions.length > 1 && selectedRole !== null;
  const summary = roleSummary(topRole, user.actingAsRole);

  return (
    <div className='flex items-center gap-2 p-3'>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <button
            type='button'
            aria-label='Account and role view options'
            className='flex min-w-0 flex-1 items-center gap-2 rounded-lg border border-border/70 bg-card/75 px-2.5 py-2 text-left transition-colors hover:bg-card focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring'>
            <div className='min-w-0 flex-1'>
              <p className='truncate text-xs font-medium'>
                {user.displayName ?? user.email}
              </p>
              <p className='truncate text-[11px] text-muted-foreground'>
                {summary ?? user.email}
              </p>
            </div>
            <ChevronsUpDown className='h-3.5 w-3.5 shrink-0 text-muted-foreground' />
          </button>
        </DropdownMenuTrigger>
        <DropdownMenuContent side='top' align='start' className='w-60'>
          <DropdownMenuLabel className='truncate text-xs font-normal text-muted-foreground'>
            {user.email}
          </DropdownMenuLabel>
          {canSwitchRole && (
            <>
              <DropdownMenuSeparator />
              <DropdownMenuLabel className='flex items-center gap-1.5 text-[10px] font-semibold uppercase tracking-[0.08em] text-muted-foreground'>
                <Eye className='h-3 w-3' />
                View as role
              </DropdownMenuLabel>
              <DropdownMenuRadioGroup
                value={selectedRole ?? undefined}
                onValueChange={(value) =>
                  onChangeRoleView(normalizeAdminPanelRole(value))
                }>
                {roleOptions.map((role) => (
                  <DropdownMenuRadioItem key={role} value={role}>
                    {formatRoleLabel(role)}
                    {role === topRole && (
                      <span className='ml-auto text-[10px] text-muted-foreground'>
                        real
                      </span>
                    )}
                  </DropdownMenuRadioItem>
                ))}
              </DropdownMenuRadioGroup>
              {user.actingAsRole && (
                <DropdownMenuItem onSelect={onResetRoleView}>
                  <RotateCcw className='h-4 w-4' />
                  Return to Real Role
                </DropdownMenuItem>
              )}
            </>
          )}
          <DropdownMenuSeparator />
          <DropdownMenuItem onSelect={onSignOut}>
            <LogOut className='h-4 w-4' />
            Sign Out
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>

      <Button
        variant='ghost'
        size='icon'
        aria-label='Sign out'
        title='Sign out'
        className='shrink-0 text-muted-foreground hover:text-foreground'
        onClick={onSignOut}>
        <LogOut className='h-4 w-4' />
      </Button>
    </div>
  );
}
