# Zustand Migration Checklist

This checklist helps you migrate your console app from useState to Zustand stores.

## ✅ Setup Complete

- [x] Installed Zustand
- [x] Created core stores (auth, stats, roles)
- [x] Created convenience hooks
- [x] Added documentation

## 🎯 High Priority Migrations

### 1. Auth Initialization
Add `useAuthInit()` to your root layout to initialize auth state globally.

**File:** `app/(protected)/layout.tsx` or similar

```tsx
'use client';
import { useAuthInit } from '@/lib/hooks';

export default function ProtectedLayout({ children }) {
  useAuthInit(); // Add this line

  return <>{children}</>;
}
```

### 2. Dashboard Stats
Replace local useState with Zustand store.

**Files to update:**
- [ ] `components/features/dashboard/_components/use-dashboard-data.ts`
  - Replace `useState<AdminStats>` with `useStats()` hook
  - Remove manual stats loading logic
  - Keep local state for page-specific data

**Example:** See `use-dashboard-data-v2.ts` for reference

### 3. Navigation/Sidebar
Use auth store for user info and role checks.

**Files to update:**
- [ ] Any component showing user avatar/name
- [ ] Any component checking roles for visibility
- [ ] Logout button/functionality

**Before:**
```tsx
const [user, setUser] = useState(null);
```

**After:**
```tsx
const { user, hasRole } = useAuthStore();
```

### 4. Stats Display Components
Any component displaying dashboard stats.

**Files to check:**
- [ ] `DashboardStatsGrid.tsx`
- [ ] `QuickStatsCard.tsx`
- [ ] `OperationalQueueCard.tsx`

**Migration:**
```tsx
// Remove props, use store directly
const { stats, isLoading } = useStats();
```

## 🔄 Medium Priority Migrations

### 5. Users Pages
Create a `useUsersStore()` for user list management.

**Files:**
- [ ] `app/(protected)/users/page.tsx`
- [ ] `app/(protected)/users/[id]/page.tsx`

**New store needed:** `lib/stores/users-store.ts`

### 6. Projects Pages
Create a `useProjectsStore()` for projects list.

**Files:**
- [ ] `app/(protected)/projects/page.tsx`

**New store needed:** `lib/stores/projects-store.ts`

### 7. Roles Page
Use `useRoles()` hook instead of local state.

**Files:**
- [ ] `app/(protected)/roles/page.tsx`

### 8. Settings Pages
Create stores for various settings.

**Files:**
- [ ] `app/(protected)/wallet-settings/page.tsx`
- [ ] `app/(protected)/tip-settings/page.tsx`
- [ ] `app/(protected)/settings/page.tsx`

**New stores needed:**
- `lib/stores/wallet-settings-store.ts`
- `lib/stores/tip-settings-store.ts`

## 📋 Low Priority Migrations

### 9. Table/List Components
Components that manage pagination, filters, search.

**Pattern to use:**
- Create a store for each list (users, projects, comments, etc.)
- Store pagination state, filters, search query
- Share state across components

### 10. Modal/Dialog State
Move modal open/close state to stores if used across components.

**Only migrate if:**
- Modal is triggered from multiple places
- Need to persist modal state across navigation

## 🎨 Store Creation Pattern

When creating new stores, follow this pattern:

```tsx
// lib/stores/users-store.ts
import { create } from "zustand";
import { devtools } from "zustand/middleware";
import type { AdminUser } from "@/lib/api";

interface UsersState {
  users: AdminUser[];
  total: number;
  isLoading: boolean;
  error: string | null;

  // Pagination
  page: number;
  limit: number;

  // Filters
  searchQuery: string;
  roleFilter: string | null;
  statusFilter: string | null;

  // Actions
  setUsers: (users: AdminUser[], total: number) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  setPage: (page: number) => void;
  setSearchQuery: (query: string) => void;
  setRoleFilter: (role: string | null) => void;
  setStatusFilter: (status: string | null) => void;
  clearFilters: () => void;
}

export const useUsersStore = create<UsersState>()(
  devtools(
    (set) => ({
      users: [],
      total: 0,
      isLoading: false,
      error: null,
      page: 0,
      limit: 20,
      searchQuery: "",
      roleFilter: null,
      statusFilter: null,

      setUsers: (users, total) => set({ users, total, error: null }),
      setLoading: (isLoading) => set({ isLoading }),
      setError: (error) => set({ error }),
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
    }),
    { name: "users-store" }
  )
);
```

## 🚫 What NOT to Migrate

Keep `useState` for:
- ✅ Form input values (unless form is used across multiple components)
- ✅ Modal/dialog open state (unless triggered from multiple places)
- ✅ Accordion/tab active state
- ✅ Temporary UI state (hover, focus, etc.)
- ✅ Component-specific data that doesn't need sharing

## 📊 Progress Tracking

### Core Features
- [ ] Auth initialization added to layout
- [ ] Dashboard using `useStats()`
- [ ] Navigation using `useAuthStore()`
- [ ] Roles page using `useRoles()`

### Data Stores Created
- [x] auth-store
- [x] stats-store
- [x] roles-store
- [ ] users-store
- [ ] projects-store
- [ ] wallet-settings-store
- [ ] tip-settings-store
- [ ] notifications-store

### Pages Migrated
- [ ] Dashboard
- [ ] Users list
- [ ] User details
- [ ] Projects
- [ ] Roles
- [ ] Settings
- [ ] Wallet settings
- [ ] Tip settings

## 🎯 Success Metrics

You'll know the migration is successful when:
- ✅ Reduced `useState` and `useEffect` in components
- ✅ No prop drilling for global data (stats, user, roles)
- ✅ Faster page loads (cached data reused)
- ✅ Easier to debug with Redux DevTools
- ✅ TypeScript errors are minimal
- ✅ Components are simpler and more focused

## 🆘 Common Issues

### Issue: "Cannot read property of null"
**Solution:** Add null checks or use optional chaining
```tsx
const { stats } = useStats();
return <div>{stats?.totalUsers ?? 0}</div>;
```

### Issue: "Store updates not reflecting in UI"
**Solution:** Make sure you're using the store hook, not just importing the store
```tsx
// ❌ Wrong
import { useStatsStore } from '@/lib/stores';
const stats = useStatsStore.getState().stats;

// ✅ Correct
import { useStatsStore } from '@/lib/stores';
const { stats } = useStatsStore();
```

### Issue: "Too many re-renders"
**Solution:** Select only the state you need
```tsx
// ❌ Re-renders on any state change
const store = useStatsStore();

// ✅ Only re-renders when stats changes
const stats = useStatsStore(state => state.stats);
```

---

Start with the high priority items and work your way down. Each migration should improve code quality and reduce complexity!
