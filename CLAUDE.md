# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Monorepo Structure

**Blocnet** - Crypto social network with project discovery, mining, community, and wallet features.

```
blocnet/
├── backend/    # NestJS API - SOURCE OF TRUTH for all business logic
├── mobile/     # Flutter app - Consumer of backend API
├── console/    # Next.js admin - Thin client, see console/CLAUDE.md
├── homepage/   # Next.js marketing
└── contracts/  # Hardhat smart contracts
```

**Package manager**: `bun` (use `bunx` not `npx`)

---

## Quick Command Reference

| Task | Command |
|------|---------|
| **Backend dev** | `cd backend && bun run dev` (port 3080) |
| **Mobile dev** | `cd mobile && flutter run` |
| **Console dev** | `cd console && bun run dev` (port 3081) |
| **Quality gate** | `./scripts/predeploy-check.sh` |
| **Prisma migrate** | `cd backend && bunx prisma migrate dev --name <name>` |
| **Prisma studio** | `cd backend && bun run prisma:studio` (port 5555) |
| **Backend test** | `cd backend && bun run test` |
| **Mobile test** | `cd mobile && flutter test` |
| **Console test** | `cd console && bun run test` |

---

## Source of Truth Locations

| Information | File Path |
|-------------|-----------|
| **Database schema** | `backend/prisma/schema.prisma` |
| **Enums (status, roles, etc)** | `backend/prisma/schema.prisma` (Prisma enums) |
| **Role definitions** | `backend/src/common/enums/role.enum.ts` |
| **Role capabilities** | `backend/src/roles/role-capabilities.ts` |
| **AuthUser interface** | `backend/src/common/interfaces/auth-user.interface.ts` |
| **Backend modules** | `backend/src/app.module.ts` (imports) |
| **API endpoints** | `http://localhost:3080/api/docs` (Swagger) |
| **Mobile stores** | `mobile/lib/services/` |
| **Mobile features** | `mobile/lib/features/` |
| **Console architecture** | `console/CLAUDE.md` |

**CRITICAL**: Always reference `backend/prisma/schema.prisma` for database structure, enums, and relationships.

---

## Architectural Invariants

### 1. Content Hierarchy (IMMUTABLE)

```
Project (id) ← MUST exist first
  └── Update (project_id) ← MUST reference valid project
        └── Comment (update_id) ← MUST reference valid update
```

- Updates **cannot exist** without a project
- Comments **cannot exist** without an update
- Enforced at DB (foreign keys) and service layer
- Never bypass this hierarchy

### 2. Multi-Role System (CRITICAL)

**Users have MULTIPLE roles simultaneously** - `user.roles` is an array, not a string.

```typescript
// ❌ WRONG - Assumes single role
if (user.role === AppRole.ADMIN) { }

// ✅ CORRECT - Check array
if (user.roles.includes(AppRole.ADMIN)) { }
```

**Role hierarchy** (from `backend/src/roles/role-capabilities.ts`):
1. `owner` - Full platform access, can manage devs
2. `dev` - Engineering governance, can manage admins
3. `admin` - Operational admin, can manage moderators
4. `moderator` - Content moderation only
5. `core_team` - Visibility role (no governance power)
6. `hunter` - Project curator/manager
7. `user` - Base role (everyone has this)

**Role impersonation**: `AuthUser` has `actingAsRole` for testing lower permissions.

### 3. Backend is Single Source of Truth

- Mobile and Console are **thin clients** - no business logic
- All validation, authorization, and state mutations happen in backend
- Frontend clients only handle UI state and optimistic updates
- **Never** duplicate business logic in clients

### 4. Prisma Migration Workflow (NON-NEGOTIABLE)

```bash
# ✅ CORRECT workflow
1. Edit backend/prisma/schema.prisma
2. bunx prisma migrate dev --name descriptive_name
3. Auto-generates client + applies migration

# ❌ NEVER do this
prisma db push  # Bypasses migration history
```

- Prisma 7 uses `backend/prisma.config.ts` for config
- `DATABASE_URL` = connection pool (app runtime)
- `DIRECT_URL` = direct connection (migrations only)
- Migration files are immutable once created

### 5. BigInt Serialization Pattern

- Database: `BigInt` for token amounts (native precision)
- DTOs: Serialize as `string` (JSON can't represent BigInt)
- Frontend: Parse as needed

```typescript
// DTO transformation
class BalanceDto {
  @Expose()
  get balance(): string {
    return this.balanceBigInt.toString();
  }
}
```

---

## Critical Patterns

### Backend: Auth Flow

```typescript
// 1. Request hits AuthGuard
@UseGuards(AuthGuard)  // Validates Supabase JWT → injects user

// 2. Optional role check
@UseGuards(AuthGuard, RolesGuard)
@Roles(AppRole.ADMIN, AppRole.OWNER)  // OR logic

// 3. Access user in handler
async handler(@CurrentUser() user: AuthUser) {
  user.id       // Supabase user ID
  user.email    // Email from JWT
  user.roles    // AppRole[] - ALWAYS an array
}
```

**Guard order matters**: `AuthGuard` must run before `RolesGuard`.

### Mobile: Store Pattern

All stores in `lib/services/` extend `ChangeNotifier`:

```dart
class FeatureStore extends ChangeNotifier {
  List<Item> _items = [];
  bool _isLoading = false;

  // Getters
  List<Item> get items => _items;
  bool get isLoading => _isLoading;

  // Actions
  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();  // ← Triggers UI rebuild

    _items = await _apiClient.get('/items');
    _isLoading = false;
    notifyListeners();  // ← Triggers UI rebuild
  }
}
```

**Boot phases** (`lib/services/auth/auth_store.dart`):
1. `cold` - App launched
2. `shellReady` - UI shell rendered
3. `authReady` - Auth loaded
4. `dataHydrating` - Initial data loading
5. `ready` - Fully booted

### Mobile: API Client Pattern

`lib/services/api/api_client.dart`:
- Auto-injects Supabase Bearer token from `AuthStore`
- Auto-refreshes expired tokens (uses Supabase SDK)
- 15-second timeout
- Throws `ApiException(message, statusCode, responseBody)`

```dart
// Usage
final projects = await apiClient.get('/projects/discovery',
  query: {'limit': '20'});
```

### Console: State Architecture

See `console/CLAUDE.md` for full details. Summary:
- **Zustand** - Client state (dialogs, forms, filters)
- **TanStack Query** - Server state (data fetching, caching)
- **Hybrid approach** - Use both in same component

---

## Tailwind v4 Mobile-First (MANDATORY)

**Syntax changes:**
- `shrink-0` not `flex-shrink-0`
- `bg-linear-to-br` not `bg-gradient-to-br`

**Responsive pattern** (mobile → desktop):
```tsx
// ❌ BAD - Too large on mobile
<h1 className="text-4xl">Title</h1>

// ✅ GOOD - Scales up
<h1 className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl">Title</h1>
```

**Quick reference table:**

| Use Case | Pattern |
|----------|---------|
| Hero titles | `text-2xl sm:text-3xl md:text-4xl lg:text-5xl` |
| Section headings | `text-xl sm:text-2xl md:text-3xl` |
| Body text | `text-sm sm:text-base md:text-lg` |
| Section padding | `py-12 sm:py-16 md:py-20 lg:py-24` |
| Card padding | `p-4 sm:p-6 md:p-8` |
| Icons | `w-5 h-5 sm:w-6 sm:h-6 md:w-8 sm:h-8` |

**Rule**: Mobile padding/margins should be 60-70% of desktop values.

---

## Module Organization

### Backend Structure

```
src/<feature>/
├── <feature>.module.ts
├── <feature>.controller.ts     # @Get/@Post/@Patch/@Delete
├── <feature>.service.ts        # Business logic
├── <feature>.service.spec.ts   # Unit tests
└── dto/
    ├── create-<feature>.dto.ts
    ├── update-<feature>.dto.ts
    └── <feature>-response.dto.ts
```

**All modules registered in** `src/app.module.ts`.

**Key modules** (39 total - see `src/app.module.ts` for complete list):
- `auth` - JWT validation, Supabase integration
- `users` - Profiles, roles, lifecycle
- `projects` - Project CRUD, assignments, proposals
- `updates` - Update publishing with urgency levels
- `comments` - Threaded comments with mentions
- `community-posts` - Forum-style discussions
- `quests` - Quest system with submissions/verification
- `badges` - Achievement system
- `levels` - User progression system (NEW)
- `mining` - Mining mechanics, downlines, leaderboards
- `wallet` - Turnkey custody, transfers, withdrawals, KYC
- `edge-engine` - ML decision engine for project analysis
- `notifications` - FCM push + in-app notifications
- `audit-log` - Admin action tracking

### Mobile Structure

```
lib/
├── features/<feature>/
│   ├── data/models/         # Data models matching backend DTOs
│   ├── presentation/
│   │   ├── pages/           # Full screens
│   │   └── widgets/         # Reusable components
│   └── application/         # Business logic (optional)
├── services/
│   ├── api/api_client.dart  # HTTP client
│   ├── auth/                # Auth store
│   ├── core/                # App-wide stores
│   ├── projects/            # Project-related stores
│   ├── engagement/          # Mining, badges, levels
│   ├── community/           # Community posts
│   ├── notifications/       # Notifications
│   ├── wallet/              # Wallet state
│   └── edge/                # Edge engine
└── shared/                  # Shared widgets/utils
```

**Store count**: ~17 ChangeNotifier stores across domains.

---

## Common Issues & Solutions

### Backend

**Issue**: BigInt in JSON response
```typescript
// ❌ WRONG - BigInt doesn't serialize
return { balance: user.balance };  // Error!

// ✅ CORRECT - Convert to string
return { balance: user.balance.toString() };
```

**Issue**: N+1 queries
```typescript
// ❌ BAD - N+1 problem
const projects = await prisma.project.findMany();
for (const p of projects) {
  p.author = await prisma.user.findUnique({ where: { id: p.authorId } });
}

// ✅ GOOD - Single query with join
const projects = await prisma.project.findMany({
  include: { primaryAuthor: true },
});
```

**Issue**: Soft deletes not working
- Check for `deletedAt` field in queries
- Add `where: { deletedAt: null }` to exclude soft-deleted records

### Mobile

**Issue**: State not updating
```dart
// ❌ WRONG - Forgot to notify
void addItem(Item item) {
  _items.add(item);
}

// ✅ CORRECT - Always notify
void addItem(Item item) {
  _items.add(item);
  notifyListeners();  // ← This triggers rebuild
}
```

**Issue**: BuildContext used across async gap
```dart
// ❌ WRONG - Context may be unmounted
await apiClient.post('/data');
Navigator.push(context, ...);  // Context invalid!

// ✅ CORRECT - Check mounted
if (!mounted) return;
Navigator.push(context, ...);
```

**Issue**: Token refresh failing
- Check Supabase session validity
- Ensure `ApiClient.setAuthToken()` called after login
- Verify `AuthStore` is listening to auth state changes

### Console

**Issue**: Role check failing for multi-role users
```typescript
// ❌ WRONG
if (session.effectiveRoles === 'admin') { }  // Type error!

// ✅ CORRECT
if (session.effectiveRoles.includes('admin')) { }
```

See `console/CLAUDE.md` for more console-specific issues.

---

## Database Schema Patterns

**Reference**: Always check `backend/prisma/schema.prisma` for latest schema.

**Key patterns in schema:**
- `@id @default(cuid())` - All IDs are CUIDs
- `@default(now())` - Timestamps
- `@unique` - Unique constraints
- `@relation` - Foreign keys
- `@@index` - Performance indexes
- `@@unique([...])` - Composite unique constraints
- `deletedAt DateTime?` - Soft delete pattern

**Enum usage:**
```typescript
// ❌ WRONG - Magic strings
status: 'published'

// ✅ CORRECT - Use Prisma enums
import { UpdateStatus } from '@prisma/client';
status: UpdateStatus.published
```

**All enums defined in schema** - Never duplicate enum definitions.

---

## Testing Commands

| Project | Command | Notes |
|---------|---------|-------|
| Backend | `bun run test` | Unit tests (Jest) |
| Backend | `bun run test:e2e` | E2E tests |
| Backend | `bun run test:cov` | Coverage report |
| Mobile | `flutter test` | Widget + unit tests |
| Mobile | `flutter test --coverage` | Coverage |
| Console | `bun run test` | Vitest |
| **All** | `./scripts/predeploy-check.sh` | Quality gate |

**Quality gate runs**: Backend (build+test) → Console (lint+test+build) → Contracts (compile+test) → Mobile (analyze+test)

---

## API Conventions

- **Base URL**: `http://localhost:3080/api`
- **Swagger docs**: `http://localhost:3080/api/docs`
- **Health check**: `GET /api/health`
- **Auth header**: `Authorization: Bearer <supabase_jwt>`

**Standard responses:**
- `200` - Success
- `201` - Created
- `400` - Bad request (validation error)
- `401` - Unauthorized (missing/invalid token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not found
- `409` - Conflict (duplicate resource)
- `500` - Internal server error

**Global validation**: All DTOs validated with `class-validator`, whitelist enabled, non-whitelisted properties rejected.

---

## Environment Variables

### Backend (`.env.local`)

**Required:**
```bash
DATABASE_URL=postgresql://...         # Pooled connection
DIRECT_URL=postgresql://...           # Direct for migrations
SUPABASE_URL=https://...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
JWT_SECRET=...
OWNER_USER_ID=...                     # For seed script
```

**Optional but common:**
```bash
FIREBASE_PROJECT_ID=...               # Push notifications
TURNKEY_API_BASE_URL=...             # Wallet custody
PORT=3080                             # Override port
NODE_ENV=development
```

### Mobile

Uses `--dart-define` flags:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3080/api
```

Default: `http://localhost:3080/api`

---

## Adding New Features

### Backend Checklist

1. Update `backend/prisma/schema.prisma` if needed
2. Run `bunx prisma migrate dev --name add_<feature>`
3. Generate module: `nest g module <feature>`
4. Generate service: `nest g service <feature>`
5. Generate controller: `nest g controller <feature>`
6. Create DTOs in `dto/` with `class-validator` decorators
7. Add guards (`@UseGuards(AuthGuard, RolesGuard)`)
8. Add role restrictions (`@Roles(AppRole.ADMIN)`)
9. Register module in `src/app.module.ts`
10. Update seed files if needed
11. Write tests (`*.spec.ts`)
12. Document in Swagger (via decorators)

### Mobile Checklist

1. Create feature dir: `lib/features/<feature>/`
2. Create data models: `data/models/<feature>_model.dart`
3. Create store: `lib/services/<domain>/<feature>_store.dart`
4. Create pages: `presentation/pages/<feature>_screen.dart`
5. Create widgets: `presentation/widgets/`
6. Add routes to `lib/app/router.dart`
7. Provide store in widget tree
8. Update `ApiClient` if new endpoints needed
9. Write tests: `test/<feature>_test.dart`

---

## Key Files to Reference

### Backend
- `src/main.ts` - App bootstrap, Swagger config, global pipes
- `src/app.module.ts` - Module imports (source of truth for modules)
- `backend/prisma/schema.prisma` - **Database schema (ALWAYS check this)**
- `src/common/guards/auth.guard.ts` - JWT validation logic
- `src/common/guards/roles.guard.ts` - RBAC enforcement
- `src/roles/role-capabilities.ts` - Role definitions & capabilities

### Mobile
- `lib/main.dart` - App entry, provider setup
- `lib/services/api/api_client.dart` - HTTP client implementation
- `lib/services/auth/auth_store.dart` - Auth state, boot phases
- `lib/app/router.dart` - Route definitions
- `lib/routes/protected_routes.dart` - Role-based access

### Console
- See `console/CLAUDE.md` for complete console reference

---

## Additional Documentation

- `README.md` - Quick start guide
- `BLOCNET_PLAN.md` - Product roadmap
- `ARCHITECTURE_INDEX.md` - Architecture deep dive
- `console/CLAUDE.md` - Console-specific architecture
- `backend/prisma/schema.prisma` - **PRIMARY reference for data structure**
