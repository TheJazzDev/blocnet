# Zustand State Management

This directory contains Zustand stores for global state management in the console app.

## Overview

We use [Zustand](https://github.com/pmndrs/zustand) for state management to reduce prop drilling and eliminate excessive `useState` hooks throughout the app.

## Available Stores

### 1. `useAuthStore`
Manages authentication state and user information.

**State:**
- `user: AdminMe | null` - Current authenticated user
- `isLoading: boolean` - Loading state
- `error: string | null` - Error message

**Actions:**
- `setUser(user)` - Set the current user
- `setLoading(loading)` - Set loading state
- `setError(error)` - Set error message
- `clearAuth()` - Clear all auth state
- `hasRole(role)` - Check if user has a specific role
- `hasAnyRole(roles)` - Check if user has any of the specified roles
- `hasAllRoles(roles)` - Check if user has all specified roles

**Usage:**
```tsx
import { useAuthStore } from '@/lib/stores';

function MyComponent() {
  const { user, hasRole } = useAuthStore();

  if (hasRole('admin')) {
    return <AdminPanel />;
  }

  return <div>Hello {user?.displayName}</div>;
}
```

### 2. `useStatsStore`
Manages dashboard statistics with caching.

**State:**
- `stats: AdminStats | null` - Dashboard stats
- `isLoading: boolean` - Loading state
- `error: string | null` - Error message
- `lastFetched: number | null` - Timestamp of last fetch

**Actions:**
- `setStats(stats)` - Set stats and update lastFetched
- `setLoading(loading)` - Set loading state
- `setError(error)` - Set error message
- `clearStats()` - Clear all stats state
- `shouldRefresh(maxAgeMs?)` - Check if stats should be refreshed

**Usage:**
```tsx
import { useStatsStore } from '@/lib/stores';

function StatsCard() {
  const { stats, isLoading } = useStatsStore();

  if (isLoading) return <Spinner />;

  return <div>Total Users: {stats?.totalUsers}</div>;
}
```

### 3. `useRolesStore`
Manages roles matrix data.

**State:**
- `rolesMatrix: RolesMatrixResponse | null` - Roles matrix
- `isLoading: boolean` - Loading state
- `error: string | null` - Error message

**Actions:**
- `setRolesMatrix(matrix)` - Set the roles matrix
- `setLoading(loading)` - Set loading state
- `setError(error)` - Set error message
- `clearRoles()` - Clear all roles state

## Hooks

We provide convenience hooks that combine stores with API calls:

### `useAuthInit()`
Initializes auth state by fetching current user. Call this once at the app root.

```tsx
// app/layout.tsx or app/(protected)/layout.tsx
'use client';

import { useAuthInit } from '@/lib/hooks';

export default function Layout({ children }) {
  useAuthInit();
  return <>{children}</>;
}
```

### `useStats(options?)`
Manages stats loading with auto-refresh support.

**Options:**
- `autoLoad?: boolean` - Auto-load on mount (default: true)
- `refreshInterval?: number` - Auto-refresh interval in ms

```tsx
import { useStats } from '@/lib/hooks';

function Dashboard() {
  const { stats, isLoading, refresh } = useStats({
    autoLoad: true,
    refreshInterval: 60000 // Refresh every minute
  });

  return (
    <div>
      <button onClick={refresh}>Refresh</button>
      {stats?.totalUsers}
    </div>
  );
}
```

### `useRoles(options?)`
Manages roles matrix loading.

**Options:**
- `autoLoad?: boolean` - Auto-load on mount (default: true)

```tsx
import { useRoles } from '@/lib/hooks';

function RolesPage() {
  const { rolesMatrix, isLoading } = useRoles();

  return <div>{rolesMatrix?.governanceRoles.map(...)}</div>;
}
```

## Migration Guide

### Before (with useState):
```tsx
'use client';

import { useState, useEffect } from 'react';
import { clientApi } from '@/lib/api-client';

function MyComponent() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    async function load() {
      try {
        const data = await clientApi.getStats();
        setStats(data);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    }
    load();
  }, []);

  return <div>{stats?.totalUsers}</div>;
}
```

### After (with Zustand):
```tsx
'use client';

import { useStats } from '@/lib/hooks';

function MyComponent() {
  const { stats, isLoading, error } = useStats();

  return <div>{stats?.totalUsers}</div>;
}
```

## Benefits

1. **No Prop Drilling** - Access state anywhere without passing props
2. **Automatic Caching** - Data is cached and shared across components
3. **Reduced Re-renders** - Only components using specific state slices re-render
4. **DevTools Support** - Use Redux DevTools to debug state
5. **TypeScript First** - Full type safety out of the box
6. **Tiny Bundle** - Only ~1KB (vs Redux Toolkit's ~12KB)
7. **Simple API** - No boilerplate, just `create()` and use

## DevTools

Zustand integrates with Redux DevTools. Install the browser extension:
- [Chrome](https://chrome.google.com/webstore/detail/redux-devtools/lmhkpmbekcpmknklioeibfkpmmfibljd)
- [Firefox](https://addons.mozilla.org/en-US/firefox/addon/reduxdevtools/)

## Best Practices

1. **Use stores for global state** - Auth, stats, shared data
2. **Use local state for component-specific state** - Form inputs, modals, local UI state
3. **Don't abuse stores** - Not everything needs to be global
4. **Create focused stores** - One store per domain (auth, stats, users, etc.)
5. **Use hooks for data fetching** - Combine stores with API calls in custom hooks

## Examples

See `use-dashboard-data-v2.ts` for an example of refactoring from useState to Zustand.
