# Blocnet Feature Atlas

> Source of truth for **what exists** across mobile, console and backend, with a live-verified status.
> Produced 2026-09-11 morning from a code inventory + click-through of every reachable screen (account `claude-audit@blocnet.app`, branch `stage` @ `bb328fa`).
> Live, formatted version: https://claude.ai/code/artifact/0279da3b-3cb9-475b-a237-330e98e02614
> **Status column refreshed 2026-09-11 evening** after WS-A…J merged; rows marked ⟲ changed since the morning audit.
> Findings and work tracking live in [`UX_UI_TRACKER.md`](UX_UI_TRACKER.md). Keep this file updated when a feature's status changes.

**Status key:** `live` reachable and working with real data · `partial` reachable but stubbed, mis-gated or visibly incomplete · `dead` code exists but nothing reaches it · `unverified` exists in code, not exercised yet.

---

## Mobile (Flutter) — 44 routes, 3 spaces

The app has three **spaces** (User, Hunter, Moderation) switched from a labelled chip in the app bar (one-time explainer on first launch). Each space re-skins the accent, swaps bottom-tab 2 (Community / Hunter Hub / Moderation); the Profile body is shared and role-aware.

### Auth & shell
| Feature | Status | Notes |
|---|---|---|
| Sign in / Sign up / Verify / Forgot / Reset | unverified | 5 routes; Supabase email + Google; referral on signup |
| Closed-alpha gate | unverified | `/public/closed-alpha/check` on boot |
| Space switcher | live ⟲ | Labelled chip + explainer sheet (WS-F) |
| Post-login prompts (hunter unlocked, referral) | unverified | Keyed per user in prefs |
| Deep links & FCM push | unverified | Token registers on boot |
| Offline banner / ConnectivityStore | removed ⟲ | deleted by WS-E |

### Home tab
| Feature | Status | Notes |
|---|---|---|
| Updates feed (radar, edge card, top hunters, feed) | live | like / comment / bookmark / share |
| General tab + filter chips | live ⟲ | urgency level bound per route (WS-A) |
| Alpha Radar | live | cold-start cache in WS-J |
| Edge Engine page | live ⟲ | empty state with "Follow projects" CTA (WS-A) |
| Global search | live | projects, updates, users |
| Notifications + category chips | live | Insights screen exists, no digest to open |
| Update detail | live ⟲ | count fixed, Tip CTA below body (WS-A) |
| Top Hunters + public profile sheet | live | follow / tip / block |

### Discover tab
| Feature | Status | Notes |
|---|---|---|
| Curated feed | live | hype score, Follow, hunted-by |
| Filters sheet | live | primary / secondary tag, priority |
| My Gems tab | live | empty for this account |
| Gem detail | live ⟲ | typo fixed, Gems vocabulary (WS-A/F) |
| Follow preferences per project | unverified | store wired, no UI seen |

### Community tab (User space)
| Feature | Status | Notes |
|---|---|---|
| General / Market Talk feeds | live | realtime via Supabase |
| Post discussion, create post | live | |
| Report content, My Reports | live | |
| Submit appeal | removed ⟲ | screen deleted by WS-E; appeals still submittable via backend only |
| Community staff tools screen | removed ⟲ | deleted by WS-E |

### Mining tab
| Feature | Status | Notes |
|---|---|---|
| Dashboard, start / claim | live | |
| Leaderboard, hourly history | live | |
| Downline screen | removed ⟲ | deleted by WS-E |
| Referral code | live ⟲ | totals from `/referrals/me` (WS-A) |

### Wallet tab
| Feature | Status | Notes |
|---|---|---|
| Wallet home (pre-launch balance, address, assets) | live | |
| Receive | live ⟲ | address + QR + copy/share (WS-A) |
| Send (internal transfer) | live | asset picker → `SendTokenPage` |
| Swap | partial ⟲ | honest "not available yet" state (WS-A) |
| Asset detail / transactions | live | |
| Withdrawals | unverified | store wired, no entry point seen |
| KYC submission | dead | no mobile UI; console queue can never fill |

### Profile tab (User space)
| Feature | Status | Notes |
|---|---|---|
| Hero + Activity / Following / Saved | live | |
| Edit profile | live | |
| Badges gallery | live | 20 badges |
| Quests + detail | live | 9 quests |
| Levels | live ⟲ | tiers, requirements, progress (levels redesign) |
| Tip history | live | |
| Settings | live | layout, 7 notification categories, privacy |
| Deactivate account | live ⟲ | `POST /me/deactivate` (WS-A/B) |
| Help & Support | live ⟲ | FAQ, Getting Started, Glossary; dead ends removed (WS-F) |
| System Alerts | live ⟲ | row shown only to owner/dev (WS-A) |
| Blocked users | live | |

### Hunter space
| Feature | Status | Notes |
|---|---|---|
| Hunter Hub | live | tip balance, success rate, ranking, elite card |
| Composer FAB (Post Update / Submit Gem) | live | tabs 0–2 only |
| Create Update | live | needs an assigned project |
| Submit New Gem | live | → console Project Proposals |
| Manage My Gems / Updates | live | |
| Profile body | live ⟲ | single role-aware body; nothing hidden per space (WS-F) |
| Become Hunter | live ⟲ | reachable from Profile and composer; posts to admin-applications; status read from `/admin-applications/mine` (WS-F/I/J) |
| Project assignment invites | live ⟲ | Invites section in Hunter Hub (WS-F) |

### Moderation space
| Feature | Status | Notes |
|---|---|---|
| Moderation Hub | live | |
| Reports Queue ("Staff Tools"), Appeals Queue | live | |
| User Actions / History tiles | removed ⟲ | tiles removed (WS-F); sanctions remain console-only |

---

## Console (Next.js admin) — 36 protected pages

All pages require owner / dev / admin + 2FA gate. Walked as **admin**.

| Page | Status | Notes |
|---|---|---|
| /dashboard | live ⟲ | view events filtered by default (WS-C) |
| /edge-engine, /decision-engine, /ml-analysis, /settings | live | |
| /projects, /updates, /comments | live ⟲ | status moderation; /projects has "Manage hunters" sheet (WS-G) |
| /community (Posts / Comments / Reports) | live | warn / mute / suspend / restrict |
| /applications | live ⟲ | proposals clamped; "Owner review required" note (WS-C/G) |
| /tags | live | |
| /wallet-users, /wallet-withdrawals | live | |
| /wallet-kyc | partial ⟲ | explanatory empty state; still no client submits KYC |
| /wallet-settings | live | |
| /tips-transactions, /tip-settings | live ⟲ | MCR retired; BNP + BNT only (WS-G/H) |
| /mining, /mining/leaderboard, /referrals | live | |
| /levels, /badges | live ⟲ | `canManageGamification` (WS-C) |
| /quests, /quest-submissions | live ⟲ | same helper; nav hidden when not allowed (WS-C) |
| /users | live | |
| /users/[id] | partial ⟲ | stub tabs hidden behind a flag; header falls back to @username (WS-C) |
| /closed-alpha, /console-access, /community-access, /roles | live | |
| /notifications | live | push + email broadcast |
| /audit-log | live ⟲ | view filter toggle; Export has a tooltip (WS-C) |
| /ops-events | unverified ⟲ | copy fixed to "Owner or dev" (WS-C) |
| /social-credentials | unverified ⟲ | access-denied card instead of redirect (WS-C) |
| /settings | live | 6 runtime flags, 2FA |
| /signin + 2FA stages, /unsupported-device | unverified | |

---

## Backend (NestJS) — 34 feature modules, ~180 routes, 71 models

Everything is consumed by at least one client except:

| Capability | Status | Detail |
|---|---|---|
| Project assignments (5 routes) | consumed (console assign/invite/list, mobile invites) | wired 2026-09-11 by WS-F/WS-G |
| Wallet KYC submit / status | no client | |
| `GET /admin/social/overview` | no client | |
| `GET /referrals/me` | consumed (mobile) | wired 2026-09-11 by WS-A |
| `GET /levels/leaderboard`, `GET /wallet/health`, `DELETE /device-tokens/:id` | no client | |
| `EdgeEngagement` model + `EdgeAction` enum | orphan table | never written or read; dropping needs a migration and an explicit go-ahead |
| `TipConversion`, `TipFeeConfig` | write-less | read only; no admin editor for fee config |
| Self-deactivate / reactivate | live | `POST /me/deactivate`, `POST /me/reactivate` (WS-B) |

Background work: no cron/queue library — digest worker (5 min), wallet settlement + deposit indexer, config refreshers (15 s), one `level.up` listener. Runtime flags overridable from console: closedAlpha, alphaRadar, followPrefs, weeklyDigest, mining, referrals.

---

## Cross-surface ownership

| Domain | Mobile | Console | Backend | Gap |
|---|:-:|:-:|:-:|---|
| Projects | ✓ | ◐ | ✓ | console moderates only |
| Project proposals | ✓ | ✓ | ✓ | |
| Hunter onboarding & assignment | — | ◐ | ✓ | nobody can invite / assign |
| Updates + comments | ✓ | ◐ | ✓ | |
| Community posts | ✓ | ✓ | ✓ | |
| Community moderation actions | ◐ | ✓ | ✓ | mobile queues only |
| Appeals | ◐ | — | ✓ | nobody can submit |
| Edge engine | ✓ | ✓ | ✓ | |
| Wallet | ✓ | ✓ | ✓ | swap stub |
| Withdrawals | ◐ | ✓ | ✓ | no mobile entry point seen |
| KYC | — | ✓ | ✓ | queue never fills |
| Tips | ✓ | ✓ | ✓ | |
| Mining + referrals | ◐ | ✓ | ✓ | totals missing, downline dead |
| Levels | ◐ | ✓ | ✓ | no requirements on mobile |
| Badges, Quests | ✓ | ✓ | ✓ | |
| Notifications | ✓ | ✓ | ✓ | |
| Users, roles, governance | — | ✓ | ✓ | |
| Audit / ops / alerts | ◐ | ✓ | ✓ | role rules differ |
| Closed alpha, flags, 2FA, social creds | — | ✓ | ✓ | |
| Account deactivation | ◐ | ✓ | ◐ | mobile path broken |

---

## Dead code register

> Cleared 2026-09-11 by WS-E. Kept on purpose: alias routes `/home` `/discover` `/mining` (deep links), `level_progress_card.dart` (used by the levels redesign), `become_hunter_screen.dart` (wired by WS-F), `EdgeEngagement` table (needs a migration).

<details><summary>Original register (historical)</summary>

**Mobile:** `submit_appeal_screen.dart`, `become_hunter_screen.dart`, `mining_downline_screen.dart`, `community_staff_tools_screen.dart` (decide wire-or-delete); orphan stores `AppStore`, `AdminsStore`; commented `PriorityStore`, `ConnectivityStore`, offline banner; zero-import files `app/app.dart`, `tag_filter_utility.dart`, `custom_icon_button.dart`, `session_gateway.dart`, `auth/data/models/user.dart`, `level_progress_card.dart`, `referral_code_card.dart`, `your_projects_view_model.dart`, `bottom_sheet_filter_controller.dart`, `dot_divider.dart`, `toggle_button.dart`; alias routes `/home`, `/discover`, `/mining`.

**Console:** `shared/DataTable.tsx`, `shared/FiltersBar.tsx`, `shared/SearchInput.tsx`, `providers/auth-store-provider.tsx`, `edge-section-nav.tsx`, `mining/ReferralSupportCard.tsx`, `use-dashboard-data-v2.ts`; 17 stale migration docs at console root; dead `EnvironmentWatermark` import in `app/signin/page.tsx`.

**Backend:** `EdgeEngagement` + `EdgeAction`; the unconsumed routes above.

</details>
