# Blocnet Blockchain Engine Deep Dive

This document explains the current blockchain transaction engine as implemented in code today.

## 1. What the "Blockchain Engine" Is (Today)

Blocnet currently runs a hybrid custody + ledger + settlement engine on BSC-compatible rails.  
It is not a custom L1/L2 consensus network; it is an application-layer transaction engine built on top of existing EVM infrastructure.

Core idea:
- On-chain handles token/native transfers and final settlement.
- Off-chain backend ledger tracks user balances, holds, fees, and internal transfers with strict transactional integrity.
- Workers reconcile chain events and backend state continuously.

## 2. Component Architecture

## A. On-chain Layer

- Network: BSC testnet/mainnet (configurable).
- Asset contract: `BNT` ERC20 (`contracts/contracts/BNT.sol`).
- Contract behavior: fixed supply minted to treasury at deployment.

Deployment + artifact flow:
- Deploy scripts: `contracts/scripts/deploy-bnt.js`
- Export ABI/address into backend: `contracts/scripts/export-artifact.js`
- Runtime artifacts consumed by backend:
  - `backend/src/wallet/artifacts/bnt.abi.json`
  - `backend/src/wallet/artifacts/bnt.addresses.json`

## B. Custody and Key Management Layer

- Abstraction: `CustodyAdapter` interface.
- Current provider: Turnkey (`TurnkeyCustodyAdapter`).
- Supports wallet creation, token transfers, and native transfers.
- Has execution modes:
  - `mock` (deterministic simulated tx hashes)
  - `real` (actual signed/broadcasted transactions)
  - `auto` (environment-dependent)

Files:
- `backend/src/wallet/custody/custody.adapter.ts`
- `backend/src/wallet/custody/turnkey-custody.adapter.ts`

## C. Off-chain Ledger Layer

Double-entry wallet ledger modeled in Prisma:
- `LedgerAccount` (`user`, `treasury`, `fee`, `hold`)
- `LedgerEntry` with reason codes (`deposit_credit`, `internal_transfer`, `withdrawal_hold`, `withdrawal_finalize`, etc.)

Design outcomes:
- Idempotency keys prevent duplicate postings.
- Serializable DB transactions protect against race conditions.
- Supports pending/locked/available balance states.

## D. Chain Ingestion + Settlement Worker Layer

Deposit path:
- `WalletDepositIndexerService` scans chain (logs for ERC20, block tx for native).
- `WalletDepositProcessorService` writes detected deposits and credits confirmed ones.
- `WalletSweepService` sweeps credited deposits to treasury.

Withdrawal path:
- User request creates ledger hold.
- Admin review transitions requests.
- `WalletWithdrawalSettlementService` broadcasts from treasury wallet, tracks confirmations, finalizes/reverts ledger effects.

Worker orchestrator:
- `WalletSettlementWorkerService`

## E. Risk, Compliance, and Runtime Controls

- Runtime toggles:
  - wallet/deposit/withdrawal enablement
  - per-asset enablement
  - confirmations, RPC URLs, withdrawal-enabled assets
- KYC profile and tiered risk limits.
- Fee configuration per asset.
- Admin APIs for health, user status, KYC, withdrawals, and runtime settings.

Files:
- `backend/src/wallet/wallet-config.service.ts`
- `backend/src/wallet/wallet-admin-config.service.ts`
- `backend/src/wallet/wallet-admin-kyc.service.ts`
- `backend/src/wallet/wallet-admin-withdrawal.service.ts`
- `backend/src/wallet/wallet-admin.service.ts`

## 3. Transaction Lifecycles

## A. Wallet Provisioning

1. Triggered by auth bootstrap or wallet API usage.
2. Upserts `KycProfile` and `UserWallet`.
3. Calls custody adapter `createWallet`.
4. Stores provider wallet ID + address.
5. Wallet status -> `ready` (or `error` with failure reason).

## B. On-chain Deposit Credit

1. Indexer detects candidate transfer to known wallet address.
2. Writes/updates `OnchainDeposit` (`detected`) idempotently by tx hash + log index.
3. Once confirmations pass threshold:
  - credits user ledger account
  - writes `LedgerEntry(reason=deposit_credit)`
  - marks deposit `credited`
4. Sweep job later moves on-chain funds to treasury sweep address and marks deposit `swept`.

## C. Internal Transfer

1. User submits transfer to userId/username/address.
2. Risk limit checks (daily USD cap).
3. Serializable ledger transaction moves value sender -> recipient.
4. Writes `LedgerEntry(reason=internal_transfer)`.

## D. Withdrawal

1. User submits withdrawal request.
2. Backend validates:
  - asset enabled
  - address format
  - KYC/risk tier and per-day/per-tx limits
  - sufficient available balance
3. Ledger hold:
  - user `available` decreases
  - user `locked` increases
  - hold account increases
  - `LedgerEntry(reason=withdrawal_hold)`
4. Admin reviews:
  - approve -> settlement worker broadcasts on-chain from treasury
  - reject -> hold released back to user
5. On confirmed tx:
  - hold -> treasury ledger finalization
  - fee ledger move to fee account
  - status -> `confirmed`
6. On failure:
  - revert ledger hold path
  - status -> `reverted`

## 4. Security and Integrity Controls Present

- JWT-based auth with role guards.
- Wallet operations gated by feature flags and runtime config.
- Idempotency keys across transfer/deposit/sweep/withdrawal paths.
- Serializable DB transactions on critical balance mutations.
- Address and tx-hash validation.
- Confirmation thresholds before credit/finalization.
- Comprehensive audit log writes around financial operations.

## 5. Current Gaps to Close Before High-Confidence Scale

These are implementation-level risks to track in launch hardening:

1. Admin rejection path currency assumption:
- `wallet-admin-withdrawal.service.ts` fetches rejection ledger accounts with hardcoded currency `'BNT'`.
- For non-BNT withdrawal assets, reject-flow behavior may be incorrect.

2. Deposit credit source account assumption:
- Deposit credit currently expects a `fee` ledger account as debit source.
- If missing, credits can fail until account exists/config is aligned.

3. Mainnet artifact consistency:
- `backend/src/wallet/artifacts/bnt.addresses.json` has `bscMainnet: null` while production env sets chainId 56 and a BNT address.
- Ensure deployment records and env values are aligned and verifiable.

4. Runtime/secret hygiene:
- Strictly keep production secrets out committed files and rotate on exposure.
- Enforce environment-managed secrets and documented rotation policy.

## 6. Investor Q&A Answers (Implementation-Accurate)

Q: "Did you build your own blockchain?"
- A: "No. We built an application-layer transaction engine on top of BSC. Our differentiation is custody orchestration, ledger integrity, risk controls, and product-level execution flows."

Q: "How do you prevent double spends or inconsistent balances?"
- A: "Critical mutations run in serializable DB transactions with idempotency keys and double-entry ledger postings."

Q: "How do on-chain and app balances stay in sync?"
- A: "Chain indexers detect deposits, confirmation thresholds gate crediting, and settlement workers sweep/confirm/reconcile with explicit state transitions."

Q: "What happens if an on-chain broadcast fails?"
- A: "Withdrawals are placed in hold first. Failures trigger controlled ledger reverts and request state transitions rather than silent loss."

Q: "How configurable is the system during operations?"
- A: "Runtime wallet config (enablement, assets, confirmations, RPC endpoints) is DB-backed and admin-controlled without requiring redeploys."

