# Prisma Database Workflow

## Files
- `schema.prisma`: source of truth for data models.
- `migrations/0001_init/migration.sql`: initial SQL snapshot generated from schema.

## Local development
```bash
bun run prisma:generate
bun run prisma:migrate
bun run prisma:seed
```

## Supabase target
1. Set `DATABASE_URL` to your Supabase pooled or direct Postgres URL.
2. Run `bun run prisma:migrate:status`.
3. Apply with `bun run prisma:migrate` (dev) or `bun run prisma:migrate:deploy` (shared env).

## Owner bootstrap
Set these env vars before seed if you want an owner account created:
- `OWNER_USER_ID`
- `OWNER_EMAIL`
