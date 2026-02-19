# Blocnet MVP Audit Snapshot
_Last updated: 2026-02-19_

This file exists so Claude Code can quickly understand the state of all three layers
without re-auditing the full codebase. Update relevant sections when making significant changes.

---

## Backend (`/backend`) — NestJS + Prisma 7 + Supabase Postgres

**Status: Production-ready**

### Modules & Endpoint Count
| Module | Endpoints | Notes |
|--------|-----------|-------|
| auth | 1 | `POST /auth/session/verify` — verifies Supabase JWT, upserts profile, returns `{ user: { id, email, roles } }` |
| health | 3 | `GET /health`, `/health/live`, `/health/ready` |
| users | 7 | `GET/PATCH /me`, public profiles, watchlist, bookmarks, activity |
| projects | 4 | 2 public (list, get), 2 protected (create, delete) |
| updates | 4 | 2 public, 2 protected |
| comments | 4 | 1 public, 3 protected |
| project-assignments | 6 | Hunter assignment CRUD — hunter/admin/owner only |
| project-proposals | 4 | Submit + admin review |
| follows | 2 | Follow/unfollow project |
| notifications | 2 | List + mark read |
| device-tokens | 2 | FCM token register/delete |
| admin-applications | 3 | Apply + owner review |
| community | 9 | Posts, comments, reactions, bookmarks |
| admin-content | 10 | Moderation endpoints for projects/updates/comments/community |
| tags | 6 | 2 public (list primary/secondary), 4 protected (CRUD) |
| roles | 6 | Promote/demote admin/moderator/hunter |
| audit-log | 1 | `GET /audit-log` |

**Total: 70+ endpoints**

### Auth & RBAC
- `AuthGuard` validates Supabase JWT (JWKS)
- `RolesGuard` checks `@Roles()` decorator
- Role hierarchy: `owner > admin > moderator > hunter > user`
- `@CurrentUser()` injects authenticated user

### Database (17 tables)
Profile, Project, Update, Comment, CommunityPost, ProjectHunter, ProjectHunterInvite,
ProjectFollow, ProjectProposal, ProjectProposalStatus, PrimaryTag, SecondaryTag,
ProjectSecondaryTag, UpdateSecondaryTag, Notification, DeviceToken, AdminApplication,
AuditLog, UserRole

### Required Env Vars
```
DATABASE_URL         # Supabase pooled (port 6543, pgbouncer=true)
DIRECT_URL           # Supabase direct (port 5432) — used by prisma migrate
SUPABASE_URL         # https://xxxx.supabase.co
SUPABASE_JWKS_URL    # https://xxxx.supabase.co/auth/v1/.well-known/jwks.json
PUBLISHABLE_KEY      # Supabase anon key
FIREBASE_PROJECT_ID
FIREBASE_CLIENT_EMAIL
FIREBASE_PRIVATE_KEY
NODE_ENV             # production
CORS_ORIGINS         # comma-separated deployed URLs
PORT                 # injected by Railway automatically
```

### Deployment
- Hosted on Railway (dev environment)
- Dockerfile: multi-stage, oven/bun:1.2 builder → oven/bun:1.2-slim runner
- CMD: `bunx prisma migrate deploy && node dist/src/main`
- Build output: `dist/src/main.js` (not `dist/main.js`)
- `prisma.config.ts` must be in runner stage (copied in Dockerfile)

### Seed Scripts
- `bun run prisma:seed` → production seed (tags only, safe to run on prod)
- `bun run prisma:seed:dev` → dev seed (fake users, projects, updates, follows)

---

## Mobile (`/mobile`) — Flutter + Provider + Supabase Auth

**Status: MVP-ready (wallet screen is UI-only placeholder)**

### API Client
- File: `lib/services/api/api_client.dart`
- Base URL: `http://localhost:3080/api` (override with `--dart-define=API_BASE_URL=...`)
- Android emulator: `http://10.0.2.2:3080/api`
- Auth: Bearer token auto-injected after login
- Timeout: 15 seconds

### All API Endpoints Called
| Endpoint | Used by |
|----------|---------|
| `POST /auth/session/verify` | AuthStore |
| `GET /me` | AuthStore |
| `PATCH /me` | ProfileRepository |
| `GET /me/watchlist` | UserProfileStore |
| `GET /me/bookmarks` | UserProfileStore |
| `GET /me/activity` | UserProfileStore |
| `GET /projects` | ProjectsStore |
| `GET /projects/:id` | ProjectsStore |
| `POST /projects` | ProjectsRepository |
| `DELETE /projects/:id` | ProjectsRepository |
| `GET /projects/:id/updates` | UpdatesStore |
| `POST /projects/:id/updates` | UpdatesRepository |
| `PATCH /updates/:id` | UpdatesRepository |
| `GET /updates/:id/comments` | CommentsStore |
| `POST /updates/:id/comments` | CommentsRepository |
| `PATCH /comments/:id` | CommentsRepository |
| `DELETE /comments/:id` | CommentsRepository |
| `POST /projects/:id/follow` | ProjectsStore |
| `DELETE /projects/:id/follow` | ProjectsStore |
| `GET /notifications` | NotificationsStore |
| `PATCH /notifications/:id/read` | NotificationsStore |
| `POST /device-tokens` | AuthStore |
| `DELETE /device-tokens/:token` | AuthStore |
| `GET /tags/primary` | TagsStore |
| `GET /tags/secondary` | TagsStore |
| `POST /project-proposals` | ProposalsRepository |
| `GET /community-posts` | CommunityPostsStore |
| `POST /community-posts` | CommunityPostsRepository |
| `POST /community-posts/:id/reactions` | CommunityPostsRepository |
| `POST /community-posts/:id/bookmarks` | CommunityPostsRepository |
| `GET /community-posts/:id/comments` | CommunityPostsRepository |
| `POST /community-posts/:id/comments` | CommunityPostsRepository |

### Screens & Routes
| Route | Screen | Access |
|-------|--------|--------|
| `/signin` | SignInScreen | Guest |
| `/signup` | SignUpScreen | Guest |
| `/verify-email` | VerifyEmailScreen | Guest |
| `/forgot-password` | ForgotPasswordScreen | Guest |
| `/reset-password` | ResetPasswordScreen | Guest |
| `/main` | MainScreen (5-tab nav) | Auth |
| `/home` | HomeScreen | Auth |
| `/discover` | DiscoverScreen | Auth |
| `/notifications` | NotificationsScreen | Auth |
| `/wallet` | WalletScreen (UI only) | Auth |
| `/profile` | ProfileScreen | Auth |
| `/settings` | SettingsScreen | Auth |
| `/edit-profile` | EditProfileScreen | Auth |
| `/trending` | TrendingScreen | Auth |
| `/submit-project` | SubmitProjectScreen | Hunter+ |
| `/create-update` | CreateUpdateScreen | Hunter+ |
| `/manage-projects` | ManageProjectsScreen | Hunter+ |
| `/manage-updates` | ManageUpdatesScreen | Hunter+ |
| `/hunter-hub` | HunterHubScreen | Hunter+ |
| `/become-hunter` | BecomeHunterScreen | Auth |
| `/community-create-post` | CommunityCreatePostScreen | Auth |
| `/community-discussion` | CommunityPostDiscussionScreen | Auth |

### State Management (Provider stores)
AuthStore, ProjectsStore, UpdatesStore, CommentsStore, CommunityPostsStore,
NotificationsStore, UserProfileStore, TagsStore, PriorityStore, AdminsStore, AppStore

### AuthStore — Fields after login
```
isAuthenticated, accessToken, userId, email, displayName, avatarUrl,
bio, username, memberSince, roles, activeSpace ('user' | 'hunter')
```

### Permission getters
```
canCreateUpdate     = owner || admin || hunter
canSubmitProject    = owner || admin || hunter
canModerateRoles    = owner || admin
hasHunterSpace      = owner || admin || hunter
```

### Known gaps (not blockers for MVP)
- Wallet screen: UI placeholder only, no backend integration
- No real-time notifications (polling only)
- No image upload (URL entry only)

---

## Admin Panel (`/admin`) — Next.js 16 + Tailwind v4 + Supabase Auth

**Status: MVP-ready (settings mutations and audit export are intentionally stubbed)**

### Pages
| Route | Purpose | Status |
|-------|---------|--------|
| `/signin` | Supabase login with role check | Complete |
| `/dashboard` | Stats, recent activity, health | Complete |
| `/projects` | Moderate project status | Complete |
| `/updates` | Moderate update status | Complete |
| `/comments` | Moderate comments | Complete |
| `/community` | Moderate community posts + comments | Complete |
| `/users` | Manage users, promote/demote roles | Complete |
| `/applications` | Review admin apps + project proposals | Complete |
| `/audit-log` | View audit trail | Complete |
| `/tags` | CRUD primary + secondary tags | Complete |
| `/settings` | Env diagnostics (save button disabled) | Partial |

### Auth Flow
1. Supabase `signInWithPassword()` → verify role via `GET /me`
2. Token stored in httpOnly cookie (`admin_token`)
3. Server components use `cookies()`, client components parse `document.cookie`
4. Middleware redirects unauthenticated requests to `/signin`

### RBAC Gates
```
canAccessAdminPanel       = owner | admin | moderator
canManageAdmins           = owner
canManageModerators       = owner | admin
canManageHunters          = owner | admin
canReviewAdminApplications = owner
canReviewProjectProposals  = owner | admin | moderator
canManageTags             = owner | admin
canMutateSettings         = owner
```

### Required Env Vars
```
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_PUBLISHABLE_KEY
NEXT_PUBLIC_API_URL    # https://your-backend.railway.app/api in production
```

### Backend Endpoints Used
All `/admin/content/*`, `/admin/users/*`, `/roles/*`, `/tags/*`,
`/admin-applications/*`, `/project-proposals/*`, `/audit-log`, `/me`

---

## Cross-Layer Sync Status

| Feature | Backend | Mobile | Admin | In Sync? |
|---------|---------|--------|-------|----------|
| Auth (Supabase JWT) | ✓ | ✓ | ✓ | ✓ |
| Projects CRUD | ✓ | ✓ | ✓ (moderation) | ✓ |
| Updates CRUD | ✓ | ✓ | ✓ (moderation) | ✓ |
| Comments | ✓ | ✓ | ✓ (moderation) | ✓ |
| Community posts | ✓ | ✓ | ✓ (moderation) | ✓ |
| Tags | ✓ | ✓ (read) | ✓ (CRUD) | ✓ |
| Follows | ✓ | ✓ | — | ✓ |
| Notifications | ✓ | ✓ | — | ✓ |
| FCM device tokens | ✓ | ✓ | — | ✓ |
| User roles | ✓ | ✓ (read) | ✓ (manage) | ✓ |
| Admin applications | ✓ | ✓ (apply) | ✓ (review) | ✓ |
| Project proposals | ✓ | ✓ (submit) | ✓ (review) | ✓ |
| Audit log | ✓ | — | ✓ (view) | ✓ |
| Wallet | — | UI only | — | N/A |

---

## Pre-Launch Checklist

- [ ] Build mobile with production API URL: `--dart-define=API_BASE_URL=https://xxx.railway.app/api`
- [ ] Set `NEXT_PUBLIC_API_URL` in admin panel to Railway URL
- [ ] Set `CORS_ORIGINS` in Railway to include admin panel deployed URL
- [ ] Run `bun run prisma:seed` against production DB (populates tags)
- [ ] Set all backend env vars in Railway (see list above)
- [ ] Rotate Supabase DB password if not done already (was exposed in chat)
