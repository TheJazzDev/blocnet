# Blocnet Feature Atlas

> Source of truth for **what exists** across mobile, console and backend, with a live-verified status.
> Produced 2026-09-11 from a code inventory + click-through of every reachable screen (account `claude-audit@blocnet.app`, branch `stage` @ `bb328fa`).
> Live, formatted version: https://claude.ai/code/artifact/0279da3b-3cb9-475b-a237-330e98e02614
> Findings and work tracking live in [`UX_UI_TRACKER.md`](UX_UI_TRACKER.md). Keep this file updated when a feature's status changes.

**Status key:** `live` reachable and working with real data · `partial` reachable but stubbed, mis-gated or visibly incomplete · `dead` code exists but nothing reaches it · `unverified` exists in code, not exercised yet.

---

## Mobile (Flutter) — 44 routes, 3 spaces

The app has three **spaces** (User, Hunter, Moderation) switched from the app-bar logo icon. Each space re-skins the accent (blue / cyan / red), swaps bottom-tab 2 (Community / Hunter Hub / Moderation) and swaps the Profile body.

### Auth & shell
| Feature | Status | Notes |
|---|---|---|
| Sign in / Sign up / Verify / Forgot / Reset | unverified | 5 routes; Supabase email + Google; referral on signup |
| Closed-alpha gate | unverified | `/public/closed-alpha/check` on boot |
| Space switcher | live | Bottom sheet from logo icon; cross-fade + blackout |
| Post-login prompts (hunter unlocked, referral) | unverified | Keyed per user in prefs |
| Deep links & FCM push | unverified | Token registers on boot |
| Offline banner / ConnectivityStore | dead | Fully commented out |

### Home tab
| Feature | Status | Notes |
|---|---|---|
| Updates feed (radar, edge card, top hunters, feed) | live | like / comment / bookmark / share |
| General tab + filter chips | partial | Trending works; High/Med/Low all open `PriorityScreens()` with no argument |
| Alpha Radar | live | "Loading alpha radar…" for seconds on cold start |
| Edge Engine page | partial | Empty card + 3 zero chips with no follow CTA |
| Global search | live | projects, updates, users |
| Notifications + category chips | live | Insights screen exists, no digest to open |
| Update detail | live | Tip Hunter CTA, comments; header count wrong (F-15) |
| Top Hunters + public profile sheet | live | follow / tip / block |

### Discover tab
| Feature | Status | Notes |
|---|---|---|
| Curated feed | live | hype score, Follow, hunted-by |
| Filters sheet | live | primary / secondary tag, priority |
| My Gems tab | live | empty for this account |
| Project detail | live | "Humber" typo (F-09) |
| Follow preferences per project | unverified | store wired, no UI seen |

### Community tab (User space)
| Feature | Status | Notes |
|---|---|---|
| General / Market Talk feeds | live | realtime via Supabase |
| Post discussion, create post | live | |
| Report content, My Reports | live | |
| Submit appeal | dead | `submit_appeal_screen.dart` imported nowhere |
| Community staff tools screen | dead | route never pushed |

### Mining tab
| Feature | Status | Notes |
|---|---|---|
| Dashboard, start / claim | live | |
| Leaderboard, hourly history | live | |
| Downline screen | dead | route never pushed |
| Referral code | partial | totals "…" forever — `/referrals/me` never called (F-03) |

### Wallet tab
| Feature | Status | Notes |
|---|---|---|
| Wallet home (pre-launch balance, address, assets) | live | |
| Receive | partial | opens BNT asset detail, not an address/QR view (F-06) |
| Send (internal transfer) | live | asset picker → `SendTokenPage` |
| Swap | partial | "in rollout" stub list |
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
| Levels | partial | ladder only, no requirements / progress (F-16) |
| Tip history | live | |
| Settings | live | layout, 7 notification categories, privacy |
| Deactivate account | partial | calls `/users/me/deactivate`, which does not exist |
| Help & Support | partial | 5 of 8 entries are "coming soon" |
| System Alerts | partial | shown to admin, API allows owner/dev only |
| Blocked users | live | |

### Hunter space
| Feature | Status | Notes |
|---|---|---|
| Hunter Hub | live | tip balance, success rate, ranking, elite card |
| Composer FAB (Post Update / Submit Gem) | live | tabs 0–2 only |
| Create Update | live | needs an assigned project |
| Submit New Gem | live | → console Project Proposals |
| Manage My Gems / Updates | live | |
| Hunter profile body | live | hides Badges / Quests / Levels / Activity |
| Become Hunter | dead | 454-line screen, no entry point |
| Project assignment invites | dead | no client for `/project-invites/*` |

### Moderation space
| Feature | Status | Notes |
|---|---|---|
| Moderation Hub | live | |
| Reports Queue ("Staff Tools"), Appeals Queue | live | |
| User Actions / History tiles | partial | "Coming Soon" snackbars |

---

## Console (Next.js admin) — 36 protected pages

All pages require owner / dev / admin + 2FA gate. Walked as **admin**.

| Page | Status | Notes |
|---|---|---|
| /dashboard | live | recent activity is page-view noise (F-13) |
| /edge-engine, /decision-engine, /ml-analysis, /settings | live | |
| /projects, /updates, /comments | live | status moderation with reason dialog |
| /community (Posts / Comments / Reports) | live | warn / mute / suspend / restrict |
| /applications | partial | proposals render full markdown inline (F-18); role apps owner-only |
| /tags | live | |
| /wallet-users, /wallet-withdrawals | live | |
| /wallet-kyc | partial | queue nothing can fill (F-28) |
| /wallet-settings | live | |
| /tips-transactions, /tip-settings | live | |
| /mining, /mining/leaderboard, /referrals | live | |
| /levels, /badges | live | dev role silently read-only (F-12) |
| /quests, /quest-submissions | live | dev role hard-blocked (F-12) |
| /users | live | |
| /users/[id] | partial | Activity, Projects, Social, Audit, Lifecycle are placeholders; "Unnamed User" header (F-05) |
| /closed-alpha, /console-access, /community-access, /roles | live | |
| /notifications | live | push + email broadcast |
| /audit-log | partial | Export permanently disabled |
| /ops-events | unverified | owner/dev; admin copy says "Owner role is required" |
| /social-credentials | unverified | owner; admin silently redirected |
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
