# Refactoring Strategy: When to Use Zustand

## Current Situation

Your console uses **3 different state management approaches**:

1. **Direct useState** (pages like BadgesPageClient) - ❌ Should migrate
2. **TanStack Query** (pages like ProjectsPageClient) - ✅ Already good!
3. **Zustand** (newly created stores) - ✅ Ready to use

## Understanding the Approaches

### 1. TanStack Query (React Query)
**Files using:** `use-projects-admin.ts`, `useProjectsQuery`

**What it does:**
- Server state management
- Automatic caching
- Background refetching
- Optimistic updates
- Already handles loading/error states

**Verdict:** ✅ **Keep it! Don't refactor these.**

TanStack Query is specifically designed for server state and does many things Zustand doesn't:
- Automatic background refetching
- Cache invalidation
- Stale-while-revalidate
- Query deduplication
- Parallel queries

### 2. Direct useState
**Files using:** `BadgesPageClient.tsx` (27+ useState hooks)

**What it does:**
- Manual state management
- Manual loading logic
- Manual error handling
- No caching
- State resets on unmount

**Verdict:** ❌ **Refactor to Zustand**

These are the pages that need refactoring to eliminate useState clutter.

### 3. Zustand
**What we created:**
- 11 stores for different features
- Global state management
- Filter persistence
- Simple caching

**Verdict:** ✅ **Use for client-side state**

---

## Pages That Use TanStack Query (DO NOT REFACTOR)

These pages already use query hooks and are optimized:

1. **Projects** - `useProjectsQuery`
2. **Updates** - Likely using queries
3. **Comments** - Likely using queries
4. **Community** - Likely using queries

**Why keep them:**
- TanStack Query handles server state better than Zustand
- They already have caching, background refetch, etc.
- Refactoring would be a downgrade
- No useState clutter (it's in the query hook)

---

## Pages That Should Use Zustand

These are pages with many useState hooks that should be refactored:

### High Priority

1. **BadgesPageClient.tsx** - 27+ useState hooks
2. **QuestsPageClient.tsx** - Likely many useState
3. **NotificationsPageClient.tsx** - Likely many useState
4. **WalletSettingsPageClient.tsx** - Settings forms
5. **TipSettingsPageClient.tsx** - Settings forms

### Medium Priority

6. **AdminAccessPageClient.tsx** - Admin management
7. **SocialCredentialsPageClient.tsx** - Credentials management
8. **SettingsPageClient.tsx** - General settings

---

## Hybrid Approach (Best Practice)

**Use TanStack Query for:**
- Server data (lists, details, etc.)
- Data that needs background refetching
- Optimistic updates
- Cache invalidation

**Use Zustand for:**
- Client-side UI state (filters, modals, etc.)
- State that persists across navigation
- Global app state (user, theme, etc.)
- Derived/computed state

**Example: Projects Page (Hybrid)**
```tsx
// Server state - TanStack Query
const { data: projects } = useProjectsQuery({ q, status, limit, offset });

// Client state - Zustand
const {
  searchQuery,
  statusFilter,
  setSearchQuery,
  setStatusFilter
} = useProjectsStore();
```

---

## Recommended Refactoring Plan

### Phase 1: Keep TanStack Query Pages (DONE ✅)

Pages like Projects, Updates, Comments are already optimized with TanStack Query.
- **Action:** Leave them as-is
- **Reason:** They're already using best practices

### Phase 2: Refactor Pages with Many useState

**Target:** Pages with 10+ useState hooks that aren't using queries

1. **BadgesPageClient** (27+ useState)
   - Create `badges-store.ts`
   - Create `use-badges.ts` hook
   - Refactor to use store

2. **QuestsPageClient**
   - Create `quests-store.ts`
   - Refactor to use store

3. **Settings Pages**
   - Use existing `wallet-settings-store`
   - Use existing `tip-settings-store`
   - Refactor form state

### Phase 3: Hybrid Optimization (Optional)

For pages using TanStack Query, you can still use Zustand for:
- Filter state persistence
- UI state (dialogs, selections)
- Derived/computed values

---

## Example: Refactoring BadgesPageClient

### Before (27+ useState hooks)
```tsx
const [loading, setLoading] = useState(true);
const [error, setError] = useState<string | null>(null);
const [badges, setBadges] = useState<BadgeModel[]>([]);
const [createOpen, setCreateOpen] = useState(false);
const [editOpen, setEditOpen] = useState(false);
const [grantOpen, setGrantOpen] = useState(false);
const [selectedBadge, setSelectedBadge] = useState<BadgeModel | null>(null);
const [newName, setNewName] = useState("");
const [newDescription, setNewDescription] = useState("");
const [newImageUrl, setNewImageUrl] = useState("");
const [newCategory, setNewCategory] = useState("engagement");
const [newRarity, setNewRarity] = useState("common");
const [newPoints, setNewPoints] = useState("0");
const [creating, setCreating] = useState(false);
const [editName, setEditName] = useState("");
const [editDescription, setEditDescription] = useState("");
const [editImageUrl, setEditImageUrl] = useState("");
const [editCategory, setEditCategory] = useState("engagement");
const [editRarity, setEditRarity] = useState("common");
const [editPoints, setEditPoints] = useState("0");
const [editActive, setEditActive] = useState(true);
const [editSaving, setEditSaving] = useState(false);
const [grantUserIdentifier, setGrantUserIdentifier] = useState("");
const [grantMatches, setGrantMatches] = useState<UserSearchResult[]>([]);
const [grantSearchLoading, setGrantSearchLoading] = useState(false);
const [grantSelected, setGrantSelected] = useState<UserSearchResult | null>(null);
const [granting, setGranting] = useState(false);
const [grantFeedback, setGrantFeedback] = useState<{
  type: "success" | "error";
  message: string;
} | null>(null);
```

### After (with Zustand)
```tsx
// Data
const { badges, isLoading, error, loadBadges } = useBadges();

// Dialogs
const {
  createOpen,
  editOpen,
  grantOpen,
  selectedBadge,
  openCreate,
  openEdit,
  openGrant,
  closeDialogs,
} = useBadgesDialogs();

// Forms (keep local state for forms - it's fine!)
const [newName, setNewName] = useState("");
const [newDescription, setNewDescription] = useState("");
// ... other form fields
```

**Result:**
- Data loading: Zustand store
- Dialog state: Zustand store
- Form inputs: Local useState (appropriate!)

---

## Action Items

### ✅ Already Done
- Created 11 Zustand stores
- Created 11 hooks
- Auth integration complete
- Example components created

### 🎯 Next Steps

1. **Identify** pages using TanStack Query
   - **Action:** Leave them alone
   - **Files:** Check for `useQuery`, `useMutation` imports

2. **List** pages with many useState
   - **Target:** 10+ useState hooks
   - **Candidates:** Badges, Quests, Settings pages

3. **Create** missing stores
   - `badges-store.ts`
   - `quests-store.ts`
   - Any other feature-specific stores

4. **Refactor** high-priority pages
   - BadgesPageClient first (27+ useState)
   - Then Quests, Notifications, etc.

5. **Test** each refactored page
   - Verify functionality
   - Check filter persistence
   - Test error handling

---

## Decision Matrix

| Page Feature | Has TanStack Query? | Has 10+ useState? | Action |
|-------------|---------------------|-------------------|--------|
| Projects | ✅ Yes | ❌ No | Keep as-is |
| Updates | ✅ Yes | ❌ No | Keep as-is |
| Comments | ✅ Yes | ❌ No | Keep as-is |
| Users | ❌ No | ✅ Yes | ✅ Use Zustand (done!) |
| Badges | ❌ No | ✅ Yes (27+) | ⚠️ Refactor to Zustand |
| Quests | ❌ No | ✅ Yes | ⚠️ Refactor to Zustand |
| Dashboard | ✅ Custom | ✅ Some | ✅ Use Zustand (example done!) |

---

## Conclusion

**DON'T refactor everything!**

- ✅ Keep TanStack Query pages (they're optimized)
- ✅ Use Zustand stores we created (auth, stats, users, etc.)
- ⚠️ Only refactor pages with excessive useState (10+ hooks)
- ✅ Consider hybrid approach for complex pages

**Focus on:**
1. Pages with 10+ useState hooks
2. Pages that need filter persistence
3. Pages with shared state needs
4. Form-heavy pages (settings)

**Avoid:**
1. Refactoring TanStack Query pages
2. Replacing server state management
3. Over-engineering simple pages

---

**Next:** Let me know which specific pages you want refactored, and I'll create the stores and refactor them properly!
