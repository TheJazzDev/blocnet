# Blocnet Edge Engine (BEE): One-Page PRD (V1)

Last updated: 2026-02-23
Owner: Product + Backend
Status: V1 Ready for Staged Rollout

## 1) Product Definition
`Blocnet Edge Engine (BEE)` is the intelligence layer that converts noisy crypto signals into personalized, action-ready decisions.

Positioning:
- See what matters first.
- Act before the crowd.

## 2) Problem
Users miss high-impact updates because feeds prioritize volume and engagement over outcome-critical timing.

## 3) Users
- Users/followers who need clear action on project signals.
- Hunters/contributors who publish time-sensitive updates.
- Admin/moderation teams who need quality and trust control.

## 4) V1 Scope
- Personal Edge Feed (`/api/me/edge/feed`)
- Edge Brief (`/api/me/edge/brief`)
- Explainability (`/api/me/edge/explain/:decisionId`)
- Feedback loop (`/api/me/edge/feedback` with `act|watch|ignore`)
- Deterministic scoring baseline over existing data (no heavy LLM dependency for first shipping slice)

## 5) Non-Goals (V1)
- Auto-trading or execution of financial actions
- Fully autonomous moderation
- Black-box ranking without reason codes

## 6) V1 Ranking Baseline
Score formula (initial deterministic baseline):

`EdgeScore = 0.35*Urgency + 0.30*Recency + 0.20*Relevance + 0.15*Novelty - Penalties`

Where:
- `Urgency`: derived from update urgency enum (`high|medium|low`)
- `Recency`: time decay by creation time
- `Relevance`: followed-project affinity and matching interest tags (next iteration)
- `Novelty`: reduce repeated stale/duplicate exposure
- `Penalties`: hidden/moderated/risky items or low confidence (later trust layer)

## 7) Success Metrics
- Missed high-urgency events per active user decreases by 40%
- Time-to-aware decreases by 50%
- `Act/Watch` response rate above 25%
- Feed trust rating above 4.2/5

## 8) Delivery Workflow Guardrails
Use this as operating rules while building BEE:
- Plan first for non-trivial work (`tasks/todo.md`)
- Verify before marking done (tests + endpoint checks)
- Keep changes minimal and reversible
- Capture corrections and lessons (`tasks/lessons.md`)

## 9) Current Program State
Start point (before BEE):
- Existing components: radar (`/api/me/radar`), digest (`/api/me/digest/summary`), notifications, updates, follows.
- Gap: no dedicated per-user decision feed with explainability and action feedback.

Current implementation status:
- Phase 1 backend scaffold completed:
  - `GET /api/me/edge/feed`
  - `GET /api/me/edge/brief`
  - `GET /api/me/edge/explain/:decisionId`
  - `POST /api/me/edge/feedback`
- Deterministic scoring baseline implemented with explainability fields.
- Unit tests passing for feed ranking, explain payload, and feedback audit path.
- Mobile integration added:
  - BEE repository + store
  - Home feed Edge brief card
  - `Act/Watch/Ignore` feedback actions from UI
  - Feed ordering now uses BEE score when available
  - "Why ranked?" drawer wired to `/api/me/edge/explain/:decisionId`
- Admin integration added:
  - Dashboard Edge Engine card consuming `/api/me/edge/brief`
  - Top decision preview for quick quality validation
  - Decision drill-down now shows reason codes and score components
  - Dedicated admin page at `/edge-engine` with:
    - Ranked decision control room (`/api/me/edge/feed`)
    - Explainability inspector (`/api/me/edge/explain/:decisionId`)
    - QA feedback controls (`/api/me/edge/feedback`)
    - Audit-driven telemetry panel for feed/brief/explain/feedback events
  - Dashboard upgraded from snapshot to operations-focused BEE visibility with direct link to Edge control room
- Persistence upgrade added:
  - `EdgeDecision` and `EdgeFeedback` first-class persistence tables
  - Feedback now writes to persistent storage (not audit-only)
  - Explain endpoint resolves from persisted decisions first, then computes fallback

Where we are going next:
1. Ship deterministic BEE endpoints.
2. Integrate mobile Edge cards + actions.
3. Add admin quality/override workflows.
4. Add AI extraction/reranking and trust graph.

## 10) Platform Impact (Mobile, Admin, Backend)
### Mobile impact
- New Edge feed section with ranked cards
- New action controls: `Act`, `Watch`, `Ignore`
- New "Why this is ranked" drill-down
- Reuses existing update detail routes and notification deeplinks

### Admin impact
- New Edge quality panel (phase 2) to inspect ranking decisions
- Override/downrank capability for risky or misleading decisions
- Monitoring for false positives and source reliability drift

### Backend impact
- New `edge-engine` module and DTO contract
- Candidate retrieval from existing updates/follows
- Deterministic ranking service now; AI enrichers later
- Feedback ingestion for online/offline ranking improvement
- Auditability for explainability and moderation alignment

## 11) API Contract (V1)
- `GET /api/me/edge/feed?limit=<n>&cursor=<token>`
- `GET /api/me/edge/brief?windowDays=<n>`
- `GET /api/me/edge/explain/:decisionId`
- `POST /api/me/edge/feedback`

Request example (`POST /api/me/edge/feedback`):
```json
{
  "decisionId": "edge:update:<updateId>",
  "action": "watch",
  "context": {
    "surface": "home_edge_feed"
  }
}
```

## 12) Change Log
### 2026-02-23
- Created initial PRD and living tracking structure.
- Implemented backend `edge-engine` module and wired into app module.
- Added `ENABLE_BEE` feature flag in env validation and `.env.example`.
- Added unit tests (`backend/src/edge-engine/edge-engine.service.spec.ts`) and passed targeted test run.
- Added mobile BEE models/repository/store and integrated home Edge brief card/actions.
- Added admin dashboard BEE brief card and API client support.
- Added Prisma BEE persistence models + migration (`EdgeDecision`, `EdgeFeedback`) and wired backend writes.
- Added mobile "Why ranked?" explain sheet and admin decision drill-down panel.
- Added dedicated admin BEE control room page and expanded dashboard operations/BEE telemetry.
- Added BEE V1 readiness report (`docs/BEE_V1_READINESS_REPORT.md`) and completed BEE-focused quality gate.
- Started BEE V2 Sprint 1 with first global admin analytics endpoint: `GET /api/admin/edge/overview`.

## 13) BEE V2 Direction
V2 objective: move from deterministic ranking to adaptive intelligence + governance controls.

Planned V2 capabilities:
1. Trust/Credibility Layer
- Source reliability scoring per project/update stream
- Penalties for misinformation patterns and moderation signals
- Confidence score exposed in explain payloads

2. AI Enrichment Layer
- LLM-assisted signal extraction from update content (event type, impact, urgency hints)
- Embedding-based relevance matching between user interests and updates
- Better narrative explanations with consistent reason-code alignment

3. Ranking Learning Loop
- Feedback-driven reweighting from `act/watch/ignore` outcomes
- Online calibration of thresholds per user segment
- Drift monitoring and periodic weight reset/guardrails

4. Admin Governance Controls
- Global `/admin/edge/*` endpoints (cross-user analytics, not user-scoped only)
- Override/downrank actions with full audit trail
- Policy rules for high-risk categories and escalation workflows

5. Experimentation + Quality
- A/B testing framework for ranker versions
- Quality dashboards (precision/recall proxies, trust rating trends)
- Canary rollout playbook with automated rollback signals
