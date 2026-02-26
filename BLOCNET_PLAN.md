# Blocknet Build + Learning Master Plan

## Product Premise and Mission
Blocknet is a structured crypto update network for communities that miss critical opportunities because chat streams are noisy.

Problem:
- Important project actions (launch, KYC, claim windows, upgrades) get buried.
- Users miss high-value deadlines because no one owns structured tracking.

Mission:
- Convert noisy chat updates into structured, followable project intelligence.
- Assign clear ownership for each project and keep followers continuously updated.
- Deliver urgency-based notifications and trust-based contributor reputation.

Long-term vision (post-MVP):
- contributor wallet and tokenized donations,
- performance and trust scores for posters,
- stronger moderation and safety controls.

## Monorepo Structure (Locked)
- `mobile/` Flutter app (user-facing product)
- `backend/` NestJS API (single source of business logic)
- `admin/` reserved for future Next.js admin panel

## Locked Architecture Decisions
- Backend: NestJS (shared API for mobile now and admin web later).
- Database: Supabase Postgres.
- ORM: Prisma 7 (`prisma.config.ts` + `@prisma/adapter-pg`).
- Auth issuer: Supabase Auth.
- Authorization authority: NestJS role + resource guards.
- Signup: open (not invite-only).
- Package manager: `bun` (use `bunx` instead of `npx`).
- Notifications: Postgres in-app notifications + FCM push for device delivery.

## Canonical Content Hierarchy (Critical Product Context)
Blocknet content structure is:
1. `Project` (root entity)
2. `Update` (entry under a project)
3. `Comment` (discussion under an update)

Core invariants:
- An update MUST belong to exactly one project (`update.project_id` required).
- A comment MUST belong to exactly one update (`comment.update_id` required).
- A project is unique by canonical identity (slug/symbol/domain); duplicates are not allowed.
- Updates can be consumed as standalone feed items, but remain linked to their project.
- The original project creator is the primary maintainer of that project.

## Project Ownership + Collaboration Model
For each project:
- Exactly one primary maintainer (creator/owner) exists.
- Additional collaborators can be assigned to co-maintain updates.
- Collaborators can create updates under the project if granted assignment.
- Ownership transfer and collaborator removal must be auditable.
- Primary maintainer can be an admin, or an approved poster granted project-publisher rights.

This supports your intended flow:
- `Codawoo` project is created once.
- Updates are posted under `Codawoo` over time.
- Followers receive notifications per new update.
- Other approved posters/admins can collaborate on `Codawoo` when accepted.

## Role and Permission Matrix (Updated)
Users can hold multiple roles simultaneously.

### `owner`
- Global authority.
- Promote/demote admins.
- Override moderation decisions.
- Access full audit logs.

### `admin`
- High-trust operators under owner.
- Create/manage projects.
- Approve/promote posters.
- Assign/remove project collaborators.
- Moderate updates/comments and apply sanctions per policy.

### `poster`
- Content contributor.
- Create project updates where assigned (or where primary maintainer).
- Can create a new project only when granted project-publisher permission by owner/admin.
- Cannot modify system-wide roles/policies.

### `user`
- Follow/unfollow projects.
- Read feeds and notifications.
- Comment under updates.
- Apply for elevation (poster/admin workflow).

## Public Profile Model (Required for Trust)
Each account has:
- private account profile (auth/account settings),
- public contributor profile (viewable by other users).

Public profile should expose:
- roles (multi-role badges),
- projects created,
- updates created,
- quality/reliability metrics,
- future: donations and wallet reputation.

## Backend Modules (Implemented + Planned)
Implemented scaffold:
- `auth`
- `users`
- `roles`
- `admin-applications`
- `projects`
- `project-assignments`
- `updates`
- `follows`
- `notifications`
- `device-tokens`
- `health`
- `audit-log`
- `prisma`

Planned next modules:
- `comments`
- `project-collaborators` (if separated from current assignment semantics)
- `moderation-actions`
- `public-profiles`

## API Contract (MVP + Next Additions)
Current scaffold routes:
- `POST /api/auth/session/verify`
- `GET /api/me`
- `PATCH /api/me`
- `POST /api/admin-applications`
- `GET /api/admin-applications`
- `PATCH /api/admin-applications/:id/review`
- `POST /api/roles/admins/:userId/promote`
- `POST /api/roles/posters/:userId/promote`
- `POST /api/projects`
- `GET /api/projects`
- `GET /api/projects/:id`
- `PATCH /api/projects/:id`
- `POST /api/projects/:projectId/posters/:posterId/assign`
- `POST /api/projects/:projectId/follow`
- `DELETE /api/projects/:projectId/follow`
- `POST /api/projects/:projectId/updates`
- `GET /api/updates`
- `GET /api/updates/:id`
- `PATCH /api/updates/:id`
- `GET /api/notifications`
- `PATCH /api/notifications/:id/read`
- `POST /api/device-tokens/register`
- `DELETE /api/device-tokens/:id`
- `GET /api/health`
- `GET /api/audit-log`

Next required routes:
- `POST /api/updates/:updateId/comments`
- `GET /api/updates/:updateId/comments`
- `PATCH /api/comments/:id`
- `DELETE /api/comments/:id`
- `GET /api/profiles/:id/public`
- `POST /api/projects/:projectId/collaborators/:userId`
- `DELETE /api/projects/:projectId/collaborators/:userId`

## Database Schema and Migration Order
Current schema file:
- `backend/prisma/schema.prisma`

Current migration sequence (locked):
1. `profiles`, `user_roles`
2. `projects`, `project_posters`
3. `updates`
4. `project_follows`
5. `notifications`
6. `device_tokens`
7. `admin_applications`
8. `audit_logs`

Next migration additions:
9. `comments`
10. `project_collaborators` (if distinct)
11. `moderation_actions`
12. `profile_metrics` (for public trust stats)

## Notification Architecture
On project update creation:
1. Enforce creator permission (owner/admin/collaborator poster).
2. Persist update under project.
3. Resolve followers of that project.
4. Insert one in-app notification record per follower.
5. Dispatch push via FCM to registered device tokens.
6. Persist failures/retry metadata.

Client behavior:
- Notification center from `/api/notifications`.
- Mark read with `/api/notifications/:id/read`.
- Open linked update when available.
- Refresh on app foreground and notification-open.

## Flutter Refactor Targets
- All runtime data from NestJS API (no dummy production flow).
- Role-aware UI behavior (owner/admin/poster/user).
- Create-update flow always project-bound.
- Notification center linked to real project updates.
- Public profile route/screen for contributor transparency.

## Week-by-Week Execution Plan (Updated)
### Week 1
- Stabilize auth/session, role hydration, API connectivity.
- Lock project uniqueness and ownership semantics.

### Week 2
- Finish role operations + audit trails.
- Admin/poster assignment and collaborator lifecycle.

### Week 3
- Harden project/update operations around canonical hierarchy.
- Enforce: all updates must be attached to a project.

### Week 4
- Implement comments under updates.
- Add moderation actions for comments/updates.

### Week 5
- Public profile and contributor metrics.
- Follow-state accuracy and notification UX hardening.

### Week 6
- Beta hardening, query tuning, release gates.

## Testing and Release Gates
Release is blocked unless all are true:
- duplicate project creation is prevented,
- updates cannot exist without a parent project,
- comments cannot exist without a parent update,
- unauthorized role escalation is blocked,
- unassigned posters cannot create updates in a project,
- followers get in-app notifications on new project updates,
- feed/urgency ordering matches backend truth,
- no dummy data is used in production paths.

## Learning Track (Yardstick)
### NestJS milestones
- Modules + dependency boundaries,
- guards/decorators for RBAC,
- DTO validation and contracts,
- Prisma relational modeling for hierarchy constraints,
- queue/push patterns + failure handling.

Weekly deliverable:
- one ADR entry documenting one architecture decision and tradeoff.

### Flutter milestones
- API repository boundaries,
- Provider state composition for auth/content/notifications,
- role-based UI paths,
- profile + feed + notification integration,
- widget tests for key user journeys.

Weekly deliverable:
- one before/after technical note.

## Operational Details to Keep Documented
- environment variable ownership,
- local setup order,
- seed strategy for dev/staging,
- backup/restore plan,
- notification incident runbook,
- API versioning policy,
- Definition of Done checklist.

## Environment Variables
Backend `.env.local`:
- `DATABASE_URL`
- `DIRECT_URL`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_JWKS_URL`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`
- `OWNER_USER_ID` (optional)
- `OWNER_EMAIL` (optional)
- `PORT`
- `NODE_ENV`

Reference file:
- `backend/.env.example`

## Command Cheat Sheet
### Backend
- `cd backend`
- `bun install`
- `bun run prisma:generate`
- `bun run prisma:migrate`
- `bun run prisma:seed`
- `bun run build`
- `bun run test`
- `bun run test:e2e`
- `bun run start:dev`

### Mobile
- `cd mobile`
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter run`

## Assumptions and Deferred Scope
- Android-first and iOS simulator support for MVP.
- Wallet/token donation system remains post-MVP but planned in profile model.
- Next.js admin panel will consume existing NestJS API.
- Policy details for sanctions and moderation thresholds will be finalized separately.

## Implementation Progress (Live)
Completed in this pass:
- Backend `comments` module scaffolded.
- API endpoints added:
  - `POST /api/updates/:updateId/comments`
  - `GET /api/updates/:updateId/comments`
  - `PATCH /api/comments/:id`
  - `DELETE /api/comments/:id`
- Prisma `Comment` model added with strict relations:
  - comment -> update (required)
  - comment -> author profile (required)
- Audit log events wired for comment create/update/delete.
- Project canonical uniqueness checks added in service layer:
  - normalized name conflict check
  - symbol conflict check
  - website domain conflict check
- Collaborator invitation flow added:
  - `POST /api/projects/:projectId/posters/:posterId/invite`
  - `GET /api/projects/:projectId/invites`
  - `GET /api/project-invites/mine`
  - `PATCH /api/project-invites/:inviteId/respond`
- Public profile endpoint added:
  - `GET /api/profiles/:id/public`
- Mobile comments integrated into update details:
  - list comments
  - create comment
  - edit/delete own comment
- Project proposal workflow implemented:
  - `POST /api/project-proposals` (poster/admin/owner submit)
  - `GET /api/project-proposals/mine`
  - `GET /api/project-proposals` (owner/admin review queue)
  - `PATCH /api/project-proposals/:id/review` (approve/reject)
- Approval behavior:
  - approved proposal creates real project
  - applicant is auto-assigned as poster on that project
  - updates can then be created under approved project
- Mobile `Submit Project` UI added and wired from root composer action menu.
