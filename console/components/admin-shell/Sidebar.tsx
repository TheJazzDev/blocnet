'use client';

import Link from 'next/link';
import Image from 'next/image';
import { useMemo } from 'react';
import {
  Activity,
  LayoutDashboard,
  FolderKanban,
  Users,
  FileCheck,
  ScrollText,
  Settings,
  MessageSquare,
  Newspaper,
  MessagesSquare,
  Tags,
  Bell,
  Wallet,
  Shield,
  LogOut,
  CheckCircle2,
  HandCoins,
  ReceiptText,
  Sparkles,
  Brain,
  Zap,
  Award,
  Target,
  TrendingUp,
} from 'lucide-react';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Separator } from '@/components/ui/separator';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import {
  canManageTags,
  canManageSocialCredentials,
  canMutateSettings,
  canSendNotifications,
  canViewOpsEvents,
  formatRoleLabel,
  normalizeAdminPanelRole,
  type AdminPanelRole,
} from '@/lib/rbac';

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
    { href: '/levels', label: 'Levels', icon: TrendingUp },
    { href: '/badges', label: 'Badges', icon: Award },
    { href: '/quests', label: 'Quests', icon: Target },
    { href: '/quest-submissions', label: 'Quest Reviews', icon: FileCheck },
  ];

  const accessItems: NavItem[] = [
    { href: '/users', label: 'Members', icon: Users },
    { href: '/admin-access', label: 'Admin Panel Access', icon: Shield },
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

export type SidebarUser = {
  id: string;
  email: string;
  displayName: string | null;
  effectiveRoles: string[];
  actingAsRole: AdminPanelRole | null;
};

export function SidebarContent({
  pathname,
  onSignOut,
  user,
  topRole,
  roleOptions,
  onChangeRoleView,
  onResetRoleView,
}: {
  pathname: string;
  onSignOut: () => void;
  user: SidebarUser;
  topRole: AdminPanelRole | null;
  roleOptions: AdminPanelRole[];
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
              Real Role{' '}
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
