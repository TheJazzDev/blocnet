# Blocnet End-to-End Flow Maps

This is the operational walkthrough for the most important user and platform flows.

## Flow 1: Authentication and Session Bootstrap

Goal: user signs in on mobile, backend verifies identity, profile/roles/wallet context becomes ready.

### Sequence

1. User signs in with Supabase from mobile:
- `mobile/lib/services/auth_store.dart`

2. Mobile gets access token and verifies session against backend:
- Backend endpoint: `POST /api/auth/session/verify`
- Controller: `backend/src/auth/auth.controller.ts`
- Service: `backend/src/auth/auth.service.ts`

3. Backend validates JWT via Supabase JWKS:
- `backend/src/auth/auth.service.ts`

4. Backend upserts `Profile`, ensures default role if missing, returns auth user payload.

5. Backend triggers wallet provisioning async (best effort, non-blocking to auth):
- `WalletProvisioningService.ensureWalletForUser`
- `backend/src/wallet/wallet-provisioning.service.ts`

6. Mobile stores token and hydrates user/session state:
- `mobile/lib/services/auth_store.dart`

### Why this matters for investor discussions

- You can state that identity is externally anchored (Supabase JWT), while application roles and wallet state are internal and controlled by backend policy.

## Flow 2: Mining Cycle -> Claim -> BNP Balance Credit

Goal: user starts mining cycle, accrues points hourly, claims completed cycle, receives BNP balance.

### Sequence

1. User starts mining:
- Mobile call: `POST /api/mining/start`
- Repo/store: `mobile/lib/features/mining/data/repositories/mining_api_repository.dart`, `mobile/lib/services/mining_store.dart`
- Backend: `backend/src/mining/mining.controller.ts`, `backend/src/mining/mining.service.ts`

2. Backend validates config/profile and creates `MiningSession` with referral boost snapshot.

3. Hourly accrual is synchronized on reads/actions:
- `syncHourlyAccrualForUser` and `syncHourlyAccrualForSession`
- Creates `MiningHourlyCheckpoint` rows.

4. User claims:
- Mobile call: `POST /api/mining/claim`
- Backend marks session/checkpoints claimed and writes `MiningPointLedger` (`source=cycle_claim`).

5. Backend credits tip economy BNP account:
- Upserts `TipCurrency` (`BNP`), increments user `TipAccount.balanceAtomic`.

6. Badges/quests post-processing runs:
- Mining milestones + streak quest trigger.

### Data touched

- `MiningSession`
- `MiningHourlyCheckpoint`
- `MiningPointLedger`
- `Profile.miningClaimedPoints`
- `TipCurrency`, `TipAccount`

### Why this matters

- Mining is not just UI counters; it is persisted, checkpointed, and reconciled with an economy balance ledger.

## Flow 3: Wallet and Blockchain Lifecycle (Provision -> Deposit -> Sweep -> Withdrawal)

Goal: custodial wallet operations with internal ledger consistency and on-chain settlement.

### A. Provisioning

1. On first wallet access/auth bootstrap, backend ensures wallet record:
- `WalletProvisioningService.ensureWalletForUser`

2. Custody adapter provisions address:
- Interface: `backend/src/wallet/custody/custody.adapter.ts`
- Turnkey implementation: `backend/src/wallet/custody/turnkey-custody.adapter.ts`

3. Wallet status transitions:
- `provisioning` -> `ready` or `error`

### B. Deposit Detection and Credit

1. Indexer worker ticks:
- `WalletDepositIndexerService` (`OnModuleInit`)

2. Reads active network config:
- `WalletConfigService.getDepositNetworkConfigs`

3. Scans:
- ERC20 `Transfer` logs for token assets (BNT/USDT)
- Native tx block scanning for BNB

4. Records detected deposit idempotently:
- `WalletDepositProcessorService.recordDetectedDeposit`
- Model: `OnchainDeposit` (`status=detected`)

5. After confirmation threshold, credits user ledger:
- `WalletDepositProcessorService.creditDetectedDeposit`
- Creates `LedgerEntry` (`reason=deposit_credit`)
- Updates `OnchainDeposit` -> `credited`

6. Settlement worker queues/executes sweep to treasury:
- `WalletSweepService.queueDepositSweeps` / `processSweepJobs`
- Uses custody adapter transfer; marks deposits `swept`.

### C. Internal Transfer

1. User calls `POST /api/wallet/transfers/internal`.
2. Backend validates limits and recipient.
3. Serializable DB transaction:
- debit sender `LedgerAccount.available`
- credit recipient `LedgerAccount.available`
- create `LedgerEntry` (`reason=internal_transfer`)

### D. Withdrawal

1. User calls `POST /api/wallet/withdrawals`.
2. Backend validates:
- asset enabled
- EVM address format
- KYC/risk tier
- per-tx and daily limits (USD conversion using asset pricing service)

3. Backend places funds on hold (serializable transaction):
- user account: `available - amount`, `locked + amount`
- hold account: `available + amount`
- ledger entry `reason=withdrawal_hold`
- create `WithdrawalRequest` (`pending_review`)

4. Admin approves/rejects:
- `PATCH /api/admin/wallet/withdrawals/:id/review`
- approval sets `status=approved`
- rejection releases hold and marks rejected

5. Settlement worker broadcasts approved withdrawals from treasury wallet:
- `WalletWithdrawalSettlementService.processApprovedWithdrawals`
- custody adapter sends token/native transfer

6. Confirmations tracked; finalization on success:
- `broadcasting` -> `confirmed`
- hold -> treasury ledger move (`withdrawal_finalize`)
- fee allocation (`withdrawal_fee`)
- revert path exists for failed on-chain broadcasts.

### Data touched

- `UserWallet`, `LedgerAccount`, `LedgerEntry`
- `OnchainDeposit`, `SweepJob`
- `WithdrawalRequest`, `KycProfile`, `RiskLimit`, `WalletFeeConfig`

### Why this matters

- Off-chain balances are enforced via double-entry ledger and serialized transactions, while on-chain transfer state is tracked and reconciled asynchronously.

## Flow 4: Edge Engine Personalized Feed and Brief

Goal: rank followed-project updates into “act/watch/ignore” signals, optionally ML-enriched.

### Sequence

1. Mobile requests:
- `GET /api/me/edge/feed`
- `GET /api/me/edge/brief`
- via `EdgeEngineApiRepository` and `EdgeEngineStore`

2. Backend loads follow context and recent updates.

3. Scores each update using weighted components:
- urgency, recency, relevance, novelty, penalties
- logic in `backend/src/edge-engine/edge-engine.utils.ts`

4. Computes recommendation:
- `act` / `watch` / `ignore`
- reason codes and explanation preview generated.

5. Optional ML enrichment:
- `MLClientService` calls BEE ML (`/analyze/batch`)
- appends quality/sentiment/topics/actionability/insights fields.

6. Persists `EdgeDecision` and returns ranked feed/brief payload.

7. User can open explain and submit feedback:
- `GET /api/me/edge/explain/:decisionId`
- `POST /api/me/edge/feedback`
- persisted as `EdgeFeedback`.

### Why this matters

- You can position this as a deterministic ranking core with optional AI enrichment, not AI-only black box ranking.

## Flow 5: Admin Console Command/Control Path

Goal: admin actions are routed through secure session cookies and backend RBAC.

### Sequence

1. Admin signs in at console.
2. Middleware and proxy maintain access/refresh token cookies:
- `console/proxy.ts`
- `console/lib/admin-session-refresh.ts`
- `console/app/api/proxy/[...path]/route.ts`

3. Console pages call `clientApi` helpers; proxy forwards to backend `/api/admin/*`.
4. Backend enforces `AuthGuard` + `RolesGuard` for admin endpoints.
5. Admin actions update runtime configs and emit audit logs.

### Why this matters

- Operational controls are live and runtime-tunable, reducing redeploy dependency for policy changes.

