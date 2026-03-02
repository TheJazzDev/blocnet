# Investor Technical Narrative

Use this as your speaking script. It is aligned to the current implementation.

## 1. 60-Second Version

"Blocnet is a crypto project intelligence and engagement platform with a production-grade backend transaction engine.  
On the user side, mobile and admin surfaces run on a unified API.  
On the financial side, we run a hybrid wallet engine: custodial key management via Turnkey, EVM settlement on BSC, and an internal double-entry ledger that guarantees balance integrity using idempotency and serializable transactions.  
On top of that, we built a mining and referrals economy, plus a personalized Edge Engine that ranks project updates into act/watch/ignore signals, with optional AI enrichment through a separate ML service.  
So the moat is not just one feature; it is the integrated execution stack: product experience, operations tooling, and controlled financial workflows."

## 2. 5-Minute Walkthrough

## Product Layer

- Mobile app (Flutter) for users.
- Admin console (Next.js) for operations.
- Both consume one backend service (NestJS).

## Core Platform Layer

- Auth uses Supabase JWT verification in backend.
- Backend creates/maintains profiles, roles, and operational state.
- Runtime flags allow operations to turn major systems on/off without redeploy.

## Blockchain Transaction Engine

- We run on BSC rails with BNT ERC20.
- Each user gets a custodial wallet address via Turnkey.
- All balance-critical operations go through an internal ledger:
  - available/pending/locked balances
  - hold/treasury/fee accounts
  - auditable reason-coded entries
- Deposit flow:
  - chain event detection -> confirmation checks -> ledger credit -> sweep to treasury
- Withdrawal flow:
  - request -> hold funds -> admin review -> on-chain broadcast -> confirmation -> finalize or revert

## Token + Smart Contract Footprint

- BNT contract is fixed-supply ERC20 minted to treasury.
- Deployment and artifact export scripts feed backend runtime.

## Intelligence Layer (Edge Engine + BEE ML)

- Deterministic ranking model scores updates on urgency, recency, relevance, novelty.
- Returns act/watch/ignore decisions with explanation.
- Optionally enriches with ML analysis from a separate BEE FastAPI service with provider fallback (Ollama/Groq/Gemini).
- Keeps deterministic fallback behavior if ML is down.

## Operations and Risk Controls

- Admin control plane for wallet runtime config, risk tiers, fee configs, KYC reviews, withdrawal approvals.
- Financial events are audit-logged.
- Health/readiness endpoints and DB health checks are in place.

## 3. "What We Built" vs "What We Did Not Claim"

What to claim confidently:
- "We built the application-layer blockchain transaction engine and control plane."
- "We built ledger integrity, reconciliation flows, and operational controls."
- "We built the ranking/decisioning layer and optional AI enrichment."

What not to claim:
- "We built a new base-layer blockchain or novel consensus protocol."
- "We are fully trustless custody today."

## 4. High-Probability Investor Questions and Answers

Q: "Is this custodial or non-custodial?"
- A: "Currently custodial with institutional custody rails via Turnkey, optimized for UX and operational control."

Q: "How do you reduce financial operational risk?"
- A: "Idempotent transaction handling, serializable ledger mutations, explicit hold/finalize/revert states, confirmation-based settlement, and audit trails."

Q: "What is the commercialization path?"
- A: "Monetize via premium intelligence surfaces, platform/treasury economics, and B2B admin tooling extensions once user and project volume scales."

Q: "What breaks under scale first?"
- A: "Throughput bottlenecks in indexing/settlement workers and operational governance volume. We already have config-driven controls and clear paths for worker partitioning and queueing."

## 5. Suggested One-Slide Architecture Narrative

Title: "Blocnet Integrated Execution Stack"

Bullet structure:
1. User Experience: Mobile + Community + Mining + Wallet
2. Decision Intelligence: Edge scoring + AI enrichment
3. Financial Core: Custody + Ledger + On-chain settlement
4. Control Plane: Admin runtime config + KYC + risk + audit
5. Infrastructure: NestJS + Prisma/Postgres + BSC + ML microservice

