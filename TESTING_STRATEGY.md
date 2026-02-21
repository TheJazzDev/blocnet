# Blocnet Testing Strategy

This repo now has four critical surfaces that must be validated before deploy:
- `backend`
- `admin`
- `contracts`
- `mobile`

## 1) Pre-deploy quality gate (single command)

Run from repo root:

```bash
./scripts/ci/predeploy-check.sh
```

Optional flags:
- `SKIP_INSTALL=1` to skip re-installing deps.
- `RUN_BACKEND_E2E=1` to include backend e2e tests.

## 2) Test pyramid by surface

### Backend (NestJS + Prisma)
- Unit tests for service logic and mapping functions.
- Integration tests for API behavior touching auth + DB rules.
- E2E smoke tests for core health/auth/content flows.

Minimum gate:
- `bun run build`
- `bun run test`
- `bun run test:e2e` (recommended in release branches)

Priority next additions:
- Notifications fanout + follow preference integration.
- Wallet transfer/withdrawal integration with risk limits.
- Role-based access tests for admin-protected endpoints.

### Admin (Next.js)
- Unit tests for pure auth/RBAC helpers and API adapters.
- Component tests for critical forms/tables.
- E2E tests for login, route protection, and moderation actions.

Minimum gate:
- `bun run lint`
- `bun run test`
- `bun run build -- --webpack`

Priority next additions:
- `api-client` request/retry behavior.
- Protected route middleware/proxy behavior.
- Wallet admin pages (review and status flows).

### Contracts (Hardhat)
- Unit tests per contract for constructor, access control, supply/accounting.
- Event/assertion tests for transfer/mint/burn behavior.
- Mainnet/testnet deployment script dry-run validations.

Minimum gate:
- `bun run compile`
- `bun run test`

Priority next additions:
- Invariant/property tests for token safety constraints.
- Deployment + verify script checks in CI dry-run mode.

### Mobile (Flutter)
- Unit tests for model/store parsing and state transitions.
- Widget tests for critical UX flows and route guards.
- Integration tests for auth + feed + notifications flows.

Minimum gate:
- `flutter analyze`
- `flutter test`

Priority next additions:
- Feed/radar and notification digest store tests.
- Wallet screen action state + error handling widget tests.
- Profile role/permission UI tests.

## 3) CI policy

PRs must pass all quality gate jobs before merge:
- backend
- admin
- contracts
- mobile

Branch protection is required on both `dev` and `main`:
- `dev`: block direct pushes, require PR + required checks.
- `main`: block direct pushes, require PR + required checks.

Setup reference:
- `.github/BRANCH_PROTECTION.md`

## 4) Coverage target (incremental)

Current goal is reliability, not vanity coverage. Start here:
- Backend: 70% statements on changed files
- Admin: 60% statements on `lib/` modules
- Contracts: 100% constructor/access-control tests for deployed contracts
- Mobile: tests required for each new store/model and critical widget changes

Raise targets per quarter as suites stabilize.
