'use client';

import Link from 'next/link';
import { createContext, useContext, useEffect, useMemo, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import axios from 'axios';
import {
  Activity,
  LayoutDashboard,
  FolderKanban,
  Users,
  FileCheck,
  ScrollText,
  Settings,
  Menu,
  X,
  LogOut,
  MessageSquare,
  Newspaper,
  MessagesSquare,
  Tags,
  Bell,
  Wallet,
  Shield,
  ShieldCheck,
  Zap,
  CheckCircle2,
  HandCoins,
  ReceiptText,
  Sparkles,
  Brain,
  Award,
  Target,
  Hexagon,
} from 'lucide-react';
import { supabase } from '@/lib/supabase';
import {
  getAdminEnvironmentLabel,
  resolveAdminEnvironmentFromHost,
  type AdminEnvironment,
} from '@/lib/environment';
import {
  canManageTags,
  canManageSocialCredentials,
  canMutateSettings,
  canSendNotifications,
  canViewOpsEvents,
  formatRoleLabel,
  getAdminGovernanceRole,
  getRoleViewOptions,
  normalizeAdminPanelRole,
  resolveEffectiveRoles,
  ROLE_VIEW_COOKIE,
  type AdminPanelRole,
} from '@/lib/rbac';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Separator } from '@/components/ui/separator';
import Image from 'next/image';
// import { EnvironmentWatermark } from "@/components/environment-watermark";

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

type NavItem = {
  href: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  exact?: boolean;
};

function buildNavItems(userRoles: string[]) {
  const overviewItems: NavItem[] = [
    { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  ];

  const edgeEngineItems: NavItem[] = [
    {
      href: '/edge-engine',
      label: 'Command Center',
      icon: Sparkles,
      exact: true,
    },
    {
      href: '/edge-engine/decision-engine',
      label: 'Decision Engine',
      icon: Zap,
    },
    { href: '/edge-engine/ml-analysis', label: 'ML Analysis', icon: Brain },
    { href: '/edge-engine/settings', label: 'Edge Settings', icon: Settings },
  ];

  const contentItems: NavItem[] = [
    { href: '/projects', label: 'Projects', icon: FolderKanban },
    { href: '/updates', label: 'Updates', icon: Newspaper },
    { href: '/comments', label: 'Comments', icon: MessageSquare },
    { href: '/community', label: 'Community', icon: MessagesSquare },
    { href: '/applications', label: 'Applications', icon: FileCheck },
  ];

  const economyItems: NavItem[] = [
    { href: '/wallet-users', label: 'Wallet Users', icon: Wallet },
    { href: '/wallet-withdrawals', label: 'Withdrawals', icon: ScrollText },
    { href: '/wallet-kyc', label: 'KYC Reviews', icon: Shield },
    { href: '/wallet-settings', label: 'Wallet Settings', icon: Settings },
    {
      href: '/tips-transactions',
      label: 'Tip Transactions',
      icon: ReceiptText,
    },
    { href: '/tip-settings', label: 'Tip Settings', icon: HandCoins },
  ];

  const gamificationItems: NavItem[] = [
    { href: '/mining', label: 'Mining', icon: Zap },
    { href: '/mining/leaderboard', label: 'Leaderboard', icon: CheckCircle2 },
    { href: '/badges', label: 'Badges', icon: Award },
    { href: '/quests', label: 'Quests', icon: Target },
    { href: '/quest-submissions', label: 'Quest Reviews', icon: FileCheck },
  ];

  const accessItems: NavItem[] = [
    { href: '/users', label: 'Members', icon: Users },
    { href: '/admin-access', label: 'Admin Panel Access', icon: ShieldCheck },
    { href: '/roles', label: 'Role Matrix', icon: Shield },
  ];

  const engagementItems: NavItem[] = [];
  const systemItems: NavItem[] = [
    { href: '/audit-log', label: 'Audit Log', icon: ScrollText },
  ];

  if (canViewOpsEvents(userRoles)) {
    systemItems.push({
      href: '/ops-events',
      label: 'Ops Events',
      icon: Activity,
    });
  }

  if (canManageSocialCredentials(userRoles)) {
    systemItems.push({
      href: '/social-credentials',
      label: 'Social Credentials',
      icon: Shield,
    });
  }

  if (canManageTags(userRoles)) {
    contentItems.push({ href: '/tags', label: 'Tags', icon: Tags });
  }

  if (canSendNotifications(userRoles)) {
    engagementItems.push({
      href: '/notifications',
      label: 'Notifications',
      icon: Bell,
    });
  }

  if (canMutateSettings(userRoles)) {
    systemItems.push({ href: '/settings', label: 'Settings', icon: Settings });
  }

  return [
    { label: 'Overview', items: overviewItems },
    { label: 'Edge Engine', items: edgeEngineItems },
    { label: 'Content', items: contentItems },
    { label: 'Economy', items: economyItems },
    { label: 'Gamification', items: gamificationItems },
    { label: 'Access', items: accessItems },
    { label: 'Engagement', items: engagementItems },
    { label: 'System', items: systemItems },
  ].filter((group) => group.items.length > 0);
}

function SidebarContent({
  pathname,
  onSignOut,
  user,
  topRole,
  roleOptions,
  environmentLabel,
  onChangeRoleView,
  onResetRoleView,
}: {
  pathname: string;
  onSignOut: () => void;
  user: AdminSessionUser;
  topRole: AdminPanelRole | null;
  roleOptions: AdminPanelRole[];
  environmentLabel: string;
  onChangeRoleView: (role: AdminPanelRole | null) => void;
  onResetRoleView: () => void;
}) {
  const navGroups = useMemo(
    () => buildNavItems(user.effectiveRoles),
    [user.effectiveRoles],
  );
  const selectedRole = user.actingAsRole ?? topRole;

  return (
    <>
      <div className='flex items-center gap-2.5 px-4 py-5'>
        <div className='flex h-8 w-8 items-center justify-center'>
          <Image
            src='/logo2.png'
            alt='Blocnet'
            width={32}
            height={32}
            priority
          />
        </div>
        <div>
          <h1 className='text-sm font-bold tracking-tight'>Blocnet Console</h1>
        </div>
      </div>
      <Separator />
      <ScrollArea className='flex-1 px-3 py-4'>
        <nav className='space-y-4'>
          {navGroups.map((group) => (
            <div key={group.label} className='space-y-1'>
              <p className='px-3 py-1 text-[10px] font-semibold uppercase tracking-[0.08em] text-primary/70'>
                {group.label}
              </p>
              {group.items.map((item) => {
                const isActive = item.exact
                  ? pathname === item.href
                  : pathname === item.href ||
                    pathname.startsWith(`${item.href}/`);
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={cn(
                      'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors',
                      isActive
                        ? 'bg-gradient-to-r from-primary/15 to-teal-400/10 text-primary'
                        : 'text-muted-foreground hover:bg-gradient-to-r hover:from-primary/12 hover:to-cyan-400/12 hover:text-foreground',
                    )}>
                    <item.icon className='h-4 w-4 shrink-0' />
                    {item.label}
                  </Link>
                );
              })}
            </div>
          ))}
        </nav>
      </ScrollArea>
      <Separator />
      <div className='space-y-3 p-4'>
        <div className='rounded-lg border border-border/70 bg-card/75 p-3'>
          <p className='truncate text-xs font-medium'>
            {user.displayName ?? user.email}
          </p>
          <p className='truncate text-[11px] text-muted-foreground'>
            {user.email}
          </p>
          {topRole && (
            <p className='mt-1.5 text-[11px] text-muted-foreground'>
              Real Role:{' '}
              <span className='font-medium text-foreground'>
                {formatRoleLabel(topRole)}
              </span>
            </p>
          )}
        </div>

        {roleOptions.length > 0 && selectedRole && (
          <div className='rounded-lg border border-border/70 bg-card/75 p-3'>
            <label
              htmlFor='role-view'
              className='text-[11px] font-medium text-muted-foreground'>
              View As Role
            </label>
            <select
              id='role-view'
              value={selectedRole}
              onChange={(event) =>
                onChangeRoleView(normalizeAdminPanelRole(event.target.value))
              }
              className='mt-1 w-full rounded-md border border-border/75 bg-background/75 px-2 py-1.5 text-xs'>
              {roleOptions.map((role) => (
                <option key={role} value={role}>
                  {formatRoleLabel(role)}
                </option>
              ))}
            </select>
            {user.actingAsRole && (
              <Button
                variant='ghost'
                size='sm'
                className='mt-2 h-7 w-full text-xs'
                onClick={onResetRoleView}>
                Return to Real Role
              </Button>
            )}
          </div>
        )}

        <Button
          variant='ghost'
          size='sm'
          className='w-full justify-start gap-2 text-muted-foreground hover:text-foreground'
          onClick={onSignOut}>
          <LogOut className='h-4 w-4' />
          Sign Out
        </Button>
      </div>
    </>
  );
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
  const [hostName, setHostName] = useState<string>(
    (currentUser.hostName?.trim() || 'unknown-host').toLowerCase(),
  );

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
    setHostName(window.location.host.toLowerCase());
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

  async function handleSignOut() {
    setRoleViewCookie(null);
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
            environmentLabel={environmentLabel}
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
            environmentLabel={environmentLabel}
            onChangeRoleView={handleRoleViewChange}
            onResetRoleView={resetRoleView}
          />
        </aside>

        <div className='relative z-10 flex flex-1 flex-col overflow-hidden'>
          <div className='flex h-14 items-center gap-3 border-b border-border/70 bg-background/80 px-4 backdrop-blur-sm lg:hidden'>
            <Button
              variant='ghost'
              size='icon'
              onClick={() => setMobileOpen(!mobileOpen)}>
              {mobileOpen ? (
                <X className='h-5 w-5' />
              ) : (
                <Menu className='h-5 w-5' />
              )}
            </Button>
          <div className='flex items-center gap-2'>
              <div className='flex h-7 w-7 items-center justify-center'>
                <Image
                  src='/logo2.png'
                  alt='Blocnet'
                  width={32}
                  height={32}
                  priority
                />
              </div>
              <span className='text-sm font-bold'>Blocnet Console</span>
            </div>
          </div>

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
