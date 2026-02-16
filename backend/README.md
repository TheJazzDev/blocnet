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
- `bun run prisma:seed` now inserts demo projects/posts/follows/notifications for local testing.
- Set `OWNER_USER_ID` and `OWNER_EMAIL` in `.env.local` if you want seed ownership tied to your real Supabase account.
- If owner env values are omitted, seed falls back to `owner@blocknet.local`.
- Use either `SUPABASE_JWKS_URL` or `SUPABASE_JWT_SECRET` for JWT verification.
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

## Access Model (Current)
- Public read endpoints:
  - `GET /api/projects`
  - `GET /api/projects/:id`
  - `GET /api/posts`
  - `GET /api/posts/:id`
- Authenticated endpoints:
  - all mutations (create/update/follow/notifications/roles/admin review).

## Important Paths
- Prisma schema: `prisma/schema.prisma`
- Initial SQL snapshot: `prisma/migrations/0001_init/migration.sql`
- Modules: `src/*`
- Plan reference: `../BLOCKNET_PLAN.md`
