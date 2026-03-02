# Founder Study Playbook (10 Days)

Goal: reach investor-grade technical command of the Blocnet stack without getting lost in implementation noise.

## Daily Method (90-120 minutes)

1. Read selected files end-to-end.
2. Write a one-page summary:
- what problem this module solves
- inputs/outputs
- failure modes
- dependencies
3. Explain it out loud in 2 minutes (record yourself).
4. Capture unknowns and answer them from code the same day.

## Day 1: System Skeleton

- `README.md`
- `backend/src/main.ts`
- `backend/src/app.module.ts`
- `mobile/lib/main.dart`
- `console/proxy.ts`

Deliverable:
- One-page system map (all major services and entry points).

## Day 2: Auth and Roles

- `backend/src/auth/auth.service.ts`
- `backend/src/auth/auth.controller.ts`
- `backend/src/common/guards/auth.guard.ts`
- `backend/src/common/guards/roles.guard.ts`
- `mobile/lib/services/auth_store.dart`

Deliverable:
- Sequence diagram of login, token verification, and role enforcement.

## Day 3: Wallet Foundations

- `backend/src/wallet/wallet.module.ts`
- `backend/src/wallet/wallet-config.service.ts`
- `backend/src/wallet/wallet-provisioning.service.ts`
- `backend/src/wallet/custody/*`
- `backend/prisma/schema.prisma` (wallet-related models)

Deliverable:
- Component map: custody, config, ledger, and status transitions.

## Day 4: Wallet Transactions

- `backend/src/wallet/wallet-transaction.service.ts`
- `backend/src/wallet/wallet-query.service.ts`
- `backend/src/wallet/wallet.controller.ts`
- `mobile/lib/features/wallet/data/repositories/wallet_api_repository.dart`
- `mobile/lib/services/wallet_store.dart`

Deliverable:
- Detailed flow notes for internal transfer + withdrawal request lifecycle.

## Day 5: On-chain Indexing and Settlement

- `backend/src/wallet/wallet-deposit-indexer.service.ts`
- `backend/src/wallet/wallet-deposit-processor.service.ts`
- `backend/src/wallet/wallet-sweep.service.ts`
- `backend/src/wallet/wallet-withdrawal-settlement.service.ts`
- `backend/src/wallet/wallet-settlement-worker.service.ts`

Deliverable:
- Deposit/withdrawal reconciliation explanation with states and retries.

## Day 6: Mining and Referrals Economy

- `backend/src/mining/mining.service.ts`
- `backend/src/mining/mining-calculator.service.ts`
- `backend/src/mining/mining-config.service.ts`
- `backend/src/referrals/referrals.service.ts`
- `mobile/lib/services/mining_store.dart`

Deliverable:
- Explain mining accrual math and referral boost mechanism clearly.

## Day 7: Edge Engine and BEE ML

- `backend/src/edge-engine/edge-engine.service.ts`
- `backend/src/edge-engine/edge-engine.utils.ts`
- `backend/src/edge-engine/ml-client.service.ts`
- `bee/app/main.py`
- `bee/app/models/registry.py`

Deliverable:
- Explain deterministic scoring vs optional ML enrichment.

## Day 8: Admin Control Plane

- `console/app/(protected)/dashboard/page.tsx`
- `console/app/(protected)/wallet-settings/page.tsx`
- `console/app/(protected)/mining/page.tsx`
- `console/app/(protected)/edge-engine/*`
- `backend/src/wallet/wallet-admin*.ts`

Deliverable:
- Explain how admins control runtime behavior and risk.

## Day 9: Contracts and Deployment Path

- `contracts/contracts/BNT.sol`
- `contracts/scripts/deploy-bnt.js`
- `contracts/scripts/export-artifact.js`
- `backend/src/wallet/artifacts/*`

Deliverable:
- One-page token deployment and backend integration explanation.

## Day 10: Rehearsal and Challenge Questions

Use:
- `INVESTOR_TECH_NARRATIVE.md`
- `BLOCKCHAIN_ENGINE_DEEP_DIVE.md`
- `LAUNCH_READINESS_CHECKLIST.md`

Deliverables:
- 60-second pitch.
- 5-minute technical walkthrough.
- 10-question hostile Q&A practice.

## Interview Prompts You Should Be Able to Answer

1. "How do you prevent double-crediting deposits?"
2. "What exactly happens in a failed withdrawal broadcast?"
3. "Where do you enforce KYC and risk limits?"
4. "How is treasury exposure controlled?"
5. "What parts are deterministic vs AI-driven?"
6. "What is your biggest technical launch risk today?"

