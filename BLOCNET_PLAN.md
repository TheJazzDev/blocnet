# Blocknet Build + Learning Master Plan

## Product Premise and Mission
Blocknet is a structured crypto update network that solves update overload in large communities.

Problem:
- Critical project updates are lost in high-noise chat streams.
- Users miss launch windows, KYC requirements, and urgent project actions.

Mission:
- Organize updates into projects and project posts.
- Let users follow projects they care about.
- Deliver urgency-aware notifications (high/medium/low).
- Build a trust-led contribution system where quality research is rewarded.

Long-term vision (post-MVP):
- tokenized contributor rewards,
- wallet integrations,
- stronger trust and safety scoring.

## Monorepo Structure (Locked)
- `mobile/` Flutter app (existing product UI)
- `backend/` NestJS API (single source of business logic)
- `admin/` reserved for future Next.js admin panel

## Locked Architecture Decisions
- Backend: NestJS (shared API for mobile now and admin web later).
- Database: Supabase Postgres.
- ORM: Prisma.
- Prisma runtime mode: Prisma 7 + `prisma.config.ts` + Postgres adapter (`@prisma/adapter-pg`).
- Auth issuer: Supabase Auth.
- Authorization authority: NestJS role + resource guards.
- Signup: open (not invite-only).
- Role chain: owner promotes admins, admins promote posters.
- Poster scope: posters can only post in assigned projects.
- Notifications: Postgres in-app notification records + FCM push.
- Package manager: `bun` (use `bunx` instead of `npx`).

## Role and Permission Matrix (Locked)
### `owner`
- Promote/demote admins.
- Access full moderation and audit logs.
- Global oversight.

### `admin`
- Create/manage projects.
- Promote users to posters.
- Assign posters to projects.
- Moderate posts in owned/managed projects.

### `poster`
- Create/edit posts only in assigned projects.
- Cannot create projects.
- Cannot change roles.

### `user`
- Follow/unfollow projects.
- Read feeds and notifications.
- Apply for elevated roles.

## Backend Modules (Implemented Scaffold)
- `auth`
- `users`
- `roles`
- `admin-applications`
- `projects`
- `project-assignments`
- `posts`
- `follows`
- `notifications`
- `device-tokens`
- `health`
- `audit-log`
- `prisma`

## API Contract (MVP Surface)
Implemented route scaffolding:
- `POST /api/auth/session/verify`
- `GET /api/me`
- `PATCH /api/me`
- `POST /api/admin-applications`
- `GET /api/admin-applications`
- `PATCH /api/admin-applications/:id/review`
- `POST /api/roles/admins/:userId/promote`
- `POST /api/roles/posters/:userId/promote`
- `POST /api/projects`
- `GET /api/projects`
- `GET /api/projects/:id`
- `PATCH /api/projects/:id`
- `POST /api/projects/:projectId/posters/:posterId/assign`
- `POST /api/projects/:projectId/follow`
- `DELETE /api/projects/:projectId/follow`
- `POST /api/projects/:projectId/posts`
- `GET /api/posts`
- `GET /api/posts/:id`
- `PATCH /api/posts/:id`
- `GET /api/notifications`
- `PATCH /api/notifications/:id/read`
- `POST /api/device-tokens/register`
- `DELETE /api/device-tokens/:id`
- `GET /api/health`
- `GET /api/audit-log`

## Database Schema and Migration Order
Prisma schema is defined in:
- `backend/prisma/schema.prisma`

Migration sequence (locked):
1. `profiles`, `user_roles`
2. `projects`, `project_posters`
3. `posts`
4. `project_follows`
5. `notifications`
6. `device_tokens`
7. `admin_applications`
8. `audit_logs`

## Notification Architecture
On post creation:
1. Validate author permissions (owner/admin ownership/assigned poster).
2. Save post in Postgres.
3. Resolve project followers.
4. Insert one in-app notification row per follower.
5. Resolve device tokens and send FCM pushes.
6. Track delivery outcomes for retries.

Client behavior:
- Notification center reads from `/api/notifications`.
- Read actions call `/api/notifications/:id/read`.
- Refresh on foreground and push-open.

## Flutter Refactor Targets
Current target state:
- Replace Firebase data services with NestJS API repositories.
- Remove runtime dummy-data dependencies from active flows.
- Keep Provider for MVP speed.
- Add role-aware route guards and auth-aware API client.

Already implemented now:
- moved Flutter app into `mobile/`.
- replaced deprecated `flutter_markdown` with `flutter_markdown_plus`.
- fixed Explore list indexing bug to use live list length.

## Week-by-Week Execution Plan
### Week 1
- Scaffold backend and wire Prisma/Supabase connection.
- Implement auth verify endpoint and guard baseline.
- Commit initial schema and migration plan.

### Week 2
- Implement roles and admin application workflows.
- Implement owner/admin promotions.
- Add audit logs on role lifecycle.

### Week 3
- Implement project and post modules.
- Enforce poster assignment checks.
- Integrate mobile feed with API reads.

### Week 4
- Implement follow/unfollow and notification fanout.
- Implement device token registration and FCM delivery.
- Integrate notification center in mobile.

### Week 5
- Add validation hardening, pagination, rate-limits.
- Add permission negative tests.
- Replace template Flutter tests with feature tests.

### Week 6
- Beta hardening and query tuning.
- Fix edge-case bugs and finalize RC.

## Testing and Release Gates
Release is blocked unless all are true:
- unauthorized role escalation is blocked,
- posters cannot post outside assigned projects,
- followers receive in-app notifications on new project posts,
- push notifications deliver to subscribed devices,
- urgency/feed results match backend truth,
- no dummy data is used in production code paths.

## Learning Track (Yardstick)
### NestJS learning milestones
- Module architecture and dependency boundaries.
- Guards/decorators for RBAC.
- DTO validation and request contracts.
- Prisma transactions and data modeling.
- Background job/push delivery patterns.

Weekly deliverable:
- add one ADR entry summarizing one key technical decision and tradeoff.

### Flutter learning milestones
- Repository integration against API.
- Provider state boundaries and async flow control.
- Role-gated UI and navigation.
- Error/loading/empty state quality.
- Widget tests for critical flows.

Weekly deliverable:
- add one short before/after implementation note.

## Operational Details to Keep Documented
- environment variable list and ownership,
- setup steps for new machines,
- seed strategy for dev/staging,
- backup/restore plan,
- notification incident runbook,
- API versioning policy,
- Definition of Done checklist template.

## Environment Variables
Backend `.env.local` should include:
- `DATABASE_URL`
- `DIRECT_URL`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_JWKS_URL` or `SUPABASE_JWT_SECRET`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`
- `OWNER_USER_ID` (optional; for owner bootstrap seed)
- `OWNER_EMAIL` (optional; for owner bootstrap seed)
- `PORT`
- `NODE_ENV`

Reference file:
- `backend/.env.example`

## Command Cheat Sheet
### Backend
- `cd backend`
- `bun install`
- `bun run prisma:generate`
- `bun run prisma:migrate`
- `bun run prisma:seed`
- `bun run build`
- `bun run test`
- `bun run test:e2e`
- `bun run start:dev`

### Mobile
- `cd mobile`
- `flutter pub get`
- `flutter analyze`
- `flutter run`

## Current Implementation Status (This Iteration)
Completed:
- Monorepo restructure: root + `mobile/` + `backend/` + `admin/`.
- NestJS backend scaffold with all planned modules.
- Prisma schema created for role/project/post/follow/notification lifecycle.
- Initial SQL migration snapshot generated at `backend/prisma/migrations/0001_init/migration.sql`.
- Auth/session verification + role-aware guards baseline.
- Environment validation wired through `ConfigModule` with schema checks.
- Core API route scaffolding across modules.
- Prisma upgraded to v7 with adapter-based runtime connection in NestJS (`PrismaPg` + `pg`).
- Prisma CLI moved to `backend/prisma.config.ts`; schema `datasource.url` removed per Prisma 7 requirements.
- FCM service scaffolding and notification fanout integration point.
- Build + unit test + e2e health test passing in backend.
- Backend CI workflow added: `.github/workflows/backend-ci.yml`.
- Mobile markdown dependency deprecation fixed.
- Mobile explore indexing runtime risk fixed.
- Mobile data layer migrated to API repositories (`PostsApiRepository`, `ProjectsApiRepository`) with `ApiClient`.
- Runtime Firestore/dummy service dependencies removed from active screens/stores.
- Priority/project-details/related-post flows now read from API-backed Provider stores.
- Backend read endpoints (`projects`/`posts`) are currently public for mobile bootstrap.

Pending (next implementation wave):
- Implement authenticated mobile flows (Supabase session -> bearer token injection).
- Replace placeholder admin/project metadata with richer backend fields.
- Run and verify Prisma migration application in your target Supabase instance.
- Add advanced observability, rate limits, and moderation tooling.

## Assumptions and Defaults
- Android-first MVP.
- Admin panel will be a future `admin/` Next.js app consuming the same backend API.
- Token/wallet systems are post-MVP.
- Provider remains in mobile for MVP speed; large state refactor deferred.
