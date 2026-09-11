# UX/UI Tracker

> Living checklist for the post-stabilization UX/UI pass. Replaces the retired Fix Ledger.
> Inventory lives in [`FEATURE_ATLAS.md`](FEATURE_ATLAS.md). Session prompts live in [`session-templates.md`](session-templates.md).
> **Rule:** every session that touches a finding updates its Status row and appends to the Session Log. Never delete rows; mark them `done` / `wontfix` / `deferred`.

Status values: `open` · `in-progress` · `done` · `deferred` (waiting on design system or a product decision) · `wontfix`.

---

## Workstreams

Parallel-safe splits. Each touches one surface so they can run as separate sessions / worktrees without conflicts. WS-D is decisions, not code. WS-E runs **after** A–C merge.

| WS | Name | Surface | Findings | Prompt |
|---|---|---|---|---|
| A | Mobile flows & copy | `mobile/` | F-02, F-03, F-06, F-09, F-15, F-17, F-19, F-21, F-22, F-24, F-27 | [session-templates.md#ws-a](session-templates.md#ws-a--mobile-flows--copy) |
| B | Backend contract fixes | `backend/` | F-DEACT, F-02 (system-alerts role), F-13 (view-event audit noise), F-03 (referrals/me exists — nothing to do server-side) | [session-templates.md#ws-b](session-templates.md#ws-b--backend-contract-fixes) |
| C | Console shell, layout & gating | `console/` | F-04, F-05, F-11, F-12, F-13, F-18, F-25, F-26, F-28 | [session-templates.md#ws-c](session-templates.md#ws-c--console-shell-layout--gating) |
| D | Product decisions | — | F-01, F-07, F-10, F-14, F-16, F-20 | discussed in-session, decisions logged below |
| E | Dead-code cleanup | all | dead-code register in the atlas (excluding screens WS-D may revive) | [session-templates.md#ws-e](session-templates.md#ws-e--dead-code-cleanup) |
| F | Mobile: spaces, hunter path, coming-soon, glossary | `mobile/` (after A merges) | F-01, F-10, F-16, F-20 (mobile half), F-07 (glossary + Gems/Projects/Updates copy) | [session-templates.md#ws-f](session-templates.md#ws-f--mobile-spaces-hunter-path-coming-soon-glossary) |
| G | Console: hunter assignment UI, MCR removal, vocabulary | `console/` (after C merges) | F-20 (console half), F-07 (MCR, `*Mcr` labels) | [session-templates.md#ws-g](session-templates.md#ws-g--console-hunter-assignment-mcr-removal) |
| H | Backend: MCR retirement, BNP/BNT naming | `backend/` (after B merges) | F-07 (MCR data migration, `*Mcr` → `*Bnp` DTO rename) | [session-templates.md#ws-h](session-templates.md#ws-h--backend-mcr-retirement) |

Deferred to the Claude Design system phase (do not spend effort now): F-14 typography scale, F-23 hunter hero copy density, visual-language alignment between console and mobile.

---

## Findings

| ID | P | Surface | Finding | WS | Status | Session / PR | Notes |
|---|---|---|---|---|---|---|---|
| F-01 | P1 | mobile | "Space" concept invisible; switcher is an unlabeled logo icon; Hunter profile hides Badges/Quests/Levels | F | open | | decided 2026-09-11: keep spaces, make explicit |
| F-02 | P1 | mobile | Raw exception strings shown (Hunter Hub tip sync, System Alerts role banner) | A + B | open | | A: friendly error copy; B: decide System Alerts roles |
| F-03 | P1 | mobile | Referral totals "…" forever — `/referrals/me` never called | A | open | | `referral_code_screen.dart`, `mining_store.dart` |
| F-04 | P1 | console | Layout scrolls sideways when a dropdown/tab opens | C | open | | `admin-shell/index.tsx`, users/[id] tabs |
| F-05 | P1 | console | Member detail half placeholder; "Unnamed User" header | C | open | | fallback to username; hide stub tabs or ship them |
| F-06 | P1 | mobile | Wallet Receive opens asset detail; Swap is a stub; "Pre-launch" unexplained | A | open | | `quick_actions.dart`, `swap_flow_screen.dart` |
| F-07 | P2 | cross | Vocabulary drift: Gems/Projects, Members/Users, BNP/BNT/MCR | F + G + H | open | | decided: reconcile Gems/Projects/Updates; glossary; MCR removed everywhere (legacy "Mine Credits" row in dev DB, 2 empty accounts, 0 tx; `*Mcr` fields in mining-admin/wallet-admin services + console types) |
| F-08 | P2 | mobile | Cold start ~7 s with no skeletons | A (stretch) | open | | use `/me/home-bootstrap` cache |
| F-09 | P2 | mobile | "Humber" typo on project detail | A | open | | `project_details_info.dart` |
| F-10 | P2 | mobile | Dead-end "coming soon" entries (Help & Support ×5, Moderation ×2) | F | open | | decided: hide until real; ship static FAQ + Getting Started |
| F-11 | P2 | console | Sidebar needs scrolling to reach half the nav | C | open | | collapsible groups or move role switcher |
| F-12 | P2 | console | Role gating disagrees with nav and copy (dev on quests/badges/levels; ops-events copy; social-creds silent redirect) | C | open | | one rule: hide what the role cannot open |
| F-13 | P2 | console | Recent activity / audit log dominated by page-view events; Export disabled | B + C | open | | B: stop auditing reads or tag them; C: filter + tooltip |
| F-14 | P2 | mobile | Body text small (49× fontSize 9–10); user comment "kinda tiny" | D | deferred | | design system defines the type scale |
| F-15 | P2 | mobile | Update detail "Comments 0" above real comments; Tip CTA above body | A | open | | `update_details_dialog.dart` |
| F-16 | P2 | mobile | Levels page shows no requirements/progress | F | open | | `/levels/me` already has progress |
| F-17 | P2 | mobile | High/Med/Low chips open the same `PriorityScreens()` | A | open | | pass level as route arg |
| F-18 | P2 | console | Project proposals render full markdown inline | C | open | | truncate + drawer |
| F-19 | P2 | mobile | Empty states with no next step (Edge page, Create Update, Hunter Hub zeros) | A | open | | |
| F-20 | P2 | cross | Hunter path has no beginning (Become Hunter dead, no assignment client) | F + G | open | | decided: wire Become Hunter (mobile), assign/invite UI (console), invite acceptance (mobile) |
| F-21 | P3 | mobile | System back on tab root quits app instantly | A | open | | `PopScope` + double-back or confirm |
| F-22 | P3 | mobile | Settings subtitle only describes notifications; "+11 more" unexpandable | A | open | | |
| F-23 | P3 | mobile | Hunter profile hero jargon for new hunters | — | deferred | | design system |
| F-24 | P3 | mobile | Discover hype score is an unlabeled decimal | A | open | | |
| F-25 | P3 | console | 11× `bg-gradient-to-*` (Tailwind v3) in shared UI | C | open | | rename to `bg-linear-to-*` |
| F-26 | P3 | console | "Stage" badge clipped under Next devtools | C | open | | move to header |
| F-27 | P3 | mobile | Count flashes and bare spinners | A (stretch) | open | | shared skeleton |
| F-28 | P3 | console | KYC review page is a queue that cannot fill | C | open | | empty state until a client can submit |
| F-DEACT | P1 | mobile+backend | Self-deactivate calls a path that does not exist | B | open | | move handler to `/me/deactivate` under `UsersController` |

---

## Decisions log

| Date | Decision | Affects |
|---|---|---|
| 2026-09-11 | Typography scale, hero copy density and console↔mobile visual alignment wait for the Claude Design system phase. | F-14, F-23 |
| 2026-09-11 | **Spaces stay**, but become explicit: labelled switcher chip, one-time explainer, one Profile body with role-aware sections so nothing disappears on switch. | F-01 |
| 2026-09-11 | **Vocabulary**: users *find Gems*, admins *create Projects*, hunters post *Updates* — reconcile so the same thing is never called two things in front of a user; add an in-app glossary. **BNP = Blocnet Point** (mined now), **BNT = Blocnet Token** (at launch; BNP converts to BNT). **MCR is discarded** — remove it from tip currencies, console tip settings and any seed. | F-07 |
| 2026-09-11 | **Hunter path**: wire Become Hunter on mobile (admin-applications backend exists), add assign/invite hunters UI on the console project page (project-assignments backend exists), add invite acceptance on mobile. | F-20 |
| 2026-09-11 | **Coming-soon entries are hidden until real.** Keep Email Support; ship a static FAQ + Getting Started page; remove Live Chat, Report a Bug, Account & Privacy, Moderation User Actions and History from the UI. | F-10 |
| 2026-09-11 | Execution: WS-A/B/C run as parallel worktree subagents from the coordinating session; docs are only edited by the coordinator. | all |

---

## Session log

| Date | Session | Workstream | What changed |
|---|---|---|---|
| 2026-09-11 | Audit | — | Feature atlas + 28 findings produced. No code changed. Artifact: https://claude.ai/code/artifact/0279da3b-3cb9-475b-a237-330e98e02614 |
