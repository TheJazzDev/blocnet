# Migration Guide - Remaining Pages

## ✅ Status: Query Hooks Created

All query hooks for the remaining pages have been created. You can now migrate the following pages using the established pattern.

---

## 📦 Available Query Hooks

### Community
- `useCommunityPostsQuery(params)` - List community posts with filters
- `useCommunityCommentsQuery(params)` - List community comments
- `useModerateCommunityPostMutation()` - Moderate community post
- `useModerateCommunityCommentMutation()` - Moderate community comment

### Governance/Applications
- `useAdminApplicationsQuery()` - List admin role applications
- `useReviewAdminApplicationMutation()` - Approve/reject applications
- `useProjectProposalsQuery()` - List project proposals
- `useReviewProjectProposalMutation()` - Approve/reject proposals
- `useAuditLogQuery(params)` - List audit log with pagination
- `useOpsEventsQuery(params)` - List ops events with filters

### Tags
- `usePrimaryTagsQuery()` - List primary tags
- `useSecondaryTagsQuery()` - List secondary tags
- `useCreatePrimaryTagMutation()` - Create primary tag
- `useCreateSecondaryTagMutation()` - Create secondary tag
- `useUpdatePrimaryTagMutation()` - Update primary tag
- `useUpdateSecondaryTagMutation()` - Update secondary tag

---

## 🎯 Pages Requiring Migration (30+)

### High Priority
1. **Community** (`/community`) - Uses `useCommunityPostsQuery`
2. **Applications** (`/applications`) - Uses `useAdminApplicationsQuery`
3. **Tags** (`/tags`) - Uses `usePrimaryTagsQuery`, `useSecondaryTagsQuery`
4. **Audit Log** (`/audit-log`) - Uses `useAuditLogQuery`
5. **Ops Events** (`/ops-events`) - Uses `useOpsEventsQuery`

### Medium Priority
6. **User Detail** (`/users/[id]`) - Uses `useUserQuery(userId)`
7. **Roles** (`/roles`) - Uses `useRolesQuery`
8. **Settings** (`/settings`)
9. **Social Credentials** (`/social-credentials`)
10. **Admin Access** (`/admin-access`)

### Lower Priority (Wallet, Mining, Notifications, etc.)
11-35. Remaining pages can use existing patterns

---

## 🔧 Migration Pattern

For **EVERY** remaining page, follow this exact pattern:

### Step 1: Find the Page Component

Example: `components/features/community/_components/PageClient.tsx`

### Step 2: Identify useState + useEffect Pattern

**Before:**
```tsx
const [data, setData] = useState([]);
const [loading, setLoading] = useState(true);
const [error, setError] = useState(null);

useEffect(() => {
  async function load() {
    setLoading(true);
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

### Step 3: Replace with Query Hook

**After:**
```tsx
import { useSomeQuery } from '@/lib/hooks/queries';
import { useDebounce } from '@/lib/hooks';

// If there's search:
const [searchInput, setSearchInput] = useState('');
const q = useDebounce(searchInput.trim(), 300);

// Replace all useState + useEffect with single hook:
const { data, isLoading, error } = useSomeQuery({
  q: q || undefined,
  limit,
  offset
});
```

### Step 4: Update Loading/Error References

Replace all:
- `loading` → `isLoading`
- `error` → `error` (check if string or Error object)

### Step 5: Handle Mutations (if applicable)

**Before:**
```tsx
async function handleAction() {
  const previous = data;
  setData(optimisticUpdate);
  try {
    await clientApi.mutate();
    await load(); // Refetch
  } catch (e) {
    setData(previous); // Rollback
    throw e;
  }
}
```

**After:**
```tsx
import { useSomeMutation } from '@/lib/hooks/queries';

const mutation = useSomeMutation();

async function handleAction() {
  await mutation.mutateAsync({ id, data });
  // Cache automatically invalidated!
}
```

---

## 📋 Example Migrations

### Example 1: Community Page

**File:** `components/features/community/_components/PageClient.tsx`

**Before (lines 1-80):**
```tsx
const [posts, setPosts] = useState([]);
const [loading, setLoading] = useState(true);
const [error, setError] = useState(null);
const [searchInput, setSearchInput] = useState('');
const [q, setQ] = useState('');
const [topic, setTopic] = useState('all');
const [limit, setLimit] = useState(25);
const [offset, setOffset] = useState(0);

useEffect(() => {
  const timer = setTimeout(() => {
    setQ(searchInput.trim());
    setOffset(0);
  }, 300);
  return () => clearTimeout(timer);
}, [searchInput]);

useEffect(() => {
  async function load() {
    setLoading(true);
    try {
      const result = await clientApi.listAdminCommunityPosts({
        q, topic: topic === 'all' ? undefined : topic, limit, offset
      });
      setPosts(result);
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }
  load();
}, [q, topic, limit, offset]);
```

**After (lines 1-20):**
```tsx
import { useCommunityPostsQuery } from '@/lib/hooks/queries';
import { useDebounce } from '@/lib/hooks';

const [searchInput, setSearchInput] = useState('');
const [topic, setTopic] = useState('all');
const [limit, setLimit] = useState(25);
const [offset, setOffset] = useState(0);

const q = useDebounce(searchInput.trim(), 300);

const { data: posts = [], isLoading, error } = useCommunityPostsQuery({
  q: q || undefined,
  topic: topic === 'all' ? undefined : topic,
  limit,
  offset,
});
```

**Result:** 60+ lines → 15 lines (75% reduction)

### Example 2: Tags Page

**File:** `components/features/tags/_components/PageClient.tsx`

**Before:**
```tsx
const [primaryTags, setPrimaryTags] = useState([]);
const [secondaryTags, setSecondaryTags] = useState([]);
const [loading, setLoading] = useState(true);

useEffect(() => {
  async function load() {
    setLoading(true);
    try {
      const [primary, secondary] = await Promise.all([
        clientApi.listPrimaryTags(),
        clientApi.listSecondaryTags(),
      ]);
      setPrimaryTags(primary);
      setSecondaryTags(secondary);
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }
  load();
}, []);
```

**After:**
```tsx
import { usePrimaryTagsQuery, useSecondaryTagsQuery } from '@/lib/hooks/queries';

const { data: primaryTags = [], isLoading: primaryLoading } = usePrimaryTagsQuery();
const { data: secondaryTags = [], isLoading: secondaryLoading } = useSecondaryTagsQuery();

const isLoading = primaryLoading || secondaryLoading;
```

**Result:** 25+ lines → 5 lines (80% reduction)

### Example 3: Audit Log Page

**File:** `components/features/audit-log/_components/PageClient.tsx`

**Before:**
```tsx
const [logs, setLogs] = useState([]);
const [loading, setLoading] = useState(true);
const [limit, setLimit] = useState(100);
const [offset, setOffset] = useState(0);

useEffect(() => {
  async function load() {
    setLoading(true);
    try {
      const result = await clientApi.listAuditLog(limit, offset);
      setLogs(result);
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }
  load();
}, [limit, offset]);
```

**After:**
```tsx
import { useAuditLogQuery } from '@/lib/hooks/queries';

const [limit, setLimit] = useState(100);
const [offset, setOffset] = useState(0);

const { data: logs = [], isLoading } = useAuditLogQuery({ limit, offset });
```

**Result:** 20+ lines → 5 lines (75% reduction)

---

## ⚡ Quick Migration Checklist

For each page, follow this checklist:

- [ ] Import query hook from `@/lib/hooks/queries`
- [ ] Import `useDebounce` from `@/lib/hooks` (if search exists)
- [ ] Remove all `useState` for data, loading, error
- [ ] Remove all `useEffect` for data fetching
- [ ] Replace with single `useQuery` hook call
- [ ] Add debounce for search inputs
- [ ] Update `loading` → `isLoading`
- [ ] Update mutations to use mutation hooks
- [ ] Test the page

**Estimated time per page:** 5-10 minutes
**Total estimated time:** 3-5 hours for all 30+ pages

---

## 🚀 Pro Tips

1. **Keep pagination state** - useState for limit/offset is fine
2. **Keep UI state** - Modals, selected items, etc. still use useState
3. **Debounce all searches** - Use `useDebounce` hook
4. **Reset offset on filter change** - Set offset to 0 when filters change
5. **Use mutation hooks** - Replace manual refetch with mutations

---

## ✅ Benefits You'll Get

For **EVERY** migrated page:

- ✅ 50-80% less code
- ✅ Automatic caching
- ✅ Background refetching
- ✅ Better error handling
- ✅ No loading flashes
- ✅ DevTools debugging
- ✅ Request deduplication

---

## 📊 Expected Impact

After migrating all remaining pages:

- **~500+ lines** of boilerplate eliminated
- **100% consistency** across all pages
- **Zero** manual loading states
- **Zero** manual error handling
- **Zero** manual cache management

---

## 🎯 Start Here

Recommended order:

1. **Community** - Simple list page, good practice
2. **Applications** - Similar to projects page
3. **Tags** - Multiple queries in one page
4. **Audit Log** - Simplest page
5. **Ops Events** - Complex filters
6. Continue with remaining pages...

**Each page follows the EXACT same pattern. Once you do 2-3, the rest will be trivial.**

---

**All query hooks are ready. Start migrating!**
