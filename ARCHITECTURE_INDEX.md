# Blocnet Architecture Index

This document maps the current implementation across mobile, backend, admin console, contracts, and BEE ML.

## 1. System Topology

- `mobile/` (Flutter): User-facing app, authenticated via Supabase, consumes backend APIs under `/api/*`.
- `backend/` (NestJS + Prisma): Core business logic, wallet/mining/referrals/quests/tips, admin APIs, Edge Engine (BEE scoring).
- `console/` (Next.js): Admin panel using server-side proxy to backend admin endpoints.
- `contracts/` (Hardhat + Solidity): BNT token contract and deployment/export scripts.
- `bee/` (FastAPI): Optional ML microservice used by backend Edge Engine for content analysis.

## 2. Runtime Entry Points

- Monorepo overview: `README.md`
- Backend bootstrap: `backend/src/main.ts`
- Backend module graph: `backend/src/app.module.ts`
- Mobile bootstrap/providers/router init: `mobile/lib/main.dart`
- Mobile router: `mobile/lib/app/router.dart`
- Console auth/proxy middleware: `console/proxy.ts`, `console/app/api/proxy/[...path]/route.ts`
- BEE ML app bootstrap: `bee/app/main.py`
- Smart contract: `contracts/contracts/BNT.sol`

## 3. Backend Module Map

### Auth and Identity

- JWT verification and user bootstrap: `backend/src/auth/auth.service.ts`
- Session verify endpoint: `backend/src/auth/auth.controller.ts`
- Request auth guard: `backend/src/common/guards/auth.guard.ts`

What happens:
- Verifies Supabase JWT via JWKS.
- Upserts profile data and default role.
- Kicks off wallet provisioning asynchronously (best-effort).

### Wallet + Blockchain Transaction Engine

- API: `backend/src/wallet/wallet.controller.ts`
- Admin API: `backend/src/wallet/wallet-admin.controller.ts`
- Query layer: `backend/src/wallet/wallet-query.service.ts`
- Transaction layer: `backend/src/wallet/wallet-transaction.service.ts`
- Config/runtime flags: `backend/src/wallet/wallet-config.service.ts`
- Provisioning/custody: `backend/src/wallet/wallet-provisioning.service.ts`
- Turnkey custody adapter: `backend/src/wallet/custody/turnkey-custody.adapter.ts`
- Deposit indexer: `backend/src/wallet/wallet-deposit-indexer.service.ts`
- Deposit processor/crediting: `backend/src/wallet/wallet-deposit-processor.service.ts`
- Sweep worker: `backend/src/wallet/wallet-sweep.service.ts`
- Withdrawal settlement worker: `backend/src/wallet/wallet-withdrawal-settlement.service.ts`
- Background worker orchestrator: `backend/src/wallet/wallet-settlement-worker.service.ts`

### Mining and Referral Economy

- Mining API: `backend/src/mining/mining.controller.ts`
- Mining core: `backend/src/mining/mining.service.ts`
- Mining formulas: `backend/src/mining/mining-calculator.service.ts`
- Mining config/admin metrics: `backend/src/mining/mining-config.service.ts`, `backend/src/mining/mining-admin.service.ts`
- Leaderboard: `backend/src/mining/mining-leaderboard.service.ts`
- Referrals API/logic: `backend/src/referrals/referrals.controller.ts`, `backend/src/referrals/referrals.service.ts`

### Edge Engine (Personalized Signal Ranking)

- User endpoints: `backend/src/edge-engine/edge-engine.controller.ts`
- Admin endpoints: `backend/src/edge-engine/edge-engine-admin.controller.ts`
- Ranking + persistence: `backend/src/edge-engine/edge-engine.service.ts`
- Scoring constants/utilities: `backend/src/edge-engine/edge-engine.utils.ts`
- Admin analytics/recompute: `backend/src/edge-engine/edge-admin.service.ts`
- ML service client: `backend/src/edge-engine/ml-client.service.ts`

### Platform Modules (selected)

- Projects/updates/comments/community: `backend/src/projects/*`, `backend/src/updates/*`, `backend/src/comments/*`, `backend/src/community-posts/*`
- Notifications and preferences: `backend/src/notifications/*`
- Quests and badges: `backend/src/quests/*`, `backend/src/badges/*`
- Tips economy: `backend/src/tips/*`
- Health checks: `backend/src/health/*`, `backend/src/prisma/database-health.service.ts`

## 4. Data Model Anchors (Prisma)

Primary schema: `backend/prisma/schema.prisma`

Key wallet/blockchain models:
- `UserWallet`
- `LedgerAccount`
- `LedgerEntry`
- `OnchainDeposit`
- `SweepJob`
- `WithdrawalRequest`
- `WalletRuntimeConfig`
- `RiskLimit`
- `WalletFeeConfig`

Key mining/referral models:
- `MiningSession`
- `MiningHourlyCheckpoint`
- `MiningPointLedger`
- `MiningConfig`
- `Profile` (`referredById`, `referralCode`)

Key Edge Engine models:
- `EdgeDecision`
- `EdgeFeedback`
- `EdgeConfig`
- `EdgeEngagement`

## 5. Mobile Architecture Map

- App bootstrap/providers: `mobile/lib/main.dart`
- Route catalog and access rules: `mobile/lib/constants/app_routes.dart`, `mobile/lib/routes/protected_routes.dart`
- Main shell and space switcher: `mobile/lib/features/main/presentation/pages/main_screen.dart`
- HTTP client: `mobile/lib/services/api/api_client.dart`
- Domain stores:
  - Wallet store: `mobile/lib/services/wallet_store.dart`
  - Mining store: `mobile/lib/services/mining_store.dart`
  - Edge store: `mobile/lib/services/edge_engine_store.dart`
  - Auth store: `mobile/lib/services/auth_store.dart`
- API repositories:
  - Wallet: `mobile/lib/features/wallet/data/repositories/wallet_api_repository.dart`
  - Mining: `mobile/lib/features/mining/data/repositories/mining_api_repository.dart`
  - Edge: `mobile/lib/features/engagement/data/repositories/edge_engine_api_repository.dart`

## 6. Console (Admin) Architecture Map

- Protected routing/session refresh: `console/proxy.ts`, `console/lib/admin-session-refresh.ts`
- Backend proxy API route: `console/app/api/proxy/[...path]/route.ts`
- API client: `console/lib/api-client.ts` (and supporting HTTP wrappers in `console/lib`)
- High-value admin surfaces:
  - Wallet ops/settings: `console/app/(protected)/wallet-settings/page.tsx`
  - Wallet users/withdrawals/KYC: `console/app/(protected)/wallet-users/page.tsx`, `console/app/(protected)/wallet-withdrawals/page.tsx`, `console/app/(protected)/wallet-kyc/page.tsx`
  - Mining ops: `console/app/(protected)/mining/page.tsx`
  - Edge analytics/controls: `console/app/(protected)/edge-engine/*`
  - Dashboard telemetry: `console/app/(protected)/dashboard/page.tsx`

## 7. Smart Contracts + On-chain Artifacts

- BNT contract: `contracts/contracts/BNT.sol`
- Hardhat config/networks: `contracts/hardhat.config.js`
- Deploy script: `contracts/scripts/deploy-bnt.js`
- ABI/address export to backend: `contracts/scripts/export-artifact.js`
- Current exported addresses: `backend/src/wallet/artifacts/bnt.addresses.json`

## 8. BEE ML Service Map

- FastAPI app: `bee/app/main.py`
- Analysis endpoint: `bee/app/api/analyze.py`
- Embeddings endpoint: `bee/app/api/embed.py`
- Provider registry/fallback: `bee/app/models/registry.py`
- Providers:
  - Ollama: `bee/app/models/providers/ollama.py`
  - Groq: `bee/app/models/providers/groq.py`
  - Gemini: `bee/app/models/providers/gemini.py`

## 9. Suggested Read Order (Founder Study)

1. `backend/src/main.ts` and `backend/src/app.module.ts`
2. Wallet engine stack (`wallet.module.ts`, config, transaction/query, indexer, sweep, withdrawal settlement, custody adapter)
3. Prisma wallet + mining + edge models in `backend/prisma/schema.prisma`
4. Mining + referral services
5. Edge Engine services + utils + admin analytics
6. Mobile stores/repositories for wallet, mining, edge
7. Admin console wallet/mining/edge pages
8. Contract and deployment/export scripts

