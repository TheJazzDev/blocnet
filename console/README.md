# Blocnet Console Shell

This is a lightweight Next.js shell for the future admin panel.

## What is included

- App Router setup with TypeScript.
- Protected route group:
  - `/dashboard`
  - `/projects`
  - `/users`
  - `/applications`
  - `/audit-log`
  - `/settings`
- Sidebar and topbar frame.
- Placeholder screens for each core admin area.
- Middleware guard that checks `admin_session` cookie.
- Mock sign-in page at `/signin` for shell testing.

## Run

```bash
cd /Users/jazzdev/Documents/Programming/blocnet/admin
npm install
npm run dev
```

Open http://localhost:3000.

## Current auth behavior

- `/signin` writes `admin_session` and `admin_role` cookies.
- Middleware allows protected pages when `admin_session` exists.
- `/settings` sign-out button clears cookies via `/signout`.

Replace this with real backend auth + role verification in the next integration pass.
