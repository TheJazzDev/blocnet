# Production Readiness Checklist

## 1) Quality Gates
- [x] Mobile static analysis passes (`flutter analyze`)
- [x] Mobile test suite passes (`flutter test`)
- [x] Backend lint passes (`npm run lint`)
- [x] Backend unit tests pass (`npm test -- --runInBand`)
- [x] Backend e2e tests pass (`npm run test:e2e -- --runInBand`)
- [x] Backend build passes (`npm run build`)
- [x] Admin lint passes (`npm run lint`)
- [x] Landing page lint passes (`npm run lint`)
- [x] Landing page build passes offline-safe (`npm run build -- --webpack`)

## 2) Routing and Screen Integrity
- [x] Profile route points to profile tab
- [x] Settings route points to dedicated settings screen
- [x] Dead route constants removed (`hunterProfile`, `projectDetail`)
- [x] Role access tests aligned with `hunter` role

## 3) Refactor Baseline (No Behavior Change)
- [x] Main shell split into modular parts
- [x] User profile body split into modular parts
- [x] Hunter profile body split into modular parts
- [x] Wallet screen split into modular parts
- [x] Backend projects canonical logic extracted to dedicated module
- [x] Backend project/update response mappers extracted to dedicated modules

## 4) Platform Hardening
- [x] Admin middleware convention migrated to Next.js `proxy.ts`
- [x] Landing page fonts migrated from remote Google fetch to local bundled assets

## 5) Remaining Production Work (Functional)
- [ ] Replace wallet placeholder actions with implemented flows (send/receive/swap/buy)
- [ ] Add broader integration tests for project/update/proposal flows
- [ ] Add monitoring/alerting hooks (backend + admin)
- [ ] Add release smoke tests for auth, content creation, and notifications

## 6) Release Gate
Only ship when all items in sections 1-4 are complete and section 5 items are either complete or explicitly deferred with risk sign-off.
