# Release Smoke Tests (Non-Wallet)

## Prerequisites
- Backend running on `http://localhost:3080`
- Admin running on `http://localhost:3081`
- Mobile app running with valid Supabase config

## Backend API
- [ ] `GET /api/health` returns status ok
- [ ] `GET /api/health/live` returns status ok
- [ ] `GET /api/health/ready` returns status ok and checks object

## Mobile Auth
- [ ] Sign in with valid credentials succeeds and opens main screen
- [ ] Sign out from settings/profile returns to sign-in screen
- [ ] Guest-only routes (`/signin`, `/signup`) redirect authenticated users to main

## Mobile Content Flows
- [ ] Open Discover and navigate to trending + priority routes
- [ ] Hunter role can open create/update/project management routes
- [ ] User role is blocked from hunter-only routes
- [ ] Community create post and discussion routes open correctly

## Admin Panel
- [ ] Unauthenticated access to `/dashboard` redirects to `/signin`
- [ ] Authenticated session can open dashboard, users, projects, applications, audit-log, settings
- [ ] Sign out clears session and protects routes again

## BEE (Edge Engine)
- [ ] `GET /api/me/edge/feed` returns ranked items and no 5xx
- [ ] `GET /api/me/edge/brief` returns headline + top decisions
- [ ] `GET /api/me/edge/explain/:decisionId` returns reason codes + components
- [ ] `POST /api/me/edge/feedback` persists feedback (`feedbackId` present when persistence is available)
- [ ] Admin can open `/edge-engine` and inspect a decision drilldown
- [ ] Mobile home can open “Why ranked?” drawer from BEE card

## Pass Criteria
- All checks above pass without runtime exceptions, blank screens, or 5xx API errors.
