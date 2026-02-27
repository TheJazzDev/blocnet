# Auth + Wallet + Economy Runbook

This document defines the expected production flow for session auth, wallet deposits, mining issuance, tipping, and admin observability.

## 1) Session Flow (Supabase + App)

### 1.1 Admin panel (Next.js)

Authority model:
- Single source of truth is `httpOnly` cookies (`admin_token`, `admin_refresh_token`).
- Browser Supabase session persistence/auto-refresh must be disabled.

Current code path:
- Sign in: `admin/app/signin/sign-in-form.tsx`
- Cookie set route: `admin/app/api/auth/set-token/route.ts`
- Protected route gate + refresh: `admin/proxy.ts`
- API forwarding + refresh lock: `admin/app/api/proxy/[...path]/route.ts`

Expected behavior:
1. User signs in with Supabase credentials.
2. App verifies admin role via backend `/me`.
3. App stores access + refresh token in `httpOnly` cookies.
4. Every admin page/API call reads cookie tokens server-side.
5. When access token is missing/near expiry, refresh occurs server-side only.
6. Refresh token rotation is serialized by refresh-token lock map.

Supabase client requirements (admin):
- `persistSession: false`
- `autoRefreshToken: false`
- `detectSessionInUrl: false`

### 1.2 Mobile app (Flutter)

Authority model:
- Token refresh is owned by app refresher (`AuthStore.refreshAccessTokenSilently`) and serialized.
- Supabase SDK auto-refresh must be disabled.

Current code path:
- Supabase init: `mobile/lib/main.dart`
- Auth bootstrap + silent refresh + retry: `mobile/lib/services/auth_store.dart`
- API 401 handling + refresh serialization: `mobile/lib/services/api/api_client.dart`
- Deep link auth callback handling: `mobile/lib/services/deep_link_service.dart`

Expected behavior:
1. App boots and loads current session access token.
2. Backend `/auth/session/verify` validates token.
3. If expired, app performs one silent refresh and retries verify.
4. API client refreshes once for concurrent 401 bursts (single in-flight refresh).
5. Deep-link callback sets session via refresh token and verifies using returned access token.

Supabase client requirements (mobile):
- `FlutterAuthClientOptions(autoRefreshToken: false)`

## 2) Required Configuration

## 2.1 Supabase project

Auth settings:
- Access token lifetime can remain 1 hour.
- Refresh token rotation stays enabled (single-use rotation is expected).
- Redirect URLs must include mobile callback scheme and admin host(s).

Minimum app-facing keys:
- `SUPABASE_URL`
- `PUBLISHABLE_KEY`

Backend verification requirements:
- `SUPABASE_JWKS_URL` or `SUPABASE_JWT_SECRET` must be configured.

## 2.2 Admin env

Required:
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_PUBLISHABLE_KEY`
- `NEXT_PUBLIC_API_URL`

## 2.3 Mobile env / dart-define

Required:
- `SUPABASE_URL`
- `PUBLISHABLE_KEY`
- `API_BASE_URL`
- `SUPABASE_EMAIL_REDIRECT_URL` (ex: `io.blocnet.app://auth/callback`)

## 2.4 Backend wallet env

Required for deposits/settlement:
- `WALLET_ENABLED=true`
- `DEPOSITS_ENABLED=true`
- `BSC_RPC_URL`
- `BSC_CHAIN_ID`
- `TURNKEY_MODE` + Turnkey credentials (when not mock)
- asset configs (`WALLET_ASSET_*`, token addresses)
- treasury configs (`TREASURY_ADDRESS`, `TREASURY_WALLET_ID`)

## 3) Deposit Flow (BSC -> User Wallet Credit)

1. User sends token to app-assigned on-chain wallet address.
2. Deposit indexer scans chain/logs and detects transfer.
3. Matching deposit is inserted as `onchain_deposit` (`detected`).
4. Processor credits internal ledger account.
5. Deposit status moves to `credited`.
6. Sweep worker may move funds to treasury.
7. Wallet screen reads ledger balances from backend.

If a tx is missed by index window:
- Admin can use Manual Deposit Reprocess in Wallet Settings and replay a tx hash.

## 4) Mining Flow (MCR issuance)

1. User starts mining session.
2. Hourly checkpoints accrue mined amount.
3. Claim finalizes matured amount.
4. Claimed amount is credited into tip balance in `MCR` currency.

Terminology:
- User-facing mining amount should be shown as `MCR`, not `points`.

## 5) Tipping Flow (MCR/CLR)

1. Sender selects tip amount/currency.
2. Policy applies fee rules.
3. Sender debited, recipient credited, fee vault credited.
4. Notification emitted to recipient.
5. Transactions visible in admin tip transactions.

## 6) Admin Observability (What must be visible)

Wallet Settings now includes:
- Wallet asset holdings totals by asset (available/pending/locked/total).
- Credited deposit totals by asset.
- Tip currency totals (holders, balances, tipped volume, fees).
- Mining issuance totals (lifetime mined/claimed/unclaimed MCR, total miners).

Mining page now includes:
- 24h operations metrics.
- Lifetime mined/claimed/unclaimed MCR totals.

## 7) Operational Checks

Session reliability checks:
- Let session run > 1 hour and trigger multiple concurrent admin API requests.
- Confirm no `Invalid Refresh Token: Already Used` errors.

Deposit checks:
- Confirm runtime flags in Wallet Settings show wallet+deposits enabled.
- Confirm RPC reachability and token/treasury config are valid.
- If tx not indexed, run manual reprocess and verify credited deposit count.

Observability checks:
- Compare mined/tip/wallet totals in admin against DB snapshots periodically.
