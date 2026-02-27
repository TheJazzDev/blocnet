# Blocknet Monorepo

This repository now contains:
- `mobile/` Flutter client
- `backend/` NestJS API (Prisma + Supabase Postgres)
- `console/` Next.js admin panel
- `homepage/` Next.js marketing site
- `contracts/` Hardhat smart contracts

Master plan and execution reference:
- `BLOCKNET_PLAN.md`

## Quick Start

### Backend
```bash
cd backend
bun install
# create backend/.env.local from backend/.env.example
bun run prisma:generate
bun run prisma:migrate
bun run prisma:seed
bun run build
bun run start:dev
```

### Mobile
```bash
cd mobile
flutter pub get
flutter analyze
flutter run
# override backend URL when needed:
# flutter run --dart-define=API_BASE_URL=http://<your-ip>:3080/api
```

## Testing

Run the full pre-deploy quality gate:

```bash
./scripts/ci/predeploy-check.sh
```

Reference:
- `TESTING_STRATEGY.md`
- `.github/BRANCH_PROTECTION.md`

## Notes
- Use `bun`/`bunx` for backend workflows.
- Prisma 7 CLI uses `backend/prisma.config.ts`.
- Use `DATABASE_URL` for app runtime and `DIRECT_URL` for Prisma migrations.
- API is prefixed with `/api`.
- Health endpoint: `/api/health`.
- Swagger UI: `http://localhost:3080/api/docs`.
- For seed bootstrap, set `OWNER_USER_ID` and `OWNER_EMAIL` in `backend/.env.local`.

