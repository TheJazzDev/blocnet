"use client";

import Image from "next/image";
import Link from "next/link";
import { createContext, useContext, useMemo, useState } from "react";
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
  const items = [
    { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
    { href: "/projects", label: "Projects", icon: FolderKanban },
    { href: "/updates", label: "Updates", icon: Newspaper },
    { href: "/comments", label: "Comments", icon: MessageSquare },
    { href: "/community", label: "Community", icon: MessagesSquare },
    { href: "/users", label: "Users & Roles", icon: Users },
    { href: "/applications", label: "Applications", icon: FileCheck },
    { href: "/audit-log", label: "Audit Log", icon: ScrollText },
  ];

  if (canManageTags(userRoles)) {
    items.push({ href: "/tags", label: "Tags", icon: Tags });
  }

  if (canSendNotifications(userRoles)) {
    items.push({ href: "/notifications", label: "Notifications", icon: Bell });
  }

  if (canMutateSettings(userRoles)) {
    items.push({ href: "/settings", label: "Settings", icon: Settings });
  }

  return items;
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
  const navItems = useMemo(() => buildNavItems(user.roles), [user.roles]);

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
        <nav className="flex flex-col gap-1">
          {navItems.map((item) => {
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
