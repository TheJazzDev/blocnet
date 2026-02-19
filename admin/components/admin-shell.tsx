"use client";

import Image from "next/image";
import Link from "next/link";
import { createContext, useContext, useEffect, useMemo, useRef, useState } from "react";
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
} from "lucide-react";
import { supabase } from "@/lib/supabase";
import { canManageTags, canMutateSettings, canSendNotifications } from "@/lib/rbac";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Separator } from "@/components/ui/separator";

export interface AdminShellUser {
  id: string;
  email: string;
  displayName: string | null;
  roles: string[];
}

const AdminSessionContext = createContext<AdminShellUser | null>(null);

export function useAdminSession(): AdminShellUser {
  const value = useContext(AdminSessionContext);
  if (!value) {
    throw new Error("useAdminSession must be used inside AdminShell");
  }
  return value;
}

function buildNavItems(userRoles: string[]) {
  const overviewItems = [
    { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  ];

  const contentItems = [
    { href: "/projects", label: "Projects", icon: FolderKanban },
    { href: "/updates", label: "Updates", icon: Newspaper },
    { href: "/comments", label: "Comments", icon: MessageSquare },
    { href: "/community", label: "Community", icon: MessagesSquare },
  ];

  const walletItems = [
    { href: "/wallet-users", label: "Wallet Users", icon: Wallet },
    { href: "/wallet-withdrawals", label: "Withdrawals", icon: ScrollText },
    { href: "/wallet-kyc", label: "KYC Reviews", icon: Shield },
    { href: "/wallet-settings", label: "Wallet Settings", icon: Settings },
  ];

  const accessItems = [
    { href: "/users", label: "Users & Roles", icon: Users },
    { href: "/applications", label: "Applications", icon: FileCheck },
  ];

  const systemItems = [
    { href: "/audit-log", label: "Audit Log", icon: ScrollText },
  ];

  if (canManageTags(userRoles)) {
    contentItems.push({ href: "/tags", label: "Tags", icon: Tags });
  }

  if (canSendNotifications(userRoles)) {
    systemItems.push({ href: "/notifications", label: "Notifications", icon: Bell });
  }

  if (canMutateSettings(userRoles)) {
    systemItems.push({ href: "/settings", label: "Settings", icon: Settings });
  }

  return [
    { label: "Overview", items: overviewItems },
    { label: "Content", items: contentItems },
    { label: "Wallet", items: walletItems },
    { label: "Access", items: accessItems },
    { label: "System", items: systemItems },
  ].filter((group) => group.items.length > 0);
}

function SidebarContent({
  pathname,
  onSignOut,
  user,
}: {
  pathname: string;
  onSignOut: () => void;
  user: AdminShellUser;
}) {
  const navGroups = useMemo(() => buildNavItems(user.roles), [user.roles]);

  return (
    <>
      <div className="flex items-center gap-2.5 px-4 py-5">
        <Image src="/logo2.png" alt="Blocnet" width={32} height={32} className="rounded-lg" />
        <div>
          <h1 className="text-sm font-bold tracking-tight">Blocnet</h1>
          <p className="text-[11px] text-muted-foreground">Admin Panel</p>
        </div>
      </div>
      <Separator />
      <ScrollArea className="flex-1 px-3 py-4">
        <nav className="space-y-4">
          {navGroups.map((group) => (
            <div key={group.label} className="space-y-1">
              <p className="px-3 py-1 text-[10px] font-semibold uppercase tracking-[0.08em] text-muted-foreground/70">
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
                        ? "bg-primary/10 text-primary"
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
          <p className="truncate text-xs font-medium">
            {user.displayName ?? user.email}
          </p>
          <p className="truncate text-[11px] text-muted-foreground">{user.email}</p>
        </div>
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

// Refresh the httpOnly access-token cookie before it expires.
// Supabase access tokens last 1 hour; we refresh every 50 minutes.
const REFRESH_INTERVAL_MS = 50 * 60 * 1000;

async function refreshSession(): Promise<boolean> {
  try {
    const res = await fetch("/api/auth/refresh-token", { method: "POST" });
    return res.ok;
  } catch {
    return false;
  }
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
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Silently refresh the access-token cookie on mount and every 50 minutes
  useEffect(() => {
    refreshSession();

    intervalRef.current = setInterval(async () => {
      const ok = await refreshSession();
      if (!ok) {
        // Refresh token expired — force sign-in
        router.push("/signin?next=" + encodeURIComponent(pathname));
      }
    }, REFRESH_INTERVAL_MS);

    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  async function handleSignOut() {
    await supabase.auth.signOut();
    await fetch("/api/auth/sign-out", { method: "POST" });
    router.push("/signin");
    router.refresh();
  }

  return (
    <AdminSessionContext.Provider value={currentUser}>
      <div className="flex h-screen overflow-hidden">
        <aside className="hidden w-[260px] shrink-0 flex-col border-r bg-sidebar lg:flex">
          <SidebarContent pathname={pathname} onSignOut={handleSignOut} user={currentUser} />
        </aside>

        {mobileOpen && (
          <div
            className="fixed inset-0 z-40 bg-black/60 lg:hidden"
            onClick={() => setMobileOpen(false)}
          />
        )}

        <aside
          className={cn(
            "fixed inset-y-0 left-0 z-50 flex w-[260px] flex-col border-r bg-sidebar transition-transform duration-200 lg:hidden",
            mobileOpen ? "translate-x-0" : "-translate-x-full",
          )}
        >
          <SidebarContent pathname={pathname} onSignOut={handleSignOut} user={currentUser} />
        </aside>

        <div className="flex flex-1 flex-col overflow-hidden">
          <div className="flex h-14 items-center gap-3 border-b px-4 lg:hidden">
            <Button variant="ghost" size="icon" onClick={() => setMobileOpen(!mobileOpen)}>
              {mobileOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
            </Button>
            <div className="flex items-center gap-2">
              <Image src="/logo2.png" alt="Blocnet" width={24} height={24} className="rounded" />
              <span className="text-sm font-bold">Blocnet Admin</span>
            </div>
          </div>

          <main className="flex-1 overflow-y-auto">
            <div className="mx-auto max-w-7xl p-4 md:p-6 lg:p-8">{children}</div>
          </main>
        </div>
      </div>
    </AdminSessionContext.Provider>
  );
}
