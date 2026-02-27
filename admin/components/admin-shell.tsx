"use client";

import Image from "next/image";
import Link from "next/link";
import { createContext, useContext, useEffect, useMemo, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import {
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
  Award,
  Target,
} from "lucide-react";
import { supabase } from "@/lib/supabase";
import {
  getAdminEnvironmentLabel,
  resolveAdminEnvironmentFromHost,
  type AdminEnvironment,
} from "@/lib/environment";
import {
  canManageTags,
  canMutateSettings,
  canSendNotifications,
  formatRoleLabel,
  getAdminGovernanceRole,
  getRoleViewOptions,
  normalizeAdminPanelRole,
  resolveEffectiveRoles,
  ROLE_VIEW_COOKIE,
  type AdminPanelRole,
} from "@/lib/rbac";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Separator } from "@/components/ui/separator";

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
    throw new Error("useAdminSession must be used inside AdminShell");
  }
  return value;
}

function setRoleViewCookie(role: AdminPanelRole | null) {
  if (typeof document === "undefined") return;
  if (!role) {
    document.cookie = `${ROLE_VIEW_COOKIE}=; Path=/; Max-Age=0; SameSite=Lax`;
    return;
  }
  document.cookie = `${ROLE_VIEW_COOKIE}=${role}; Path=/; Max-Age=${60 * 60 * 24 * 30}; SameSite=Lax`;
}

function buildNavItems(userRoles: string[]) {
  const overviewItems = [{ href: "/dashboard", label: "Dashboard", icon: LayoutDashboard }];

  const contentItems = [
    { href: "/projects", label: "Projects", icon: FolderKanban },
    { href: "/updates", label: "Updates", icon: Newspaper },
    { href: "/comments", label: "Comments", icon: MessageSquare },
    { href: "/community", label: "Community", icon: MessagesSquare },
    { href: "/applications", label: "Applications", icon: FileCheck },
  ];

  const economyItems = [
    { href: "/wallet-users", label: "Wallet Users", icon: Wallet },
    { href: "/wallet-withdrawals", label: "Withdrawals", icon: ScrollText },
    { href: "/wallet-kyc", label: "KYC Reviews", icon: Shield },
    { href: "/wallet-settings", label: "Wallet Settings", icon: Settings },
    { href: "/tips-transactions", label: "Tip Transactions", icon: ReceiptText },
    { href: "/tip-settings", label: "Tip Settings", icon: HandCoins },
  ];

  const gamificationItems = [
    { href: "/mining", label: "Mining", icon: Zap },
    { href: "/mining/leaderboard", label: "Leaderboard", icon: CheckCircle2 },
    { href: "/badges", label: "Badges", icon: Award },
    { href: "/quests", label: "Quests", icon: Target },
    { href: "/quest-submissions", label: "Quest Reviews", icon: FileCheck },
  ];

  const accessItems = [
    { href: "/users", label: "Members", icon: Users },
    { href: "/admin-access", label: "Admin Panel Access", icon: ShieldCheck },
    { href: "/roles", label: "Role Matrix", icon: Shield },
  ];

  const engagementItems = [{ href: "/edge-engine", label: "Edge Engine", icon: Sparkles }];
  const systemItems = [{ href: "/audit-log", label: "Audit Log", icon: ScrollText }];

  if (canManageTags(userRoles)) {
    contentItems.push({ href: "/tags", label: "Tags", icon: Tags });
  }

  if (canSendNotifications(userRoles)) {
    engagementItems.push({ href: "/notifications", label: "Notifications", icon: Bell });
  }

  if (canMutateSettings(userRoles)) {
    systemItems.push({ href: "/settings", label: "Settings", icon: Settings });
  }

  return [
    { label: "Overview", items: overviewItems },
    { label: "Content", items: contentItems },
    { label: "Economy", items: economyItems },
    { label: "Gamification", items: gamificationItems },
    { label: "Access", items: accessItems },
    { label: "Engagement", items: engagementItems },
    { label: "System", items: systemItems },
  ].filter((group) => group.items.length > 0);
}

function SidebarContent({
  pathname,
  onSignOut,
  user,
  topRole,
  roleOptions,
  environmentLabel,
  hostName,
  onChangeRoleView,
  onResetRoleView,
}: {
  pathname: string;
  onSignOut: () => void;
  user: AdminSessionUser;
  topRole: AdminPanelRole | null;
  roleOptions: AdminPanelRole[];
  environmentLabel: string;
  hostName: string;
  onChangeRoleView: (role: AdminPanelRole | null) => void;
  onResetRoleView: () => void;
}) {
  const navGroups = useMemo(() => buildNavItems(user.effectiveRoles), [user.effectiveRoles]);
  const selectedRole = user.actingAsRole ?? topRole;

  return (
    <>
      <div className="flex items-center gap-2.5 px-4 py-5">
        <Image src="/logo2.png" alt="Blocnet" width={32} height={32} className="rounded-lg" />
        <div>
          <h1 className="text-sm font-bold tracking-tight">
            Blocnet Admin {environmentLabel}
          </h1>
          <p className="text-[11px] text-muted-foreground">
            {environmentLabel} Environment
          </p>
          <p className="text-[10px] font-medium text-muted-foreground/80">
            {hostName}
          </p>
        </div>
      </div>
      <Separator />
      <ScrollArea className="flex-1 px-3 py-4">
        <nav className="space-y-4">
          {navGroups.map((group) => (
            <div key={group.label} className="space-y-1">
              <p className="px-3 py-1 text-[10px] font-semibold uppercase tracking-[0.08em] text-primary/70">
                {group.label}
              </p>
              {group.items.map((item) => {
                const isActive = pathname === item.href || pathname.startsWith(`${item.href}/`);
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={cn(
                      "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors",
                      isActive
                        ? "bg-gradient-to-r from-primary/15 to-teal-400/10 text-primary"
                        : "text-muted-foreground hover:bg-accent hover:text-accent-foreground",
                    )}
                  >
                    <item.icon className="h-4 w-4 shrink-0" />
                    {item.label}
                  </Link>
                );
              })}
            </div>
          ))}
        </nav>
      </ScrollArea>
      <Separator />
      <div className="space-y-3 p-4">
        <div className="rounded-lg border bg-card p-3">
          <p className="truncate text-xs font-medium">{user.displayName ?? user.email}</p>
          <p className="truncate text-[11px] text-muted-foreground">{user.email}</p>
          {topRole && (
            <p className="mt-1.5 text-[11px] text-muted-foreground">
              Real Role: <span className="font-medium text-foreground">{formatRoleLabel(topRole)}</span>
            </p>
          )}
        </div>

        {roleOptions.length > 0 && selectedRole && (
          <div className="rounded-lg border bg-card p-3">
            <label htmlFor="role-view" className="text-[11px] font-medium text-muted-foreground">
              View As Role
            </label>
            <select
              id="role-view"
              value={selectedRole}
              onChange={(event) => onChangeRoleView(normalizeAdminPanelRole(event.target.value))}
              className="mt-1 w-full rounded-md border border-border bg-background px-2 py-1.5 text-xs"
            >
              {roleOptions.map((role) => (
                <option key={role} value={role}>
                  {formatRoleLabel(role)}
                </option>
              ))}
            </select>
            {user.actingAsRole && (
              <Button
                variant="ghost"
                size="sm"
                className="mt-2 h-7 w-full text-xs"
                onClick={onResetRoleView}
              >
                Return to Real Role
              </Button>
            )}
          </div>
        )}

        <Button
          variant="ghost"
          size="sm"
          className="w-full justify-start gap-2 text-muted-foreground hover:text-foreground"
          onClick={onSignOut}
        >
          <LogOut className="h-4 w-4" />
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
    currentUser.environment ?? "development",
  );
  const [hostName, setHostName] = useState<string>(
    (currentUser.hostName?.trim() || "unknown-host").toLowerCase(),
  );

  const realRoles = useMemo(() => Array.from(new Set(currentUser.roles)), [currentUser.roles]);
  const topRole = useMemo(() => getAdminGovernanceRole(realRoles), [realRoles]);
  const roleOptions = useMemo(() => getRoleViewOptions(realRoles), [realRoles]);
  const environmentLabel = useMemo(
    () => getAdminEnvironmentLabel(environment),
    [environment],
  );
  const watermarkEnv = useMemo(() => environmentLabel.toUpperCase(), [environmentLabel]);

  useEffect(() => {
    setActingAsRole(currentUser.actingAsRole ?? null);
  }, [currentUser.actingAsRole]);

  useEffect(() => {
    if (typeof window === "undefined") return;
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
    await fetch("/api/auth/sign-out", { method: "POST" });
    router.push("/signin");
    router.refresh();
  }

  function handleRoleViewChange(nextRole: AdminPanelRole | null) {
    const nextActing =
      nextRole && topRole && nextRole !== topRole && roleOptions.includes(nextRole) ? nextRole : null;
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
      <div className="relative flex h-screen overflow-hidden">
        <div
          aria-hidden="true"
          className="pointer-events-none fixed inset-0 z-0 overflow-hidden"
        >
          <div className="absolute left-1/2 top-1/2 w-[220vmax] -translate-x-1/2 -translate-y-1/2 -rotate-[14deg]">
            <p
              className="select-none whitespace-nowrap text-center text-[clamp(2.8rem,8vw,8rem)] font-black uppercase tracking-[0.14em] text-primary/15"
            >
              {watermarkEnv} · {watermarkEnv} · {watermarkEnv}
            </p>
            <p className="mt-2 select-none whitespace-nowrap text-center text-[clamp(0.7rem,1.4vw,1.1rem)] font-semibold tracking-[0.12em] text-primary/35">
              {hostName} · {hostName} · {hostName}
            </p>
          </div>
        </div>

        <aside className="relative z-10 hidden w-[260px] shrink-0 flex-col border-r bg-sidebar lg:flex">
          <SidebarContent
            pathname={pathname}
            onSignOut={handleSignOut}
            user={sessionValue}
            topRole={topRole}
            roleOptions={roleOptions}
            environmentLabel={environmentLabel}
            hostName={hostName}
            onChangeRoleView={handleRoleViewChange}
            onResetRoleView={resetRoleView}
          />
        </aside>

        {mobileOpen && (
          <div className="fixed inset-0 z-40 bg-black/60 lg:hidden" onClick={() => setMobileOpen(false)} />
        )}

        <aside
          className={cn(
            "fixed inset-y-0 left-0 z-50 flex w-[260px] flex-col border-r bg-sidebar transition-transform duration-200 lg:hidden",
            mobileOpen ? "translate-x-0" : "-translate-x-full",
          )}
        >
          <SidebarContent
            pathname={pathname}
            onSignOut={handleSignOut}
            user={sessionValue}
            topRole={topRole}
            roleOptions={roleOptions}
            environmentLabel={environmentLabel}
            hostName={hostName}
            onChangeRoleView={handleRoleViewChange}
            onResetRoleView={resetRoleView}
          />
        </aside>

        <div className="relative z-10 flex flex-1 flex-col overflow-hidden">
          <div className="flex h-14 items-center gap-3 border-b px-4 lg:hidden">
            <Button variant="ghost" size="icon" onClick={() => setMobileOpen(!mobileOpen)}>
              {mobileOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
            </Button>
            <div className="flex items-center gap-2">
              <Image src="/logo2.png" alt="Blocnet" width={24} height={24} className="rounded" />
              <span className="text-sm font-bold">Blocnet Admin {environmentLabel}</span>
            </div>
          </div>

          <div className="pointer-events-none fixed bottom-4 right-4 z-30">
            <div
              className={cn(
                "rounded-md border px-3 py-1.5 text-[11px] font-semibold shadow-lg backdrop-blur-xs",
                environment === "production"
                  ? "border-teal-400/30 bg-teal-500/12 text-teal-200"
                  : "border-amber-400/30 bg-amber-500/12 text-amber-200",
              )}
            >
              {environmentLabel} · {hostName}
            </div>
          </div>

          {sessionValue.actingAsRole && (
            <div className="border-b border-teal-400/20 bg-gradient-to-r from-primary/10 to-teal-400/10 px-4 py-2.5 md:px-6 lg:px-8">
              <div className="mx-auto flex w-full max-w-7xl items-center justify-between gap-3">
                <p className="flex items-center gap-2 text-sm text-foreground">
                  <CheckCircle2 className="h-4 w-4 text-teal-300" />
                  Viewing as <span className="font-semibold">{formatRoleLabel(sessionValue.actingAsRole)}</span>
                </p>
                <Button variant="outline" size="sm" onClick={resetRoleView}>
                  Return to Real Role
                </Button>
              </div>
            </div>
          )}

          <main className="flex-1 overflow-y-auto">
            <div className="mx-auto max-w-7xl p-4 md:p-6 lg:p-8">{children}</div>
          </main>
        </div>
      </div>
    </AdminSessionContext.Provider>
  );
}
