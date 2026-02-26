# Blocknet Backend (NestJS)

Backend API for Blocknet mobile and future admin panel.

## Stack
- NestJS
- Prisma ORM (v7 + `prisma.config.ts`)
- Supabase Postgres
- Supabase Auth JWT verification
- Firebase Cloud Messaging (push)

## Setup
```bash
bun install
cp .env.example .env.local
bun run prisma:generate
bun run prisma:migrate
bun run prisma:seed
bun run build
bun run start:dev
```

## Swagger
- UI: `http://localhost:3080/api/docs`
- JSON: `http://localhost:3080/api/docs-json`
- Use the `Authorize` button with a Supabase bearer token for protected endpoints.

## Bootstrap Notes
- `bun run prisma:seed` now inserts demo projects/updates/follows/notifications for local testing.
- Set `OWNER_USER_ID` and `OWNER_EMAIL` in `.env.local` if you want seed ownership tied to your real Supabase account.
- If owner env values are omitted, seed falls back to `owner@blocknet.local`.
- Use `SUPABASE_JWKS_URL` for JWT verification.
- Prisma CLI config is in `prisma.config.ts`.
- `DATABASE_URL` is used by runtime Prisma adapter (`@prisma/adapter-pg`).
- `DIRECT_URL` is preferred for Prisma migration commands.

## Test
```bash
bun run test
bun run test:e2e
```

## API Prefix
All routes are served under `/api`.

## Blocnet Edge Engine (BEE) V1 Endpoints
- `GET /api/me/edge/feed`
- `GET /api/me/edge/brief`
- `GET /api/me/edge/explain/:decisionId`
- `POST /api/me/edge/feedback`

## Blocnet Edge Engine (BEE) V2 (Admin Analytics - Sprint 1)
- `GET /api/admin/edge/overview`
- `GET /api/admin/edge/config`
- `PATCH /api/admin/edge/config` (owner/admin)

Feature flag:
- `ENABLE_BEE=true|false` (default: `true`)
- `ENABLE_BEE` is used as the bootstrap default; runtime enable/disable is stored in DB (`EdgeConfig`) and managed from admin.

Persistence:
- `EdgeDecision` table stores generated decision records and score components.
- `EdgeFeedback` table stores user feedback actions (`act|watch|ignore`).
- `EdgeConfig` table stores runtime BEE toggle state.

## Access Model (Current)
- Public read endpoints:
  - `GET /api/projects`
  - `GET /api/projects/:id`
  - `GET /api/updates`
  - `GET /api/updates/:id`
- Authenticated endpoints:
  - all mutations (create/update/follow/notifications/roles/admin review).

## Important Paths
- Prisma schema: `prisma/schema.prisma`
- Initial SQL snapshot: `prisma/migrations/0001_init/migration.sql`
- Modules: `src/*`
- Plan reference: `../BLOCKNET_PLAN.md`
