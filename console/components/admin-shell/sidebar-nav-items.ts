import {
  Activity,
  Award,
  Bell,
  Brain,
  CheckCircle2,
  FileCheck,
  FolderKanban,
  HandCoins,
  LayoutDashboard,
  MessageSquare,
  MessagesSquare,
  Newspaper,
  ReceiptText,
  ScrollText,
  Settings,
  Shield,
  Sparkles,
  Tags,
  Target,
  TrendingUp,
  UserPlus,
  Users,
  Wallet,
  Zap,
} from 'lucide-react';
import {
  canManageGamification,
  canManageSocialCredentials,
  canManageTags,
  canMutateSettings,
  canSendNotifications,
  canViewOpsEvents,
} from '@/lib/rbac';

export type NavItem = {
  href: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  exact?: boolean;
};

export type NavGroup = {
  label: string;
  items: NavItem[];
};

export function isNavItemActive(item: NavItem, pathname: string): boolean {
  if (item.exact) return pathname === item.href;
  return pathname === item.href || pathname.startsWith(`${item.href}/`);
}

export function findActiveGroupLabel(
  groups: NavGroup[],
  pathname: string,
): string | null {
  return (
    groups.find((group) =>
      group.items.some((item) => isNavItemActive(item, pathname)),
    )?.label ?? null
  );
}

export function buildNavItems(userRoles: string[]): NavGroup[] {
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

  // One rule: an item is listed only when its page's own gate would let the
  // role in. Each conditional below mirrors the helper that page calls.
  const gamificationItems: NavItem[] = [
    { href: '/mining', label: 'Mining', icon: Zap },
    { href: '/mining/leaderboard', label: 'Leaderboard', icon: CheckCircle2 },
    { href: '/referrals', label: 'Referrals', icon: UserPlus },
  ];

  if (canManageGamification(userRoles)) {
    gamificationItems.push(
      { href: '/levels', label: 'Levels', icon: TrendingUp },
      { href: '/badges', label: 'Badges', icon: Award },
      { href: '/quests', label: 'Quests', icon: Target },
      { href: '/quest-submissions', label: 'Quest Reviews', icon: FileCheck },
    );
  }

  const accessItems: NavItem[] = [
    { href: '/users', label: 'Members', icon: Users },
    { href: '/closed-alpha', label: 'Closed Alpha', icon: Shield },
    { href: '/console-access', label: 'Console Access', icon: Shield },
    { href: '/community-access', label: 'Community Access', icon: Shield },
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
