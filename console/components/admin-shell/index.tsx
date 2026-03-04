'use client';

import { createContext, useContext, useEffect, useMemo, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import axios from 'axios';
import { CheckCircle2 } from 'lucide-react';
import { supabase } from '@/lib/supabase';
import {
  getAdminEnvironmentLabel,
  resolveAdminEnvironmentFromHost,
  type AdminEnvironment,
} from '@/lib/environment';
import {
  formatRoleLabel,
  getAdminGovernanceRole,
  getRoleViewOptions,
  resolveEffectiveRoles,
  ROLE_VIEW_COOKIE,
  type AdminPanelRole,
} from '@/lib/rbac';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { SidebarContent } from './Sidebar';
import { TopBar } from './TopBar';
import { useAuthStore } from '@/lib/stores';

export interface AdminShellUser {
  id: string;
  email: string;
  displayName: string | null;
  roles: string[];
  actingAsRole?: AdminPanelRole | null;
  environment?: AdminEnvironment;
  hostName?: string | null;
}

export interface AdminSessionUser {
  id: string;
  email: string;
  displayName: string | null;
  realRoles: string[];
  effectiveRoles: string[];
  actingAsRole: AdminPanelRole | null;
  roles: string[];
}

const AdminSessionContext = createContext<AdminSessionUser | null>(null);

export function useAdminSession(): AdminSessionUser {
  const value = useContext(AdminSessionContext);
  if (!value) {
    throw new Error('useAdminSession must be used inside AdminShell');
  }
  return value;
}

function setRoleViewCookie(role: AdminPanelRole | null) {
  if (typeof document === 'undefined') return;
  if (!role) {
    document.cookie = `${ROLE_VIEW_COOKIE}=; Path=/; Max-Age=0; SameSite=Lax`;
    return;
  }
  document.cookie = `${ROLE_VIEW_COOKIE}=${role}; Path=/; Max-Age=${60 * 60 * 24 * 30}; SameSite=Lax`;
}

export function AdminShell({
  children,
  currentUser,
}: {
  children: React.ReactNode;
  currentUser: AdminShellUser;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [actingAsRole, setActingAsRole] = useState<AdminPanelRole | null>(
    currentUser.actingAsRole ?? null,
  );
  const [environment, setEnvironment] = useState<AdminEnvironment>(
    currentUser.environment ?? 'stage',
  );

  // Sync user data to Zustand store
  const setUser = useAuthStore((state) => state.setUser);
  useEffect(() => {
    setUser({
      id: currentUser.id,
      email: currentUser.email,
      displayName: currentUser.displayName,
      avatarUrl: null, // Add avatarUrl to AdminShellUser if available
      roles: currentUser.roles,
    });
  }, [currentUser, setUser]);

  const realRoles = useMemo(
    () => Array.from(new Set(currentUser.roles)),
    [currentUser.roles],
  );
  const topRole = useMemo(() => getAdminGovernanceRole(realRoles), [realRoles]);
  const roleOptions = useMemo(() => getRoleViewOptions(realRoles), [realRoles]);
  const environmentLabel = useMemo(
    () => getAdminEnvironmentLabel(environment),
    [environment],
  );

  useEffect(() => {
    setActingAsRole(currentUser.actingAsRole ?? null);
  }, [currentUser.actingAsRole]);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    setEnvironment(resolveAdminEnvironmentFromHost(window.location.hostname));
  }, []);

  useEffect(() => {
    if (actingAsRole && !roleOptions.includes(actingAsRole)) {
      setActingAsRole(null);
      setRoleViewCookie(null);
    }
  }, [actingAsRole, roleOptions]);

  const effectiveRoles = useMemo(
    () => resolveEffectiveRoles(realRoles, actingAsRole),
    [actingAsRole, realRoles],
  );

  const sessionValue = useMemo<AdminSessionUser>(
    () => ({
      id: currentUser.id,
      email: currentUser.email,
      displayName: currentUser.displayName,
      realRoles,
      effectiveRoles,
      roles: effectiveRoles,
      actingAsRole,
    }),
    [
      actingAsRole,
      currentUser.displayName,
      currentUser.email,
      currentUser.id,
      effectiveRoles,
      realRoles,
    ],
  );

  const clearAuth = useAuthStore((state) => state.clearAuth);

  async function handleSignOut() {
    setRoleViewCookie(null);
    clearAuth(); // Clear Zustand store
    await supabase.auth.signOut();
    await axios.post('/api/auth/sign-out');
    router.push('/signin');
    router.refresh();
  }

  function handleRoleViewChange(nextRole: AdminPanelRole | null) {
    const nextActing =
      nextRole &&
      topRole &&
      nextRole !== topRole &&
      roleOptions.includes(nextRole)
        ? nextRole
        : null;
    setActingAsRole(nextActing);
    setRoleViewCookie(nextActing);
    router.refresh();
  }

  function resetRoleView() {
    setActingAsRole(null);
    setRoleViewCookie(null);
    router.refresh();
  }

  return (
    <AdminSessionContext.Provider value={sessionValue}>
      <div className='relative flex h-screen overflow-hidden bg-[radial-gradient(circle_at_10%_14%,rgba(99,102,241,0.16),transparent_34%),radial-gradient(circle_at_92%_8%,rgba(34,211,238,0.14),transparent_30%),var(--background)]'>
        <div className='pointer-events-none absolute -top-28 right-[-6rem] h-80 w-80 rounded-full bg-cyan-300/10 blur-3xl' />
        <div className='pointer-events-none absolute -bottom-36 left-[-8rem] h-96 w-96 rounded-full bg-violet-400/10 blur-3xl' />

        <aside className='relative z-10 hidden w-[260px] shrink-0 flex-col border-r border-sidebar-border/70 bg-gradient-to-b from-sidebar via-sidebar to-sidebar/92 lg:flex'>
          <SidebarContent
            pathname={pathname}
            onSignOut={handleSignOut}
            user={sessionValue}
            topRole={topRole}
            roleOptions={roleOptions}
            onChangeRoleView={handleRoleViewChange}
            onResetRoleView={resetRoleView}
          />
        </aside>

        {mobileOpen && (
          <div
            className='fixed inset-0 z-40 cursor-pointer bg-black/60 lg:hidden'
            onClick={() => setMobileOpen(false)}
          />
        )}

        <aside
          className={cn(
            'fixed inset-y-0 left-0 z-50 flex w-65 flex-col border-r border-sidebar-border/70 bg-linear-to-b from-sidebar via-sidebar to-sidebar/92 transition-transform duration-200 lg:hidden',
            mobileOpen ? 'translate-x-0' : '-translate-x-full',
          )}>
          <SidebarContent
            pathname={pathname}
            onSignOut={handleSignOut}
            user={sessionValue}
            topRole={topRole}
            roleOptions={roleOptions}
            onChangeRoleView={handleRoleViewChange}
            onResetRoleView={resetRoleView}
          />
        </aside>

        <div className='relative z-10 flex flex-1 flex-col overflow-hidden'>
          <TopBar
            mobileOpen={mobileOpen}
            onToggleMobile={() => setMobileOpen(!mobileOpen)}
          />

          <div className='pointer-events-none fixed bottom-4 right-8 z-30'>
            <div
              className={cn(
                'rounded-md border px-3 py-1.5 text-[11px] font-semibold shadow-lg backdrop-blur-xs',
                environment === 'production'
                  ? 'border-teal-400/30 bg-teal-500/12 text-teal-200'
                  : 'border-amber-400/30 bg-amber-500/12 text-amber-200',
              )}>
              {environmentLabel}
            </div>
          </div>

          {sessionValue.actingAsRole && (
            <div className='border-b border-teal-400/20 bg-gradient-to-r from-primary/10 to-teal-400/10 px-4 py-2.5 md:px-6 lg:px-8'>
              <div className='mx-auto flex w-full max-w-7xl items-center justify-between gap-3'>
                <p className='flex items-center gap-2 text-sm text-foreground'>
                  <CheckCircle2 className='h-4 w-4 text-teal-300' />
                  Viewing as{' '}
                  <span className='font-semibold'>
                    {formatRoleLabel(sessionValue.actingAsRole)}
                  </span>
                </p>
                <Button variant='outline' size='sm' onClick={resetRoleView}>
                  Return to Real Role
                </Button>
              </div>
            </div>
          )}

          <main className='flex-1 overflow-y-auto'>
            <div className='mx-auto p-4 md:p-6 lg:p-8'>{children}</div>
          </main>
        </div>
      </div>
    </AdminSessionContext.Provider>
  );
}
