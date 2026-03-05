# Zustand Migration Examples

Real-world examples of migrating from useState to Zustand.

## Example 1: Simple Stats Display

### ❌ Before (with useState)

```tsx
'use client';

import { useState, useEffect } from 'react';
import { clientApi } from '@/lib/api-client';
import { Loader2 } from 'lucide-react';

export function UserStatsCard() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    async function loadStats() {
      try {
        setLoading(true);
        const data = await clientApi.getStats();
        setStats(data);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    }

    loadStats();
  }, []);

  if (loading) {
    return <Loader2 className="animate-spin" />;
  }

  if (error) {
    return <div className="text-destructive">{error}</div>;
  }

  return (
    <div className="grid gap-4 sm:grid-cols-2 md:grid-cols-3">
      <div>
        <div className="text-2xl sm:text-3xl font-bold">{stats?.totalUsers}</div>
        <div className="text-xs sm:text-sm text-muted-foreground">Total Users</div>
      </div>
      <div>
        <div className="text-2xl sm:text-3xl font-bold">{stats?.activeUsers}</div>
        <div className="text-xs sm:text-sm text-muted-foreground">Active Users</div>
      </div>
      <div>
        <div className="text-2xl sm:text-3xl font-bold">{stats?.totalProjects}</div>
        <div className="text-xs sm:text-sm text-muted-foreground">Projects</div>
      </div>
    </div>
  );
}
```

### ✅ After (with Zustand)

```tsx
'use client';

import { useStats } from '@/lib/hooks';
import { Loader2 } from 'lucide-react';

export function UserStatsCard() {
  const { stats, isLoading, error } = useStats();

  if (isLoading) {
    return <Loader2 className="animate-spin" />;
  }

  if (error) {
    return <div className="text-destructive">{error}</div>;
  }

  return (
    <div className="grid gap-4 sm:grid-cols-2 md:grid-cols-3">
      <div>
        <div className="text-2xl sm:text-3xl font-bold">{stats?.totalUsers}</div>
        <div className="text-xs sm:text-sm text-muted-foreground">Total Users</div>
      </div>
      <div>
        <div className="text-2xl sm:text-3xl font-bold">{stats?.activeUsers}</div>
        <div className="text-xs sm:text-sm text-muted-foreground">Active Users</div>
      </div>
      <div>
        <div className="text-2xl sm:text-3xl font-bold">{stats?.totalProjects}</div>
        <div className="text-xs sm:text-sm text-muted-foreground">Projects</div>
      </div>
    </div>
  );
}
```

**Benefits:**
- ✅ 15 fewer lines of code
- ✅ No useEffect boilerplate
- ✅ Stats automatically cached and shared
- ✅ If another component already loaded stats, this loads instantly

---

## Example 2: User Profile with Role Check

### ❌ Before (with prop drilling)

```tsx
// page.tsx
export default async function DashboardPage() {
  const me = await api.getMe();
  return <DashboardClient user={me} />;
}

// DashboardClient.tsx
export function DashboardClient({ user }) {
  return (
    <div>
      <Header user={user} />
      <Sidebar user={user} />
      <MainContent user={user} />
    </div>
  );
}

// Header.tsx
export function Header({ user }) {
  return (
    <header>
      <UserMenu user={user} />
    </header>
  );
}

// UserMenu.tsx
export function UserMenu({ user }) {
  return (
    <div>
      <img src={user.avatarUrl} />
      <span>{user.displayName}</span>
      {user.roles.includes('admin') && <AdminBadge />}
    </div>
  );
}
```

### ✅ After (with Zustand)

```tsx
// page.tsx
export default function DashboardPage() {
  return <DashboardClient />;
}

// DashboardClient.tsx
'use client';
import { useAuthInit } from '@/lib/hooks';

export function DashboardClient() {
  useAuthInit(); // Initialize auth once

  return (
    <div>
      <Header />
      <Sidebar />
      <MainContent />
    </div>
  );
}

// Header.tsx
'use client';

export function Header() {
  return (
    <header>
      <UserMenu />
    </header>
  );
}

// UserMenu.tsx
'use client';
import { useAuthStore } from '@/lib/stores';

export function UserMenu() {
  const { user, hasRole } = useAuthStore();

  return (
    <div>
      <img src={user?.avatarUrl} />
      <span>{user?.displayName}</span>
      {hasRole('admin') && <AdminBadge />}
    </div>
  );
}
```

**Benefits:**
- ✅ No prop drilling through 4 components
- ✅ Cleaner component signatures
- ✅ User data available anywhere
- ✅ Easy to add auth checks anywhere

---

## Example 3: Multiple Components Using Same Data

### ❌ Before (duplicate loading)

```tsx
// StatsCard.tsx
function StatsCard() {
  const [stats, setStats] = useState(null);

  useEffect(() => {
    async function load() {
      const data = await clientApi.getStats();
      setStats(data);
    }
    load();
  }, []);

  return <div>{stats?.totalUsers} users</div>;
}

// ProjectsCard.tsx
function ProjectsCard() {
  const [stats, setStats] = useState(null);

  useEffect(() => {
    async function load() {
      const data = await clientApi.getStats(); // Duplicate API call!
      setStats(data);
    }
    load();
  }, []);

  return <div>{stats?.totalProjects} projects</div>;
}
```

**Problem:** 2 API calls for the same data!

### ✅ After (shared state)

```tsx
// StatsCard.tsx
function StatsCard() {
  const { stats } = useStats();
  return <div>{stats?.totalUsers} users</div>;
}

// ProjectsCard.tsx
function ProjectsCard() {
  const { stats } = useStats(); // Same data, no extra API call
  return <div>{stats?.totalProjects} projects</div>;
}
```

**Benefits:**
- ✅ Only 1 API call total
- ✅ Instant load for second component
- ✅ Data stays in sync across components

---

## Example 4: Refresh Button

### ❌ Before (manual refresh logic)

```tsx
function Dashboard() {
  const [stats, setStats] = useState(null);
  const [refreshing, setRefreshing] = useState(false);

  async function loadStats() {
    const data = await clientApi.getStats();
    setStats(data);
  }

  async function handleRefresh() {
    setRefreshing(true);
    await loadStats();
    setRefreshing(false);
  }

  useEffect(() => {
    loadStats();
  }, []);

  return (
    <div>
      <button onClick={handleRefresh} disabled={refreshing}>
        {refreshing ? 'Refreshing...' : 'Refresh'}
      </button>
      <div>{stats?.totalUsers}</div>
    </div>
  );
}
```

### ✅ After (built-in refresh)

```tsx
function Dashboard() {
  const { stats, isLoading, refresh } = useStats();

  return (
    <div>
      <button onClick={refresh} disabled={isLoading}>
        {isLoading ? 'Refreshing...' : 'Refresh'}
      </button>
      <div>{stats?.totalUsers}</div>
    </div>
  );
}
```

**Benefits:**
- ✅ Built-in refresh function
- ✅ Refreshes data in ALL components using stats
- ✅ Less code to maintain

---

## Example 5: Auto-Refresh with Interval

### ❌ Before (manual interval management)

```tsx
function LiveStatsCard() {
  const [stats, setStats] = useState(null);

  async function loadStats() {
    const data = await clientApi.getStats();
    setStats(data);
  }

  useEffect(() => {
    loadStats();

    const interval = setInterval(() => {
      loadStats();
    }, 30000); // Refresh every 30s

    return () => clearInterval(interval);
  }, []);

  return <div>{stats?.totalUsers}</div>;
}
```

### ✅ After (built-in auto-refresh)

```tsx
function LiveStatsCard() {
  const { stats } = useStats({
    autoLoad: true,
    refreshInterval: 30000 // Refresh every 30s
  });

  return <div>{stats?.totalUsers}</div>;
}
```

**Benefits:**
- ✅ Built-in interval management
- ✅ Automatic cleanup
- ✅ Configurable per component

---

## Example 6: Conditional Rendering Based on Role

### ❌ Before (passing roles as props)

```tsx
function Sidebar({ userRoles }) {
  return (
    <nav>
      <Link href="/dashboard">Dashboard</Link>
      <Link href="/users">Users</Link>
      {userRoles.includes('admin') && (
        <Link href="/admin">Admin Panel</Link>
      )}
      {userRoles.includes('owner') && (
        <Link href="/settings">Settings</Link>
      )}
    </nav>
  );
}
```

### ✅ After (using auth store)

```tsx
'use client';
import { useAuthStore } from '@/lib/stores';

function Sidebar() {
  const { hasRole } = useAuthStore();

  return (
    <nav>
      <Link href="/dashboard">Dashboard</Link>
      <Link href="/users">Users</Link>
      {hasRole('admin') && (
        <Link href="/admin">Admin Panel</Link>
      )}
      {hasRole('owner') && (
        <Link href="/settings">Settings</Link>
      )}
    </nav>
  );
}
```

**Benefits:**
- ✅ No props needed
- ✅ Clean role checks with `hasRole()`
- ✅ Works anywhere in the app

---

## Example 7: Optimized Re-renders (Selector Pattern)

### ⚠️ Non-optimized

```tsx
function UserName() {
  // Re-renders on ANY auth store change (loading, error, etc.)
  const authStore = useAuthStore();

  return <div>{authStore.user?.displayName}</div>;
}
```

### ✅ Optimized (only re-renders when user changes)

```tsx
function UserName() {
  // Only re-renders when user.displayName changes
  const displayName = useAuthStore(state => state.user?.displayName);

  return <div>{displayName}</div>;
}
```

**Benefits:**
- ✅ Minimal re-renders
- ✅ Better performance in large apps

---

## Example 8: Multiple Filters (Creating a Users Store)

### ❌ Before (lots of useState)

```tsx
function UsersPage() {
  const [users, setUsers] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(0);
  const [searchQuery, setSearchQuery] = useState('');
  const [roleFilter, setRoleFilter] = useState(null);
  const [statusFilter, setStatusFilter] = useState(null);

  useEffect(() => {
    async function load() {
      setLoading(true);
      const data = await clientApi.listUsers({
        offset: page * 20,
        limit: 20,
        q: searchQuery,
        role: roleFilter,
        status: statusFilter,
      });
      setUsers(data.data);
      setTotal(data.total);
      setLoading(false);
    }
    load();
  }, [page, searchQuery, roleFilter, statusFilter]);

  return (
    <div>
      <input
        value={searchQuery}
        onChange={e => {
          setSearchQuery(e.target.value);
          setPage(0); // Reset to page 0 on search
        }}
      />
      <select value={roleFilter} onChange={e => {
        setRoleFilter(e.target.value);
        setPage(0);
      }}>
        {/* ... */}
      </select>
      {/* More filters... */}
      <UserTable users={users} />
      <Pagination page={page} total={total} onPageChange={setPage} />
    </div>
  );
}
```

### ✅ After (with Zustand store)

```tsx
// lib/stores/users-store.ts
import { create } from "zustand";
import { devtools } from "zustand/middleware";

interface UsersState {
  users: AdminUser[];
  total: number;
  isLoading: boolean;
  page: number;
  limit: number;
  searchQuery: string;
  roleFilter: string | null;
  statusFilter: string | null;

  setUsers: (users: AdminUser[], total: number) => void;
  setLoading: (loading: boolean) => void;
  setPage: (page: number) => void;
  setSearchQuery: (query: string) => void;
  setRoleFilter: (role: string | null) => void;
  setStatusFilter: (status: string | null) => void;
  clearFilters: () => void;
}

export const useUsersStore = create<UsersState>()(
  devtools((set) => ({
    users: [],
    total: 0,
    isLoading: false,
    page: 0,
    limit: 20,
    searchQuery: "",
    roleFilter: null,
    statusFilter: null,

    setUsers: (users, total) => set({ users, total }),
    setLoading: (isLoading) => set({ isLoading }),
    setPage: (page) => set({ page }),
    setSearchQuery: (searchQuery) => set({ searchQuery, page: 0 }),
    setRoleFilter: (roleFilter) => set({ roleFilter, page: 0 }),
    setStatusFilter: (statusFilter) => set({ statusFilter, page: 0 }),
    clearFilters: () => set({
      searchQuery: "",
      roleFilter: null,
      statusFilter: null,
      page: 0
    }),
  }), { name: "users-store" })
);

// lib/hooks/use-users.ts
import { useEffect } from "react";
import { useUsersStore } from "@/lib/stores/users-store";
import { clientApi } from "@/lib/api-client";

export function useUsers() {
  const store = useUsersStore();
  const { page, limit, searchQuery, roleFilter, statusFilter, setUsers, setLoading } = store;

  useEffect(() => {
    async function load() {
      setLoading(true);
      const data = await clientApi.listUsers({
        offset: page * limit,
        limit,
        q: searchQuery || undefined,
        role: roleFilter || undefined,
        status: statusFilter || undefined,
      });
      setUsers(data.data, data.total);
      setLoading(false);
    }
    load();
  }, [page, limit, searchQuery, roleFilter, statusFilter]);

  return store;
}

// UsersPage.tsx
function UsersPage() {
  const {
    users,
    total,
    isLoading,
    page,
    searchQuery,
    roleFilter,
    setPage,
    setSearchQuery,
    setRoleFilter,
    clearFilters,
  } = useUsers();

  return (
    <div>
      <input value={searchQuery} onChange={e => setSearchQuery(e.target.value)} />
      <select value={roleFilter || ''} onChange={e => setRoleFilter(e.target.value)}>
        {/* ... */}
      </select>
      <button onClick={clearFilters}>Clear Filters</button>
      <UserTable users={users} loading={isLoading} />
      <Pagination page={page} total={total} onPageChange={setPage} />
    </div>
  );
}
```

**Benefits:**
- ✅ All filter state in one place
- ✅ Auto-resets page when filters change
- ✅ Can access filter state from anywhere
- ✅ Built-in `clearFilters()` function
- ✅ Filter state persists across navigation

---

## Summary

**When to use Zustand:**
- ✅ Data shared across multiple components
- ✅ User authentication state
- ✅ Dashboard stats/metrics
- ✅ List filters and pagination
- ✅ Data that needs caching

**When to keep useState:**
- ✅ Form input values (single component)
- ✅ Modal/dialog open state (single trigger)
- ✅ Temporary UI state
- ✅ Component-specific data

Start migrating today and enjoy cleaner, simpler components! 🚀
