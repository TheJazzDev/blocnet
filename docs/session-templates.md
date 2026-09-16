# Session Templates

> Human-facing. Prompts to paste at the start of a Claude Code session. State lives in [`UX_UI_TRACKER.md`](UX_UI_TRACKER.md) and [`FEATURE_ATLAS.md`](FEATURE_ATLAS.md).

## Template — continue a workstream

```
I'm continuing work on Blocnet. Read CLAUDE.md, then docs/UX_UI_TRACKER.md and docs/FEATURE_ATLAS.md to load current state.

Today's workstream: WS-<letter> (<name>). Work only on the findings assigned to it, in the files under <surface>/. Mark each finding in-progress when you start and done when verified, and append a Session Log row before you finish. Do not touch findings owned by another workstream.
```

## Template — full feature + UX audit (reusable on any project)

This is the prompt shape that produced the 2026-09-11 audit. The ingredients that matter are in bold in the notes below it.

```
This is a new phase, not bug-fixing. Two-part goal:

PHASE 1 — Full feature inventory.
Enumerate every feature across all surfaces: <surface 1: where routes/screens live>, <surface 2: where pages live>, <backend: the module list that is the source of truth>. Cross-reference each UI with the stores/hooks that back it and each backend module with the clients that call it, to catch anything with backend support that never got a UI, or vice versa.
Don't just grep — open the app(s) live (<emulator / browser>) and click through each feature to confirm what's real, what's scaffolded-but-unreachable, and what's dead code. Test accounts exist: <account>; ask me for the password rather than resetting it.
Produce a clean inventory: surface → feature → status (live / partial / dead) → one-line description.

PHASE 2 — Intuitive UX/UI review.
Go through the app the way a real first-time user would — not hunting for bugs, but judging feel: is the flow obvious, is anything confusing or inconsistent, does navigation make sense, is the visual design coherent surface-to-surface, does it meet <the project's own design rules, e.g. CLAUDE.md mobile-first rules>. Compare surfaces for the same feature where both exist and flag inconsistency.

Log everything in a fresh Artifact: inventory first, then a prioritized findings list. Don't start fixing anything yet — we'll decide priority and approach together.
```

Why this shape works:
- **Names the sources of truth** (router file, pages dir, module list) so the agent inventories from the code, not from memory.
- **Demands live verification** ("don't just grep — open it and click through") so status is observed, not inferred.
- **Asks for a status vocabulary** (live / partial / dead) which forces a judgement per feature instead of a list.
- **Asks for cross-referencing in both directions** (UI without backend, backend without UI), which is where dead features hide.
- **Separates inventory from review** and defines the reviewer's stance ("first-time user, feel not bugs") so findings are UX findings, not a second bug audit.
- **Points at the project's own rules** (CLAUDE.md) so compliance checks are concrete.
- **Says "don't fix yet"**, which keeps the whole session on observation and produces a complete picture before any change.
- Gives an existing test account and says how to handle credentials.

---

## Workstream kickoffs (2026-09-11 pass)

Each block is self-contained. Run them in parallel in separate sessions or worktrees; they touch different directories.

### WS-A — Mobile flows & copy

```
I'm continuing work on Blocnet. Read CLAUDE.md, then docs/UX_UI_TRACKER.md and docs/FEATURE_ATLAS.md.

Workstream WS-A (mobile/ only). Fix these findings, smallest first, one commit per finding:
- F-09 "Humber" → "Hunter" typo in project detail (project_details_info.dart, check for other occurrences).
- F-03 Referral Code screen: fetch GET /referrals/me on open and render totals; show 0, never "…".
- F-15 Update detail header comment count must match the rendered list; move the "Tip Hunter" CTA below the body.
- F-17 High/Medium/Low chips: pass the level into PriorityScreens (route argument) and filter accordingly.
- F-06 Wallet "Receive" must open a receive view (address + copy + QR) instead of asset detail; Swap stub gets a clear "not available yet" state instead of a list that goes nowhere; add one line under "Pre-launch" explaining what it means.
- F-02 Replace raw exception text in Hunter Hub tip cards with user copy ("Couldn't load tips. Tap to retry.") and log the exception instead. System Alerts: hide the menu row unless the user's roles include owner or dev (backend allows only those).
- F-19 Empty states: Edge Engine page gets a "Follow projects" button to Discover; Create Update explains how to get a project assigned; Hunter Hub zero stats lose the red "failure" styling when there is no data yet.
- F-21 Wrap the main shell in PopScope: on a tab root, first back shows "Press back again to exit" for 2 s; second back exits.
- F-22, F-24 copy fixes (Settings subtitle; label the Discover hype score).
Stretch if time remains: F-27 shared skeleton widget for list pages; F-08 render the cached home-bootstrap payload before the network resolves.

Rules: follow the existing store pattern (ChangeNotifier in lib/services). Keep files small; split widgets when a file passes ~300 lines. Run `flutter analyze` and `flutter test` before each commit. Update the tracker rows and add a Session Log entry. Do not touch backend/ or console/.
```

### WS-B — Backend contract fixes

```
I'm continuing work on Blocnet. Read CLAUDE.md, then docs/UX_UI_TRACKER.md and docs/FEATURE_ATLAS.md.

Workstream WS-B (backend/ only). Fix:
- F-DEACT Move the self-deactivate / reactivate handlers out of AdminUsersController into UsersController under `/me/deactivate` and `/me/reactivate` with AuthGuard only (any signed-in user may deactivate themselves). Keep the admin endpoints for admin-initiated deactivation. Mobile already calls `/users/me/deactivate` — coordinate: expose the new path AND leave a note in the tracker that mobile must switch to `/me/deactivate` (WS-A owner will do it) or accept both paths for one release.
- F-13 Stop writing audit-log rows for read-only admin views (`*.view` actions) OR tag them with a `kind: 'view'` field so the console can filter them. Prefer the tag; keep the data.
- F-02 Decide and document the System Alerts role rule: either open `/audit-log/system-alerts` to admin as well, or keep owner/dev. Record the decision in the tracker's Decisions log.
- Add a spec for each change. Run `bun run build` and `bun run test`.
If any change needs a Prisma field, go through `bunx prisma migrate dev --name <name>` against .env.local — never `db push`. Update the tracker and Session Log. Do not touch mobile/ or console/.
```

### WS-C — Console shell, layout & gating

```
I'm continuing work on Blocnet. Read CLAUDE.md and console/CLAUDE.md, then docs/UX_UI_TRACKER.md and docs/FEATURE_ATLAS.md.

Workstream WS-C (console/ only). Fix:
- F-04 The page scrolls horizontally when a Radix dropdown or tab receives focus (sidebar slides off-screen). Find the child wider than the viewport in the content column (suspects: the fixed "Stage" badge, a table without overflow-x-auto, the users/[id] tab bar) and fix it at the shell level so no page can overflow; verify on /projects row menu and /users/[id] tabs at 1372 px.
- F-05 users/[id]: header falls back to username when displayName is empty; hide the Activity, Social and System tabs and the Projects tiles until their data is implemented (or implement them — the TODOs list the queries). At 820 px the tab bar must not wrap into two misaligned rows.
- F-11 Sidebar: make nav groups collapsible with the current page's group open, and move "View As Role" into a compact popover so the scroll area is usable at 891 px height.
- F-12 One gating rule: use the `canMutate*` helpers on quests, quest-submissions, badges and levels (dev gets the same treatment as everywhere else); hide nav items the role cannot open; fix the ops-events copy ("Owner or dev role"); social-credentials shows an access-denied card instead of a silent redirect.
- F-13 Dashboard recent activity and Audit Log: filter out `*.view` events by default with a toggle; Export button gets a tooltip or is removed until CSV exists.
- F-18 Project proposals: truncate description to ~4 lines with "Show more" or open in a review sheet.
- F-25 Rename all `bg-gradient-to-*` to `bg-linear-to-*` (Tailwind v4). Check for any other v3 class names.
- F-26 Move the environment badge into the header next to the logo.
- F-28 wallet-kyc: when every row is "Not Submitted", show an explanatory empty state instead of live Approve/Reject buttons.
Mobile-first rules from CLAUDE.md apply to any new markup. Run `bun run lint`, `bun run test`, `bun run build`. Update the tracker and Session Log. Do not touch mobile/ or backend/.
```

### WS-E — Dead-code cleanup

```
I'm continuing work on Blocnet. Read docs/FEATURE_ATLAS.md, section "Dead code register", and docs/UX_UI_TRACKER.md.

Run this only after WS-A, WS-B and WS-C have merged. Delete the zero-import files and orphan stores listed for mobile and console, the 17 stale migration docs at console root, and the dead EnvironmentWatermark import. Do NOT delete become_hunter_screen.dart, submit_appeal_screen.dart, mining_downline_screen.dart or community_staff_tools_screen.dart — those wait on WS-D decisions. Do not drop the EdgeEngagement table without a migration and an explicit go-ahead. Verify with `flutter analyze`, console `bun run build`, backend `bun run build`. One commit per surface. Update the Session Log.
```

### WS-F — Mobile: spaces, hunter path, coming-soon, glossary

Run after WS-A has merged (it edits the same profile/hunter files).

```
I'm continuing work on Blocnet. Read CLAUDE.md, then docs/UX_UI_TRACKER.md (Decisions log first) and docs/FEATURE_ATLAS.md.

Workstream WS-F (mobile/ only). Implement the 2026-09-11 decisions:
- F-01 Spaces become explicit. Replace the bare logo icon in the app bar with a chip showing the current space name + icon (tap opens the existing switcher sheet). Add a one-time explainer sheet the first time a user has more than one space available ("You have two spaces: User for reading and community, Hunter for posting updates and managing gems"), keyed per user in prefs. Merge user_profile_body and hunter_profile_body into ONE profile body with role-aware sections: hero + Activity/Following/Saved for everyone; Hunter stats block and hunter shortcuts appear when the user is a hunter, regardless of active space. Nothing may disappear when switching space.
- F-20 Wire Become Hunter: make /become-hunter reachable from the User-space Profile ("Become a Hunter" row, hidden once the user has the hunter role or a pending application) and from the composer sheet for non-hunters. It submits POST /admin-applications with targetRole=hunter (backend exists). Add "My project invites": GET /project-invites/mine and PATCH /project-invites/:id/respond, shown in Hunter Hub "Manage My Projects" as an "Invites" section with Accept / Decline.
- F-10 Help & Support: remove Live Chat, Report a Bug and Account & Privacy rows; keep Email Support and Documentation; add static FAQ and Getting Started screens (markdown or simple widgets, content drafted from FEATURE_ATLAS.md — what Gems, Hunters, Updates, BNP and BNT are, how mining and quests work). Moderation Hub: remove the User Actions and History tiles.
- F-16 Levels page: show each level's requirements (BNP, comments, days active, quests, updates, projects — from GET /levels) and the user's progress toward the next level (GET /levels/me). The unused level_progress_card.dart is a starting point; delete it if you replace it.
- F-07 Vocabulary: users FIND Gems, admins CREATE Projects, hunters POST Updates. Audit every user-facing string in mobile/lib for "project" and decide per string whether the user is looking at a Gem (rename) or at admin/system wording (keep). Add a Glossary screen under Help (Gem, Hunter, Update, Alpha Radar, Edge brief, BNP = Blocnet Point mined now, BNT = Blocnet Token at launch, BNP converts to BNT). Remove any MCR string.

Rules: existing store pattern, small files, `flutter analyze` + `flutter test` green per commit, commit per finding with `WS-F F-xx:` prefix and the standard co-author trailer. Do not touch backend/ or console/. Report done/partial/skipped per finding with files and branch.
```

### WS-G — Console: hunter assignment, MCR removal

Run after WS-C has merged.

```
I'm continuing work on Blocnet. Read CLAUDE.md, console/CLAUDE.md, then docs/UX_UI_TRACKER.md (Decisions log first) and docs/FEATURE_ATLAS.md.

Workstream WS-G (console/ only):
- F-20 Hunter assignment UI. On /projects add a row action "Manage hunters" opening a Sheet that lists current hunters, lets an admin search members with the hunter role (GET /admin/users?role=hunter) and either Assign directly (POST /projects/:projectId/hunters/:hunterId/assign) or Invite (POST .../invite), and shows pending invites (GET /projects/:projectId/invites). Also surface hunter role applications: /applications › Role Applications already lists them; make Approve/Reject work for admins on hunter applications if the backend allows it, otherwise show who can approve.
- F-07 MCR removal: /tip-settings must not show MCR (filter by code and hide "MCR" everywhere); rename user-facing labels "MCR/hour" → "BNP/hour" (users/[id] MiningSection) and any other MCR text. Keep reading the API fields (`lifetimeMinedMcr` etc.) until WS-H renames them; centralize the mapping in one adapter so the rename is a one-line change.
- F-07 vocabulary: console keeps "Projects", "Updates", "Members". Add a small "Gems = Projects as users see them" hint in the Projects page header description.

Mobile-first Tailwind v4 rules apply. Split components past ~300 lines. `bun run lint && bun run test && bun run build` per commit, `WS-G F-xx:` prefix, standard co-author trailer. Do not touch mobile/ or backend/. Report per finding with files and branch.
```

### WS-H — Backend: MCR retirement

Run after WS-B has merged.

```
I'm continuing work on Blocnet. Read CLAUDE.md, then docs/UX_UI_TRACKER.md (Decisions log first) and docs/FEATURE_ATLAS.md.

Workstream WS-H (backend/ only). MCR ("Mine Credits") is discarded; BNP = Blocnet Point, BNT = Blocnet Token.
1. Data: the dev DB has a TipCurrency row code=MCR with 2 TipAccount rows and 0 TipTransaction rows; it is NOT in prisma/seed.ts or seed.dev.ts. Write a Prisma migration via `bunx prisma migrate dev --name retire_mcr_tip_currency` whose SQL deletes TipAccount rows for currencyCode='MCR' only where no TipTransaction references them, then deletes the TipCurrency row. Guard so it is a no-op when MCR is absent (prod). Never `db push`.
2. Guard the API: tips-admin settings endpoints reject creating/enabling a currency with code MCR; `GET /admin/tips/settings` never returns it.
3. Naming: rename `lifetimeMinedMcr / lifetimeClaimedMcr / lifetimeUnclaimedMcr` to `...Bnp` in mining-admin.service.ts, wallet-admin.service.ts and their DTOs, and the `mcr` local in notification-events.service.ts. Keep the old field names in responses for one release as deprecated aliases so the console (WS-G) can switch without breaking; note the removal date in the tracker report.
4. Add a short comment block at the top of the tips module documenting BNP vs BNT and the planned BNP→BNT conversion at launch (no conversion code yet).
`bun run build && bun run test` per commit, `WS-H F-07:` prefix, standard co-author trailer. Do not touch mobile/ or console/. Report with the migration file name and the response shape changes.
```

## Workstream kickoffs — mining (2026-09-16 pass)

S1, S2, S3 and S5 can run in parallel right now, each in its own worktree. S4 starts its store half now and its UI half once the Mine design is approved in Claude Design (`docs/design-briefs/mine.md`). Merge order: S1 first (it owns the migration and the config DTO), then S2 and S3, then S4 and S5.

### WS-S1 — Backend mining integrity

```
I'm continuing work on Blocnet. Read CLAUDE.md, then docs/UX_UI_TRACKER.md (findings F-44…F-62) and backend/src/mining + backend/src/referrals in full.

Workstream S1 (backend/ only). Fix, one commit per finding, tests first for each:
- F-44 P0 double start. Add a partial unique index allowing one unsettled MiningSession per user (claimedAt IS NULL AND expiredAt IS NULL) via `bunx prisma migrate dev --name mining_one_unsettled_session` (raw SQL in the migration; Prisma can't express partial indexes — document it in schema.prisma). Before creating the migration, query the dev DB for existing violators. Make `start()` and `ensureNextSessionState()` create inside a transaction and treat P2002 as "already running" (return the running session, 200). Either wire the unused `idempotencyKey` DTOs or delete them. Write a test that fires two starts concurrently.
- F-45 hourly checkpoint insert: use createMany with skipDuplicates (or catch P2002) so concurrent GET /mining/me never 500s.
- F-46 remove `email` from the user-facing `/referrals/downline` response (select and DTO). Add a simple per-IP throttle to `/referrals/validate` (check if @nestjs/throttler is already a dependency; if not, a small in-memory guard is fine).
- F-47 backend half: add `claimWindowHours` (Min 1, Max 168) to UpdateMiningConfigDto. Make GET /admin/mining/config return the raw stored row values plus separate `runtimeFlags: {miningEnabled, referralsEnabled}` so a save can never persist flag-ANDed values. Coordinate the shape change in the tracker for S3.
- F-48 rounding: pay the per-cycle remainder in the final hourly checkpoint so a cycle always totals exactly floor(base*(10000+boost)/10000). Test 0–4 active referrals at base 120/24h.
- F-50 one definition of active referral: "started a mining cycle in the last activeReferralWindowHours". Put it in one helper and use it for the boost, /referrals/me, downline and admin metrics.
- F-51 when mining is disabled: block start and auto-start (already), keep claim open so nobody loses points, and return `config.enabled=false` so clients can show a paused state. Record this decision in the Decisions log.
- F-52 quest BNP rewards must also credit the BNP tip account through the same helper the claim settlement uses.
- F-61 backend half: leaderboard excludes members with 0 claimed and 0 unclaimed points; add an index on Profile.miningClaimedPoints (same migration as F-44 is fine).
Rules: never `prisma db push`; commit schema + migration together. Run `bun run build` and `bun run test` before each commit. Update tracker rows + Session Log. Don't touch mobile/ or console/.
```

### WS-S2 — Backend mining reminders

```
I'm continuing work on Blocnet. Read CLAUDE.md, docs/UX_UI_TRACKER.md (F-49), backend/src/notifications and backend/src/mining (mining-expiry.service.ts, mining-settlement.ts).

Workstream S2 (backend/ only; new files preferred to avoid conflicts with S1). Build F-49:
- Two new notification types in the `mining_referrals` category: `mining_cycle_ready` ("Your BNP is ready — claim {n} BNP") and `mining_claim_expiring` ("{n} BNP expires in {h} hours — claim now"). Enum change goes through `bunx prisma migrate dev --name mining_reminder_notification_types`.
- A scheduler: the backend has no cron library — follow the existing interval-worker pattern (see the digest worker) with a 5-minute sweep. Cycle-ready fires once per session after endsAt; expiring fires once when ≤6h of the claim window remain. Dedupe with the existing dedupeKey mechanism so restarts and multiple instances never double-send (prove it with a test).
- Respect notification preferences; push via the existing FCM path. Deep link to /mining.
- The sweep must also settle expired cycles (call MiningExpiryService) so forfeits no longer depend on the user opening the app.
Add a mobile note in the tracker for S4: route both new types to the Mine tab (notification_target_resolver.dart).
Run build + tests; update tracker + Session Log. Don't touch mobile/ or console/.
```

### WS-S3 — Console mining admin

```
I'm continuing work on Blocnet. Read CLAUDE.md, console/CLAUDE.md, docs/UX_UI_TRACKER.md (F-47, F-56) and console/components/features/mining.

Workstream S3 (console/ plus the one status fix in backend/src/users-admin). Fix:
- F-47 console half: the config form sends only the fields the admin changed; show and edit `claimWindowHours`; show runtime flags read-only with a link to Settings (S1 is changing GET config to return raw values + `runtimeFlags` — check the tracker/S1 branch for the final shape). Move the page's data loading onto TanStack Query (use-mining-query.ts already exists), per console/CLAUDE.md.
- F-56: session status in users-admin.service.ts must consider `expiredAt` and the claim window (reuse the mining module's isClaimable predicate); add "expired" to the MiningSection status type and badge. Gate /mining on a mining/admin capability, not canMutateWallet. Label lifetime totals as lifetime, only 24h metrics as "Rolling 24h". Show the config change history from the audit log (mining config actions).
- Stretch (only if time remains, backend endpoint needed — coordinate with S1 in the tracker): full per-user session history with pagination.
Tailwind v4 + mobile-first rules from CLAUDE.md apply. Run `bun run lint`, `bun run test`, `bun run build`. Update tracker + Session Log.
```

### WS-S4 — Mobile Mine rebuild

```
I'm continuing work on Blocnet. Read CLAUDE.md, docs/PROGRESS.md §4b, docs/design-briefs/NEXT_SESSION.md (the build method is non-negotiable), docs/UX_UI_TRACKER.md (F-53…F-62), docs/design-briefs/mine.md, and lib/features/mining + lib/services/engagement/mining_store.dart.

Workstream S4 (mobile/ only). Two phases.

Phase 1 — now, no design needed:
- F-54: clear MiningStore on sign-out; split `_lastError` per request (snapshot / leaderboard / downline); stop fetching downline on every refresh (fetch it on the referral view only); make the 409 friendly copy reachable (prefer the error `code` over the message).
- F-53: read `config.enabled` and show a paused state with no Start; first-load failure shows error + retry, never a default idle card; use `config.cycleHours` instead of defaulting to 24.
- Countdown: offset the device clock by server `asOf`; refetch once when a cycle reaches its end; pause the 1 s ticker when the tab is not visible; refresh the snapshot on app resume.
- MiningStartResult.unknown() must not report success; a claim with missing status must not default to 'claimed'.
- Referral bind sheet: check the sheet's own mounted state; dispose its controller. Don't mark the first-launch referral prompt as seen when the snapshot load failed.
- Route the S2 notification types (mining_cycle_ready, mining_claim_expiring) to the Mine tab.
- F-62: give every bottom-bar tab a semantic label; check the stale-semantics symptom with TalkBack and fix it if it's real.
Widget tests for the hero states (idle / running / claimable / expired / paused / error).

Phase 2 — after the owner approves the Mine canvas in Claude Design:
Extract every state's element order from the approved design file first, then build to those lists. Rebuild rather than adapt. Merge the referral screen into Mine (keep /referral-code as an alias route), remove Mining Power and the duplicate Total Earned tile, add the leaderboard preview with a pinned own row + pagination on the full board, and the three-state hourly history. Walk every state on the emulator against the list before calling it done.
Rules: ChangeNotifier store pattern, files under ~300 lines, design tokens in lib/app/tokens. `flutter analyze` + `flutter test` before each commit. Update tracker + Session Log.
```

### WS-S5 — Wallet BNP row

```
I'm continuing work on Blocnet. Read CLAUDE.md, docs/UX_UI_TRACKER.md (F-59), backend/src/wallet (summary/assets), backend/src/tips (BNP tip account, tip.constants.ts BNP_CURRENCY_CODE), and mobile/lib/features/wallet.

Workstream S5. Mined BNP is credited to the BNP tip account (1 BNP = 1000 atomic units, see mining-settlement.ts) but the Wallet asset list shows only BNT, BNB, USDT. Find why BNP is missing (asset registry? summary query? mobile filter?), and make the Wallet show a BNP row with the in-app balance, labelled as in-app points that convert to BNT at launch — no USD price. Tapping it opens asset detail with mining claims and tips as transactions. Balance string stays BigInt-safe end to end. Tests on both sides; update tracker + Session Log.
```
