# TanStack Query Setup Complete

TanStack Query has been successfully installed and configured in the console app for efficient server state management.

## What Was Added

### 1. Packages
- ✅ Installed `@tanstack/react-query@5.90.21`
- ✅ Installed `@tanstack/react-query-devtools@5.91.3`

### 2. Core Setup
- ✅ `components/shared/query-provider.tsx` - QueryClient provider wrapper
- ✅ `app/layout.tsx` - QueryProvider added to root layout
- ✅ DevTools enabled (bottom of screen, toggle with button)

### 3. Query Utilities (`lib/hooks/queries/`)
- ✅ `query-keys.ts` - Centralized query key factory (prevents typos, easier cache invalidation)
- ✅ `query-options.ts` - Common query option presets (realtime, standard, static, once, noCache)
- ✅ `index.ts` - Barrel export for all query hooks

### 4. Example Query Hooks
- ✅ `use-users-query.ts` - Users list, detail, update, delete, reactivate, hard delete
- ✅ `use-stats-query.ts` - Dashboard stats with optional auto-refresh
- ✅ `use-roles-query.ts` - Roles matrix (static caching)

### 5. Utility Hooks
- ✅ `lib/hooks/use-debounce.ts` - Debounce hook for search inputs

### 6. Example Refactored Page
- ✅ `components/features/users/_components/PageClient-v2.tsx` - Refactored users page using TanStack Query

---

## Quick Start

### Before (useState + useEffect)

```tsx
'use client';
import { useState, useEffect } from 'react';
import { clientApi } from '@/lib/api-client';

function UsersPage() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    async function load() {
      setLoading(true);
      setError(null);
      try {
        const result = await clientApi.listUsers({ limit: 25 });
        setUsers(result.data);
      } catch (e) {
        setError(e.message);
      } finally {
        setLoading(false);
      }
    }
    load();
  }, []);

  if (loading) return <LoadingSpinner />;
  if (error) return <ErrorMessage error={error} />;
  return <UsersList users={users} />;
}
```

### After (TanStack Query)

```tsx
'use client';
import { useUsersQuery } from '@/lib/hooks/queries';

function UsersPage() {
  const { data, isLoading, error } = useUsersQuery({ limit: 25 });

  if (isLoading) return <LoadingSpinner />;
  if (error) return <ErrorMessage error={error} />;
  return <UsersList users={data.data} />;
}
```

**What you get for free:**
- ✅ Automatic caching (30 seconds stale time)
- ✅ Background refetching on window focus
- ✅ Request deduplication
- ✅ Automatic error retry
- ✅ Loading states that don't flash
- ✅ DevTools for debugging

---

## Available Query Hooks

### Users
```tsx
import {
  useUsersQuery,           // List users with filters
  useUserQuery,            // Get single user
  useUpdateUserMutation,   // Update user
  useDeleteUserMutation,   // Deactivate user
  useReactivateUserMutation, // Reactivate user
  useHardDeleteUserMutation  // Permanently delete user
} from '@/lib/hooks/queries';
```

#### Example: List Users
```tsx
const { data, isLoading, error } = useUsersQuery({
  limit: 25,
  offset: 0,
  role: 'hunter',
  status: 'active',
  q: 'search term'
});

// data.data = user array
// data.total = total count
```

#### Example: Update User
```tsx
const updateUser = useUpdateUserMutation();

// In a form handler
const handleSubmit = async (values) => {
  await updateUser.mutateAsync({
    userId: '123',
    data: { displayName: 'New Name' }
  });
  // Cache is automatically updated!
};
```

### Stats
```tsx
import { useStatsQuery } from '@/lib/hooks/queries';

// Basic usage
const { data: stats } = useStatsQuery();

// With auto-refresh every 30 seconds
const { data: stats } = useStatsQuery({ refetchInterval: 30_000 });
```

### Roles
```tsx
import { useRolesQuery } from '@/lib/hooks/queries';

const { data: rolesMatrix } = useRolesQuery();
// Uses static caching (5 min stale time)
```

---

## Query Keys Reference

Centralized in `lib/hooks/queries/query-keys.ts`:

```tsx
import { queryKeys } from '@/lib/hooks/queries';

// Users
queryKeys.users.all                    // ['users']
queryKeys.users.lists()                // ['users', 'list']
queryKeys.users.list({ role: 'admin' }) // ['users', 'list', { role: 'admin' }]
queryKeys.users.detail('123')          // ['users', 'detail', '123']

// Stats
queryKeys.stats.dashboard()            // ['stats', 'dashboard']
queryKeys.stats.health()               // ['stats', 'health']

// Roles
queryKeys.roles.matrix()               // ['roles', 'matrix']
```

### Manual Cache Invalidation

```tsx
import { useQueryClient } from '@tanstack/react-query';
import { queryKeys } from '@/lib/hooks/queries';

function MyComponent() {
  const queryClient = useQueryClient();

  const handleRefresh = () => {
    // Invalidate all user queries
    queryClient.invalidateQueries({ queryKey: queryKeys.users.all });

    // Invalidate specific user
    queryClient.invalidateQueries({ queryKey: queryKeys.users.detail('123') });

    // Invalidate all user lists
    queryClient.invalidateQueries({ queryKey: queryKeys.users.lists() });
  };
}
```

---

## Query Options Presets

Defined in `lib/hooks/queries/query-options.ts`:

```tsx
import { queryOptions } from '@/lib/hooks/queries';

// Realtime data (refetch every 10s)
{ ...queryOptions.realtime }
// → staleTime: 0, refetchInterval: 10_000

// Standard caching (30s stale time)
{ ...queryOptions.standard }
// → staleTime: 30_000, refetchOnWindowFocus: true

// Static data (5 min stale time)
{ ...queryOptions.static }
// → staleTime: 5 * 60 * 1000, refetchOnWindowFocus: false

// One-time fetch (never refetch)
{ ...queryOptions.once }
// → staleTime: Infinity, refetchOnMount: false

// No caching (always fresh)
{ ...queryOptions.noCache }
// → staleTime: 0, cacheTime: 0
```

### Custom Query Example
```tsx
import { useQuery } from '@tanstack/react-query';
import { queryKeys, queryOptions } from '@/lib/hooks/queries';

function useProjectsQuery() {
  return useQuery({
    queryKey: queryKeys.projects.lists(),
    queryFn: () => clientApi.listProjects(),
    ...queryOptions.standard, // 30s caching
  });
}
```

---

## Migration Guide

### Step 1: Identify useState Patterns

Look for this pattern:
```tsx
const [data, setData] = useState(null);
const [loading, setLoading] = useState(true);
const [error, setError] = useState(null);

useEffect(() => {
  async function load() {
    setLoading(true);
    setError(null);
    try {
      const result = await clientApi.someMethod();
      setData(result);
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }
  load();
}, [dependencies]);
```

### Step 2: Create a Query Hook

```tsx
// lib/hooks/queries/use-projects-query.ts
import { useQuery } from '@tanstack/react-query';
import { clientApi } from '@/lib/api-client';
import { queryKeys, queryOptions } from './';

export function useProjectsQuery(filters?: { status?: string }) {
  return useQuery({
    queryKey: queryKeys.projects.list(filters ?? {}),
    queryFn: () => clientApi.listProjects(filters),
    ...queryOptions.standard,
  });
}
```

### Step 3: Add to Query Keys

```tsx
// lib/hooks/queries/query-keys.ts
export const queryKeys = {
  // ... existing keys
  projects: {
    all: ['projects'] as const,
    lists: () => [...queryKeys.projects.all, 'list'] as const,
    list: (filters: Record<string, unknown>) =>
      [...queryKeys.projects.lists(), filters] as const,
  },
};
```

### Step 4: Export from Index

```tsx
// lib/hooks/queries/index.ts
export * from './use-projects-query';
```

### Step 5: Use in Component

```tsx
import { useProjectsQuery } from '@/lib/hooks/queries';

function ProjectsPage() {
  const { data, isLoading, error } = useProjectsQuery({ status: 'active' });

  // Rest of component...
}
```

---

## Mutations Guide

Mutations are for write operations (POST, PATCH, DELETE).

### Basic Mutation Hook

```tsx
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { clientApi } from '@/lib/api-client';
import { queryKeys } from './query-keys';

export function useCreateProjectMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: { name: string; description: string }) =>
      clientApi.createProject(data),

    onSuccess: (newProject) => {
      // Invalidate project lists to refetch
      queryClient.invalidateQueries({ queryKey: queryKeys.projects.lists() });
    },
  });
}
```

### Using Mutations

```tsx
function CreateProjectForm() {
  const createProject = useCreateProjectMutation();

  const handleSubmit = async (values) => {
    try {
      await createProject.mutateAsync(values);
      toast.success('Project created!');
    } catch (error) {
      toast.error('Failed to create project');
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      {/* form fields */}
      <Button disabled={createProject.isPending}>
        {createProject.isPending ? 'Creating...' : 'Create'}
      </Button>
    </form>
  );
}
```

### Optimistic Updates

```tsx
export function useUpdateProjectMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }) => clientApi.updateProject(id, data),

    // Optimistic update
    onMutate: async ({ id, data }) => {
      // Cancel outgoing refetches
      await queryClient.cancelQueries({ queryKey: queryKeys.projects.detail(id) });

      // Snapshot previous value
      const previous = queryClient.getQueryData(queryKeys.projects.detail(id));

      // Optimistically update
      queryClient.setQueryData(queryKeys.projects.detail(id), (old) => ({
        ...old,
        ...data,
      }));

      return { previous };
    },

    // Rollback on error
    onError: (err, variables, context) => {
      queryClient.setQueryData(
        queryKeys.projects.detail(variables.id),
        context.previous
      );
    },

    // Always refetch after error or success
    onSettled: (data, error, variables) => {
      queryClient.invalidateQueries({
        queryKey: queryKeys.projects.detail(variables.id)
      });
    },
  });
}
```

---

## Pagination Example

See `PageClient-v2.tsx` for a full example. Key points:

1. **Debounce search input** to avoid excessive queries
2. **Reset offset to 0** when filters change
3. **Query key includes all params** for proper caching

```tsx
const [offset, setOffset] = useState(0);
const [limit, setLimit] = useState(25);
const [search, setSearch] = useState('');

const debouncedSearch = useDebounce(search, 300);

const { data, isLoading } = useUsersQuery({
  limit,
  offset,
  q: debouncedSearch || undefined,
});

const handleNextPage = () => setOffset(offset + limit);
const handlePrevPage = () => setOffset(Math.max(0, offset - limit));
```

---

## DevTools

TanStack Query DevTools are enabled automatically in development.

**To use:**
1. Look for a floating icon at the bottom of the screen
2. Click to open the DevTools panel
3. Inspect queries, mutations, cache, and timeline

**Features:**
- View all active queries and their state
- See cache contents
- Force refetch
- Clear cache
- View query timeline

---

## When to Use TanStack Query vs Zustand

### Use TanStack Query for:
- ✅ **Server state** - Data from API calls
- ✅ Lists, tables, paginated data
- ✅ Detail pages (user details, project details)
- ✅ Dashboard stats that need refreshing
- ✅ Any data that can become stale

### Use Zustand for:
- ✅ **Client state** - UI state, preferences
- ✅ Auth state (current user, roles)
- ✅ Global UI state (sidebar open/closed, theme)
- ✅ Form state that needs to persist across routes
- ✅ User preferences

### Use Both Together:
```tsx
// Zustand for auth
const { user, hasRole } = useAuthStore();

// TanStack Query for data
const { data: projects } = useProjectsQuery();

// Perfect combo!
```

---

## Best Practices

### 1. Always Use Query Keys Factory
```tsx
// ❌ Bad - hardcoded strings
useQuery({ queryKey: ['users', 'list', { role: 'admin' }] })

// ✅ Good - centralized factory
useQuery({ queryKey: queryKeys.users.list({ role: 'admin' }) })
```

### 2. Use Appropriate Caching Strategies
```tsx
// Frequently changing data
{ ...queryOptions.standard } // 30s

// Rarely changing data
{ ...queryOptions.static } // 5 min

// Real-time data
{ ...queryOptions.realtime } // 10s auto-refresh
```

### 3. Invalidate Related Queries After Mutations
```tsx
onSuccess: () => {
  // Invalidate all user lists after creating a user
  queryClient.invalidateQueries({ queryKey: queryKeys.users.lists() });
}
```

### 4. Handle Loading and Error States
```tsx
const { data, isLoading, error } = useUsersQuery();

if (isLoading) return <LoadingSpinner />;
if (error) return <ErrorMessage error={error} />;
return <UsersList users={data.data} />;
```

### 5. Use Enabled Option for Conditional Queries
```tsx
// Only fetch user if ID is available
const { data: user } = useUserQuery(userId, {
  enabled: !!userId
});
```

---

## Next Steps

### High Priority Pages to Migrate

1. **Dashboard** (`app/(protected)/dashboard/page.tsx`)
   - Stats query is already available
   - Replace useState with `useStatsQuery({ refetchInterval: 30_000 })`

2. **Projects** (`app/(protected)/projects/page.tsx`)
   - Create `use-projects-query.ts`
   - Similar pattern to users page

3. **Updates** (`app/(protected)/updates/page.tsx`)
   - Create `use-updates-query.ts`

4. **User Detail** (`app/(protected)/users/[id]/page.tsx`)
   - Use `useUserQuery(userId)`
   - Create mutation hooks for role changes, badge assignments, etc.

### Creating New Query Hooks

For each new entity (projects, updates, comments, etc.):

1. Add query keys to `query-keys.ts`
2. Create `use-{entity}-query.ts` with hooks
3. Export from `lib/hooks/queries/index.ts`
4. Use in components

### Testing the Refactored Page

To test the refactored users page:

```tsx
// In app/(protected)/users/page.tsx
import PageClient from '@/components/features/users/_components/PageClient-v2';

export default function Page() {
  return <PageClient />;
}
```

---

## Troubleshooting

### Query Not Refetching
- Check `staleTime` - data might still be fresh
- Check `enabled` option - query might be disabled
- Use DevTools to inspect query state

### Too Many Requests
- Increase `staleTime`
- Disable `refetchOnWindowFocus` if not needed
- Use debounce for search inputs

### Cache Not Updating After Mutation
- Ensure you're invalidating correct queries
- Use `queryClient.invalidateQueries()` with proper key
- Check DevTools to verify invalidation

### TypeScript Errors
- Ensure API types are exported from `@/lib/api-client`
- Query functions should match API return types
- Use `type` imports for better tree-shaking

---

## Resources

- [TanStack Query Docs](https://tanstack.com/query/latest)
- [Query Keys Best Practices](https://tkdodo.eu/blog/effective-react-query-keys)
- [Mutations Guide](https://tanstack.com/query/latest/docs/react/guides/mutations)
- [Optimistic Updates](https://tanstack.com/query/latest/docs/react/guides/optimistic-updates)

---

**TanStack Query is now ready to use!** Start migrating pages from useState to query hooks for better performance and developer experience.
