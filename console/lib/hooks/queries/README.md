# TanStack Query Hooks

This directory contains all TanStack Query hooks for server state management.

## Structure

```
lib/hooks/queries/
├── query-keys.ts           # Centralized query key factory
├── query-options.ts        # Reusable query option presets
├── use-users-query.ts      # User queries and mutations
├── use-stats-query.ts      # Dashboard stats queries
├── use-roles-query.ts      # Roles matrix queries
└── index.ts                # Barrel export
```

## Quick Reference

### Import Query Hooks
```tsx
import { useUsersQuery, useStatsQuery, useRolesQuery } from '@/lib/hooks/queries';
```

### Import Utilities
```tsx
import { queryKeys, queryOptions } from '@/lib/hooks/queries';
```

## Usage Examples

### Basic Query
```tsx
const { data, isLoading, error } = useUsersQuery({ limit: 25 });
```

### Query with Auto-Refresh
```tsx
const { data: stats } = useStatsQuery({ refetchInterval: 30_000 });
```

### Mutation
```tsx
const updateUser = useUpdateUserMutation();

await updateUser.mutateAsync({
  userId: '123',
  data: { displayName: 'New Name' }
});
```

### Cache Invalidation
```tsx
import { useQueryClient } from '@tanstack/react-query';
import { queryKeys } from '@/lib/hooks/queries';

const queryClient = useQueryClient();

// Invalidate all user queries
queryClient.invalidateQueries({ queryKey: queryKeys.users.all });
```

## Adding New Query Hooks

### 1. Add Query Keys
```tsx
// query-keys.ts
export const queryKeys = {
  // ...
  myEntity: {
    all: ['my-entity'] as const,
    lists: () => [...queryKeys.myEntity.all, 'list'] as const,
    list: (filters: Record<string, unknown>) =>
      [...queryKeys.myEntity.lists(), filters] as const,
  },
};
```

### 2. Create Hook File
```tsx
// use-my-entity-query.ts
import { useQuery } from '@tanstack/react-query';
import { clientApi } from '@/lib/api-client';
import { queryKeys, queryOptions } from './';

export function useMyEntityQuery() {
  return useQuery({
    queryKey: queryKeys.myEntity.lists(),
    queryFn: () => clientApi.listMyEntity(),
    ...queryOptions.standard,
  });
}
```

### 3. Export from Index
```tsx
// index.ts
export * from './use-my-entity-query';
```

## Documentation

See `/console/TANSTACK_QUERY_SETUP.md` for complete documentation including:
- Migration guide
- Best practices
- Pagination examples
- Optimistic updates
- Troubleshooting
