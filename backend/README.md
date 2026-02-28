# Blocknet Backend (NestJS)

Backend API for Blocknet mobile and future admin panel.

## Stack
- NestJS
- Prisma ORM (v7 + `prisma.config.ts`)
- Supabase Postgres
- Supabase Auth JWT verification
- Firebase Cloud Messaging (push)

## Setup
```bash
bun install
cp .env.example .env.local
bun run prisma:generate
bun run prisma:migrate
bun run prisma:seed
bun run build
bun run start:dev
```

## Swagger
- UI: `http://localhost:3080/api/docs`
- JSON: `http://localhost:3080/api/docs-json`
- Use the `Authorize` button with a Supabase bearer token for protected endpoints.

## Bootstrap Notes
- `bun run prisma:seed` now inserts demo projects/updates/follows/notifications for local testing.
- Set `OWNER_USER_ID` and `OWNER_EMAIL` in `.env.local` if you want seed ownership tied to your real Supabase account.
- If owner env values are omitted, seed falls back to `owner@blocknet.local`.
- Use `SUPABASE_JWKS_URL` for JWT verification.
- Prisma CLI config is in `prisma.config.ts`.
- `DATABASE_URL` is used by runtime Prisma adapter (`@prisma/adapter-pg`).
- `DIRECT_URL` is preferred for Prisma migration commands.

## Email Broadcast Env
- `RESEND_API_KEY`
- `EMAIL_FROM_ADDRESS` or `FROM_EMAIL` (default digest sender address)
- `EMAIL_FROM_NAME` (default: `Blocnet Digest`)
- `EMAIL_ADMIN_FROM_ADDRESS` (default: `EMAIL_FROM_ADDRESS`)
- `EMAIL_ADMIN_FROM_NAME` (default: `Blocnet Updates`)
- `EMAIL_FROM_ALLOWLIST` (comma-separated list of allowed sender addresses for admin broadcasts)
- `EMAIL_REPLY_TO`
- `EMAIL_BROADCAST_RATE_PER_MINUTE` (default: `120`, range: `1-600`)
- `EMAIL_LOGO_URL` (optional, defaults to `https://blocnet.app/logo2.png`)

## Test
```bash
bun run test
bun run test:e2e
```

## API Prefix
All routes are served under `/api`.

## Blocnet Edge Engine (BEE) V1 Endpoints
- `GET /api/me/edge/feed`
- `GET /api/me/edge/brief`
- `GET /api/me/edge/explain/:decisionId`
- `POST /api/me/edge/feedback`

## Blocnet Edge Engine (BEE) V2 (Admin Analytics - Sprint 1)
- `GET /api/admin/edge/overview`
- `GET /api/admin/edge/config`
- `PATCH /api/admin/edge/config` (owner/admin)

Feature flag:
- `ENABLE_BEE=true|false` (default: `true`)
- `ENABLE_BEE` is used as the bootstrap default; runtime enable/disable is stored in DB (`EdgeConfig`) and managed from admin.

Persistence:
- `EdgeDecision` table stores generated decision records and score components.
- `EdgeFeedback` table stores user feedback actions (`act|watch|ignore`).
- `EdgeConfig` table stores runtime BEE toggle state.
- `EdgeEngagement` table stores user engagement metrics (clicks, view duration, scroll depth).

## BEE ML Integration (AI-Powered Content Analysis)

The Edge Engine supports optional ML-powered content analysis via the BEE ML service (FastAPI + LLM providers).

### ML-Enhanced Features
When enabled via admin panel, the Edge Engine enhances each update with:
- **Quality Score** (0-1): Content quality assessment
- **Sentiment Analysis**: Positive, neutral, or negative sentiment
- **Topic Extraction**: Key topics and themes
- **Actionability Score** (0-1): How actionable the update is
- **Key Insights**: Important takeaways from the content
- **Web Context**: Optional web search grounding (Gemini provider)

### Configuration
ML settings are configured at runtime from the admin panel (stored in `EdgeConfig` table):
- **mlEnabled**: Enable/disable ML analysis
- **mlUrl**: BEE ML service URL (default: `http://localhost:8083`)
- **mlTimeout**: Request timeout in milliseconds (default: 10000)
- **mlProvider**: LLM provider selection (`auto`, `ollama`, `groq`, `gemini`)
- **mlWebSearch**: Enable web search grounding for analysis

No environment variables required - all settings are runtime-configurable from the admin dashboard.

### How It Works
1. Edge Engine generates feed using traditional BEE scoring
2. If ML is enabled (via `EdgeConfig.mlEnabled`), batch analyzes update content via BEE ML service
3. Enriches `EdgeDecision` records with ML analysis results
4. Falls back gracefully to traditional scoring if ML service is unavailable

### ML Fields in EdgeDecision
- `mlQuality`: Float (0-1)
- `mlSentiment`: String (positive/neutral/negative)
- `mlTopics`: JSON array of topics
- `mlActionability`: Float (0-1)
- `mlInsights`: JSON array of key insights
- `mlProvider`: String (provider name, e.g., "bee")

### BEE ML Service
The BEE ML service is a separate FastAPI application in `../bee/` that provides:
- Multi-provider LLM architecture (Ollama, Groq, Gemini)
- Automatic fallback between providers
- Batch content analysis
- Vector embeddings for semantic search
- Web-grounded analysis (Gemini)

See `../bee/README.md` for setup instructions. Default service port: **8083**

## Access Model (Current)
- Public read endpoints:
  - `GET /api/projects`
  - `GET /api/projects/:id`
  - `GET /api/updates`
  - `GET /api/updates/:id`
- Authenticated endpoints:
  - all mutations (create/update/follow/notifications/roles/admin review).

## Important Paths
- Prisma schema: `prisma/schema.prisma`
- Initial SQL snapshot: `prisma/migrations/0001_init/migration.sql`
- Modules: `src/*`
- Plan reference: `../BLOCKNET_PLAN.md`
