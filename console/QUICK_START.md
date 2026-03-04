# ⚡ Zustand Quick Start

## 30-Second Start

```tsx
import { useUsers } from '@/lib/hooks';

function UsersPage() {
  const { users, isLoading } = useUsers();

  if (isLoading) return <div>Loading...</div>;

  return users.map(user => (
    <div key={user.id}>{user.email}</div>
  ));
}
```

**That's it!** No useState, no useEffect, no manual loading.

---

## All Available Hooks

```tsx
import {
  useAuthInit,       // Auth state
  useStats,          // Dashboard stats
  useRoles,          // Roles matrix
  useUsers,          // Users list
  useProjects,       // Projects list
  useComments,       // Comments list
  useUpdates,        // Updates list
  useAuditLog,       // Audit logs
  useWalletSettings, // Wallet config
  useTipSettings,    // Tip config
  useCommunity,      // Community posts/comments
} from '@/lib/hooks';
```

---

## Common Patterns

### 1. Simple List
```tsx
const { users, isLoading } = useUsers();
```

### 2. With Search
```tsx
const { users, searchQuery, setSearchQuery } = useUsers();

<input
  value={searchQuery}
  onChange={e => setSearchQuery(e.target.value)}
/>
```

### 3. With Filters
```tsx
const {
  users,
  roleFilter,
  setRoleFilter,
  clearFilters,
  hasFilters,
} = useUsers();

{hasFilters() && (
  <button onClick={clearFilters}>Clear Filters</button>
)}
```

### 4. With Pagination
```tsx
const { users, page, setPage, total, limit } = useUsers();

<button onClick={() => setPage(page - 1)}>Previous</button>
<button onClick={() => setPage(page + 1)}>Next</button>
```

### 5. Direct Store Access
```tsx
import { useAuthStore } from '@/lib/stores';

const user = useAuthStore(state => state.user);
const hasRole = useAuthStore(state => state.hasRole);

if (hasRole('admin')) {
  return <AdminPanel />;
}
```

### 6. Performance Optimization
```tsx
// Only re-renders when displayName changes
const displayName = useAuthStore(state => state.user?.displayName);
```

---

## Cheat Sheet

| Want to... | Use this... |
|-----------|-------------|
| Get current user | `useAuthStore()` |
| Check user role | `useAuthStore().hasRole('admin')` |
| Load dashboard stats | `useStats()` |
| Load users list | `useUsers()` |
| Search users | `useUsers().setSearchQuery(query)` |
| Filter by role | `useUsers().setRoleFilter(role)` |
| Clear filters | `useUsers().clearFilters()` |
| Load projects | `useProjects()` |
| Load comments | `useComments()` |
| Load audit logs | `useAuditLog()` |
| Refresh data | `useUsers().refresh()` |

---

## File Locations

- **Stores:** `lib/stores/*.ts`
- **Hooks:** `lib/hooks/*.ts`
- **Examples:** `components/features/users/_components/PageClientV2.tsx`
- **Docs:** Root directory `*.md` files

---

## Documentation Index

- **This file:** Quick start (you are here!)
- **ZUSTAND_SETUP.md:** Full setup guide
- **lib/stores/README.md:** Complete API reference
- **EXAMPLES.md:** 8 before/after examples
- **USERS_PAGE_REFACTOR.md:** Real refactoring walkthrough
- **MIGRATION_CHECKLIST.md:** Step-by-step migration
- **ALL_STORES_COMPLETE.md:** Complete store inventory
- **ZUSTAND_FINAL_SUMMARY.md:** Project summary

---

## DevTools

1. Install: [Chrome](https://chrome.google.com/webstore/detail/lmhkpmbekcpmknklioeibfkpmmfibljd) | [Firefox](https://addons.mozilla.org/firefox/addon/reduxdevtools/)
2. Open DevTools (F12)
3. Click "Redux" tab
4. See all stores in action!

---

## Need Help?

1. Check `EXAMPLES.md` for code samples
2. Read `lib/stores/README.md` for API details
3. Study `PageClientV2.tsx` for a real example
4. Follow `MIGRATION_CHECKLIST.md` step by step

---

**Ready? Pick a page and start replacing useState!** 🚀
