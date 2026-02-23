# BEE Implementation Todo

Last updated: 2026-02-23

## Active Sprint: BEE V1 Backend Scaffold
- [x] Create living PRD document (`docs/BEE_PRD_V1.md`)
- [x] Add backend `edge-engine` module (controller/service/dto)
- [x] Implement `GET /api/me/edge/feed`
- [x] Implement `GET /api/me/edge/brief`
- [x] Implement `GET /api/me/edge/explain/:decisionId`
- [x] Implement `POST /api/me/edge/feedback`
- [x] Wire module into `backend/src/app.module.ts`
- [x] Add unit tests for score ordering and feedback path
- [x] Run targeted backend tests and capture results
- [x] Integrate mobile client repository/store for BEE endpoints
- [x] Integrate admin quality panel data source for BEE monitoring
- [x] Add dedicated mobile Edge explain drawer (`/me/edge/explain/:decisionId`)
- [x] Add admin edge decision drill-down with reason codes/components
- [x] Add first-class persistence for edge decisions/feedback (Prisma tables)
- [x] Add dedicated admin BEE page (`/edge-engine`) with feed/explain/feedback telemetry
- [x] Upgrade dashboard with stronger BEE/operations visibility and Edge control-room navigation
- [x] Run BEE V1 production-readiness pass and publish report (`docs/BEE_V1_READINESS_REPORT.md`)

## Next Sprint: Integration
- [x] Mobile edge feed UI contract integration (brief card + action feedback)
- [x] Admin edge quality panel contract integration (dashboard card)
- [ ] Add trust/source credibility layer
- [ ] Add AI summarizer/extractor pass
- [ ] Add migration runbook for applying BEE persistence migration in each environment
- [x] Build BEE V2 Sprint 1 global admin analytics endpoint (`GET /admin/edge/overview`)
- [ ] Build remaining BEE V2 global admin endpoints (`/admin/edge/*`) + override workflows

## Review Notes
- Keep V1 deterministic and explainable.
- Prefer minimal schema changes in first slice.
- Keep endpoint responses stable for mobile/admin adoption.
