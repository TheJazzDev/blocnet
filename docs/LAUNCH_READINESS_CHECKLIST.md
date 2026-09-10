# Blocnet Launch Readiness Checklist

Status legend:
- `PASS`: clearly implemented in code.
- `VERIFY`: exists but needs environment/runtime confirmation.
- `BLOCKER`: must be resolved before high-confidence launch.

## 1. Identity and Access

- `PASS` JWT verification via Supabase JWKS in backend.
- `PASS` Role-based guards (`owner/admin/moderator`) on admin controllers.
- `VERIFY` Admin 2FA policy and enrollment should be enforced in production runtime, not only available.

Key files:
- `backend/src/auth/auth.service.ts`
- `backend/src/common/guards/auth.guard.ts`
- `backend/src/common/guards/roles.guard.ts`
- `backend/src/admin-security/*`

## 2. Wallet/Blockchain Controls

- `PASS` Runtime toggles for wallet/deposit/withdrawal and asset enablement.
- `PASS` Confirmation-based deposit crediting and withdrawal finalization.
- `PASS` Idempotency + serializable transactions on critical wallet flows.
- `VERIFY` Mainnet RPC, token addresses, treasury wallet IDs, and chain environment consistency in deployed env.
- `BLOCKER` Validate non-BNT withdrawal rejection path (hardcoded BNT account lookup in admin reject logic).

Key files:
- `backend/src/wallet/wallet-config.service.ts`
- `backend/src/wallet/wallet-transaction.service.ts`
- `backend/src/wallet/wallet-withdrawal-settlement.service.ts`
- `backend/src/wallet/wallet-admin-withdrawal.service.ts`

## 3. Treasury and Settlement Integrity

- `PASS` Deposit sweep jobs are queued and processed with state transitions.
- `PASS` Withdrawal broadcast + confirm + finalize/revert states implemented.
- `VERIFY` Ensure operational dashboards/alerts around stuck `processing`/`broadcasting` states.
- `VERIFY` Ensure `fee` and `treasury` ledger accounts are correctly seeded for every enabled asset.

Key files:
- `backend/src/wallet/wallet-sweep.service.ts`
- `backend/src/wallet/wallet-settlement-worker.service.ts`
- `backend/src/wallet/wallet-deposit-processor.service.ts`

## 4. KYC, Risk, and Fee Governance

- `PASS` KYC submission/review flow exists.
- `PASS` Tiered risk limits for withdrawal and internal transfers.
- `PASS` Asset-specific fee configuration path exists.
- `VERIFY` Production values for risk tiers and fee configs are reviewed and signed off.

Key files:
- `backend/src/wallet/wallet-admin-kyc.service.ts`
- `backend/src/wallet/wallet-admin-config.service.ts`
- `backend/prisma/schema.prisma` (`RiskLimit`, `WalletFeeConfig`)

## 5. Observability and Operations

- `PASS` API health, liveness, readiness endpoints.
- `PASS` DB health check with timeout and cached snapshots.
- `PASS` Financial/admin audit logs are written for critical actions.
- `VERIFY` External alerting/on-call wiring (Sentry/PagerDuty/etc.) is not represented in this repo and must be confirmed.

Key files:
- `backend/src/health/health.service.ts`
- `backend/src/prisma/database-health.service.ts`
- `backend/src/audit-log/*`

## 6. Edge Engine and ML Reliability

- `PASS` Deterministic scoring works without ML.
- `PASS` ML enrichment is optional and degrades gracefully on failure.
- `VERIFY` BEE ML availability and provider credentials for production.
- `VERIFY` Guardrails for model output quality and token-cost monitoring.

Key files:
- `backend/src/edge-engine/edge-engine.service.ts`
- `backend/src/edge-engine/ml-client.service.ts`
- `bee/app/models/registry.py`

## 7. Secrets and Configuration Hygiene

- `PASS` Env validation schema exists for required keys.
- `BLOCKER` Ensure no live production credentials remain in tracked env files; rotate exposed secrets and move to secret manager.
- `VERIFY` Re-issue custody/API keys after any exposure.

Key files:
- `backend/src/config/env.validation.ts`
- `backend/.env.*`
- `bee/.env*`

## 8. Product Surface Readiness

- `PASS` Mobile routes and stores are wired for wallet/mining/edge.
- `PASS` Admin console has operational pages for wallet/mining/edge.
- `VERIFY` Final UX polish for edge cases (timeouts, retries, empty/error states) should be tested on physical devices and lower-end networks.

Key files:
- `mobile/lib/main.dart`
- `mobile/lib/services/*_store.dart`
- `console/app/(protected)/*`

## 9. Pre-Launch Execution Plan (Recommended)

1. Resolve all `BLOCKER` items.
2. Run full gate: `./scripts/ci/predeploy-check.sh`.
3. Run production-like smoke tests:
- Auth login/refresh
- Wallet provision
- Test deposit detect -> credit -> sweep
- Withdrawal request -> approve -> confirm
- Mining start/claim
- Edge feed/brief/explain
4. Freeze features for 7 days and run incident drills.
5. Prepare investor demo script using `INVESTOR_TECH_NARRATIVE.md`.

