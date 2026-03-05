# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Console Application Overview

The **Blocnet Console** is a Next.js 16 admin panel for managing the Blocnet platform. It runs on port **3081** and communicates with the NestJS backend on port **3080**.

**Tech Stack:**
- Next.js 16 (App Router)
- TypeScript 5.8
- Tailwind CSS v4
- Zustand (state management)
- TanStack Query (server state)
- Supabase Auth
- Radix UI components

---

## Development Commands

```bash
# Install dependencies
bun install

# Development server (http://localhost:3081)
bun run dev

# Production build
bun run build
bun run start

# Code quality
bun run lint          # ESLint
bunx tsc --noEmit     # TypeScript check

# Testing
bun run test          # Run tests once
bun run test:watch    # Watch mode
```

**Hot Tips:**
- Backend must be running on `:3080` for API calls to work
- Use `bunx` instead of `npx` for all CLI commands
- Prisma schema lives in `backend/` - console just consumes the API

---

## Architecture

### App Router Structure

```
app/
├── (protected)/           # Routes requiring auth
│   ├── admin-access/      # Governance role management
│   ├── badges/            # Achievement badges
│   ├── projects/          # Project management
│   ├── users/             # User directory & management
│   ├── quests/            # Quest creation & editing
│   ├── quest-submissions/ # Quest review queue
│   ├── wallet-*/          # Wallet & withdrawal management
│   └── ...
├── signin/                # Login page
└── layout.tsx             # Root layout with providers
```

### State Management (Hybrid Approach)

**1. Zustand Stores** (`lib/stores/`) - Client State
- Use for: UI state, dialogs, forms, filters
- 17 stores total covering all major features
- All use Redux DevTools middleware for debugging
- Import from: `@/lib/stores` or use hooks from `@/lib/hooks`

**2. TanStack Query** (`lib/hooks/queries/`) - Server State
- Use for: Data fetching with auto-caching & background refetch
- Already implemented for: projects, updates, comments, users, tags, mining leaderboard
- **Keep these as-is** - don't refactor to Zustand

**When to use which:**
- **Zustand:** Pages with 10+ useState hooks, complex dialog/form state
- **TanStack Query:** Simple data fetching with caching needs
- **Hybrid:** Use both! TanStack Query for data + Zustand for UI state

### Component Organization

```
components/
├── admin-shell/           # Shell layout with sidebar, topbar, auth context
├── features/              # Feature-specific components
│   ├── badges/_components/
│   ├── quests/_components/
│   ├── users/_components/
│   └── ...
├── shared/                # Cross-feature shared components
├── ui/                    # Radix UI primitives (shadcn/ui pattern)
└── [root components]      # page-header, moderation-dialog, etc.
```

**Feature Structure Pattern:**
```
features/<feature>/
├── _components/
│   ├── PageClient.tsx          # Main client component
│   ├── <Feature>Table.tsx      # Data table
│   ├── <Feature>Dialog.tsx     # Dialogs/modals
│   └── types.ts / models.ts    # TypeScript types
```

### API Client (`lib/api-client.ts`)

**Core Concept:** The console is a **thin client** - all business logic lives in the NestJS backend.

- `apiFetch<T>()` - Primary HTTP client with automatic JWT injection
- `clientApi` - Typed methods for all endpoints (users, projects, quests, etc.)
- Organized into sub-modules: `api-client-users.ts`, `api-client-wallet.ts`, etc.
- Errors thrown as `ApiError` with status code & message

**Example:**
```tsx
import { apiFetch } from '@/lib/api-client';

// Simple fetch
const badges = await apiFetch<BadgeModel[]>('/admin/badges');

// With options
await apiFetch('/admin/quests', {
  method: 'POST',
  body: JSON.stringify(payload),
});
```

### Authentication & RBAC

**Auth Flow:**
1. User signs in via Supabase (`/signin`)
2. `AdminShell` validates session & loads user with roles from backend
3. User context provided via `useAdminSession()` hook
4. Zustand `auth-store` syncs for global state access

**Roles (from backend):**
- `owner` - Full access to everything
- `dev` - Developer access (can manage admins)
- `admin` - Standard admin (can manage moderators)
- `moderator` - Content moderation only
- `user` - No admin access

**Role Checking:**
```tsx
import { useAdminSession } from '@/components/admin-shell';
import { canManageTags, canMutateWallet } from '@/lib/rbac';

const session = useAdminSession();
const canEdit = session.effectiveRoles.includes('owner') ||
                session.effectiveRoles.includes('admin');

// OR use helper functions
const canEdit = canManageTags(session.effectiveRoles);
```

**Important:** Users can have multiple roles. Use `effectiveRoles` array, not a single role check.

### Zustand Store Pattern

**File Structure:**
```
lib/
├── stores/
│   ├── index.ts                    # Export all stores
│   ├── <feature>-store.ts          # Individual store
│   └── ...
├── hooks/
│   ├── index.ts                    # Export all hooks
│   ├── use-<feature>.ts            # Hook with data loading
│   └── ...
```

**Store Organization:**
```typescript
// lib/stores/example-store.ts
import { create } from 'zustand';
import { devtools } from 'zustand/middleware';

interface ExampleState {
  // Data
  items: Item[];
  isLoading: boolean;
  error: string | null;

  // UI State
  dialogOpen: boolean;
  selectedItem: Item | null;

  // Form State
  formField: string;

  // Actions
  setItems: (items: Item[]) => void;
  openDialog: (item: Item) => void;
  closeDialog: () => void;
  // ...
}

export const useExampleStore = create<ExampleState>()(
  devtools(
    (set) => ({
      // Initial state
      items: [],
      isLoading: false,
      // ...

      // Actions
      setItems: (items) => set({ items }),
      // ...
    }),
    { name: 'example-store' }
  )
);
```

**Hook Pattern:**
```typescript
// lib/hooks/use-example.ts
import { useCallback, useEffect } from 'react';
import { useExampleStore } from '@/lib/stores';
import { apiFetch } from '@/lib/api-client';

export function useExample(options = { autoLoad: true }) {
  const store = useExampleStore();
  const { setItems, setLoading, setError } = store;

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const data = await apiFetch<Item[]>('/admin/items');
      setItems(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [setItems, setLoading, setError]);

  useEffect(() => {
    if (options.autoLoad) {
      loadData();
    }
  }, [options.autoLoad, loadData]);

  return { ...store, loadData, refresh: loadData };
}
```

**Usage in Component:**
```tsx
const { items, isLoading, error, openDialog, closeDialog } = useExample();
```

---

## Critical Patterns

### 1. Mobile-First Responsive Design

**ALWAYS use mobile-first with Tailwind breakpoints:**

```tsx
// ❌ BAD - Desktop size on mobile
<h1 className="text-4xl">Title</h1>
<div className="p-8">Content</div>

// ✅ GOOD - Scales from mobile up
<h1 className="text-2xl sm:text-3xl md:text-4xl">Title</h1>
<div className="p-4 sm:p-6 md:p-8">Content</div>
```

**Common Patterns:**
- Hero titles: `text-2xl sm:text-3xl md:text-4xl lg:text-5xl`
- Section headings: `text-xl sm:text-2xl md:text-3xl`
- Body text: `text-sm sm:text-base md:text-lg`
- Padding: `p-4 sm:p-6 md:p-8`
- Icons: `w-5 h-5 sm:w-6 sm:h-6 md:w-8 sm:h-8`

### 2. Never Create V2 Files

When refactoring, **replace the original file directly**. Never create `ComponentV2.tsx` - just update `Component.tsx` in place.

### 3. Tailwind v4 Syntax

```css
/* OLD (v3) */
flex-shrink-0
bg-gradient-to-br

/* NEW (v4) */
shrink-0
bg-linear-to-br
```

### 4. Form Handling Pattern

```tsx
// Use FormData API for forms
async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
  e.preventDefault();
  const formData = new FormData(e.currentTarget);
  const payload = {
    name: formData.get('name') as string,
    // ...
  };
  await apiFetch('/endpoint', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}
```

### 5. Error Handling

```tsx
// Consistent error display
{error && (
  <Card className="border-destructive/35 bg-destructive/10">
    <CardContent className="pt-6 text-sm text-destructive">
      {error}
    </CardContent>
  </Card>
)}
```

---

## File Reference Patterns

When referencing code locations in explanations, use this format:
```
path/to/file.ts:123
```

Example: `The badges are loaded in lib/hooks/use-badges.ts:42`

This helps users quickly navigate to specific lines.

---

## Common Tasks

### Adding a New Admin Page

1. Create route: `app/(protected)/<feature>/page.tsx`
2. Create components: `components/features/<feature>/_components/`
3. Create types: `components/features/<feature>/_components/types.ts`
4. Add API methods if needed: `lib/api-client-<domain>.ts`
5. Create store (if 10+ useState): `lib/stores/<feature>-store.ts`
6. Create hook: `lib/hooks/use-<feature>.ts`
7. Export from index files
8. Add route to sidebar: `components/admin-shell/Sidebar.tsx`

### Adding RBAC Permission Check

1. Add function to `lib/rbac/permissions.ts`:
```typescript
export function canManageFeature(roles: string[]): boolean {
  return roles.includes('owner') || roles.includes('admin');
}
```

2. Use in component:
```tsx
import { useAdminSession } from '@/components/admin-shell';
import { canManageFeature } from '@/lib/rbac';

const session = useAdminSession();
const canEdit = canManageFeature(session.effectiveRoles);
```

### Debugging State

1. Open Redux DevTools in browser
2. All Zustand stores are visible with time-travel debugging
3. TanStack Query DevTools show cache state (already configured)

---

## Key Files

- `components/admin-shell/index.tsx` - Auth shell & session context
- `lib/api-client.ts` - HTTP client & API methods
- `lib/rbac/` - Role-based access control helpers
- `lib/stores/index.ts` - All Zustand stores
- `lib/hooks/index.ts` - All custom hooks
- `lib/supabase.ts` - Supabase client config
- `middleware.ts` - Auth middleware for route protection

---

## Testing

- Unit tests: `bun run test`
- Test files: `*.test.ts` or `*.spec.ts`
- Vitest configured for React components
- RBAC tests: `lib/rbac.test.ts`
- API client tests: `lib/api-client.test.ts`
