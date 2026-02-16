# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Blocnet** is a structured crypto update network — a monorepo containing four apps:

```
blocnet/
├── backend/        # NestJS API (source of truth for all business logic)
├── mobile/         # Flutter app (user-facing)
├── admin/          # Next.js admin panel (reserved, minimal)
└── landing_page/   # Next.js marketing page
```

**Package manager**: `bun` for all Node projects. Use `bunx` instead of `npx`.

---

## Development Commands

### Backend (`cd backend`)

```bash
bun install
bun run dev                     # Hot reload dev server on :3080
bun run build && bun run start:prod

# Database
bun run prisma:generate         # Regenerate Prisma client after schema changes
bunx prisma migrate dev --name <name>   # Create and apply migration
bun run prisma:seed             # Seed database
bun run prisma:studio           # GUI at localhost:5555

# Testing
bun run test                    # Unit tests
bun run test:watch
bun run test:cov
bun run test:e2e

# Quality
bun run lint
bun run format
```

### Mobile (`cd mobile`)

```bash
flutter pub get
flutter run
flutter run --dart-define=API_BASE_URL=http://<ip>:3080/api   # Custom API URL
flutter test
flutter analyze
```

### Admin / Landing Page (`cd admin` or `cd landing_page`)

```bash
bun install
bun run dev       # admin → :3081, landing → :3000
bun run build
bun run lint
```

---

## Critical Rules

### Prisma Migrations
- **ALWAYS** use `prisma migrate dev` — **NEVER** `prisma db push`
- Workflow: edit `schema.prisma` → `bunx prisma migrate dev --name <name>` → this auto-generates and applies
- Never manually edit migration SQL files after creation

### Tailwind CSS v4 (admin / landing_page)
- `shrink-0` not `flex-shrink-0`
- `bg-linear-to-br` not `bg-gradient-to-br`
- Always mobile-first: start with base (mobile) values, scale up with `sm:`, `md:`, `lg:`
- Keep mobile padding/margins ~60–70% of desktop values
- Never use large bare values like `text-4xl`, `p-8`, `py-24` without responsive prefixes

---

## Backend Architecture

### Module Structure
Each feature module lives at `src/<feature>/` and contains a controller, service, and `dto/` folder. The `app.module.ts` imports all feature modules.

**Active modules:** `auth`, `users`, `roles`, `projects`, `updates`, `comments`, `project-assignments`, `project-proposals`, `follows`, `notifications`, `device-tokens`, `admin-applications`, `tags`, `audit-log`, `health`, `prisma`, `config`

### Auth & Authorization
- `AuthGuard` — validates Supabase JWT on each request
- `RolesGuard` — checks `@Roles()` decorator against user roles
- `@CurrentUser()` — injects the authenticated user into controller methods
- RBAC roles: `owner`, `admin`, `poster`, `user` (users can hold multiple roles)

### API Conventions
- Global prefix: `/api`
- Swagger docs: `http://localhost:3080/api/docs`
- Global `ValidationPipe` with `whitelist: true`, `forbidNonWhitelisted: true`
- Standard HTTP exceptions: `BadRequestException`, `ForbiddenException`, `NotFoundException`, `ConflictException`

### Database (Prisma + Supabase Postgres)
- Prisma 7 with `@prisma/adapter-pg` (connection pooling)
- Config: `prisma.config.ts` (Prisma 7 syntax — not `schema.prisma` datasource block alone)
- Content hierarchy (immutable invariants):
  1. `Project` → 2. `Update` → 3. `Comment`
  - An `Update` MUST have a `project_id`
  - A `Comment` MUST have an `update_id`

---

## Mobile Architecture

### State Management
Provider (`ChangeNotifier`) stores in `lib/services/`:
- `AuthStore` — auth state, user profile, roles
- `ProjectsStore` — project list, follow state
- `UpdatesStore` — updates feed, filters
- `CommentsStore`, `TagsStore`, `NotificationsStore`

All stores use `ApiClient` (`lib/services/api/api_client.dart`) which injects the Supabase Bearer token automatically.

### Feature Structure
`lib/features/<feature>/`
- `data/models/` — data models (e.g., `ProjectModel`, `UpdateModel`)
- `data/repositories/` — API calls via `ApiClient`
- `presentation/pages/` — full screens
- `presentation/widgets/` — reusable components
- `presentation/viewmodels/` or controllers — UI state

### Routing
- `lib/app/router.dart` — route generation
- `lib/routes/protected_routes.dart` — role-based route definitions
- `RouteAccessGate` — redirects unauthorized users
