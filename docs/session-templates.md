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
