# Start here — next session

> Rewritten 2026-09-17. Read this, then [`../APP_MAP.md`](../APP_MAP.md) (the plan) and the
> last rows of [`../UX_UI_TRACKER.md`](../UX_UI_TRACKER.md) (what happened).

---

## Owner rules (from 2026-09-17)

- **No design rounds.** No Claude Design briefs or canvases. Build and change screens directly
  in [`VISUAL_LANGUAGE.md`](VISUAL_LANGUAGE.md), the app's original look. The 09-11 "Signal
  Cyan" look was rejected as "too AI".
- **Fix, don't log.** When you find a defect, fix it in the same session and report the call
  you made. Only leave a finding `open` if it needs the owner (credentials, production, their
  phone).
- Run commands yourself; `stage` is the working branch and pushing it deploys.

## Where things stand

| | |
|---|---|
| Branch | `stage`. The 09-17 polish pass was built on `polish-pass` and merged once the owner approved. |
| Plan | APP_MAP steps 0–6 done: cleanup, reliability, Hunter Hub, **Gems**, **Profile slim**, Mine + Wallet. Every mobile screen has had the visual pass. |
| Open findings | None needing work. F-67 (sizes) waits for the owner's test on a physical phone. |

## What's left, in order

1. **Shared widgets.** Several features carry their own copy of the same pieces: a dark
   outlined 40px button (`HubButton`, `ModButton`), a caps pill (`HubPill`, `ModPill`,
   `ProfilePill`, `MinePalette.tag`), a list row with chevron, a row group and a stat tile
   (`features/profile/.../common/`). Move one version of each into `lib/shared/widgets`,
   point the features at it, and delete the copies.
2. **`AppSnackbar` from inside a sheet** shows behind the sheet for error/info toasts
   (success was fixed per screen). Add a variant that attaches to the sheet's overlay.
3. **Progress screen** (APP_MAP step 7): Badges, Quests and Levels as one screen.
4. **Community post edit/delete**: no server endpoint exists; build it with the screen.
5. **Console review** (APP_MAP step 7), in the same visual language as mobile.
6. Small layout nits seen on device: the Home + button covers the end of post text while
   scrolling; the Hub's "Post update" button is large.

## Local dev — things that bite

- **Launch the app with the env file.** VS Code's *Run* lens above `main()` skips
  `.env.local.json`, Supabase is never set up, and the app hangs on the splash. Use the
  **Mobile Flutter (local env)** launch config, or
  `flutter run --dart-define-from-file=.env.local.json`.
- The backend dev server must be running (`cd backend && bun run dev`, health at
  `localhost:3080/api/health`) and the emulator needs `adb reverse tcp:3080 tcp:3080`.
- `bun run dev` compiles to `backend/dist-dev`. After pulling a migration run
  `bunx prisma generate`.
- The emulator (Pixel_9_Pro) sometimes closes; `flutter emulators --launch Pixel_9_Pro`.
  A cold boot usually keeps the session now (F-38 keeps roles offline).
- Dev data kept on purpose: `@babsman4all` co-owns Solana Radar, TON Drop Desk and Ethereum
  Watch; TON Drop Desk has 3 asks and 1 inactivity report; every seeded profile has a
  username (`bun run prisma:seed:usernames` fills missing ones).

## Not yet seen on a device

Hub: the Reliable / Slipping standing cards, a Due row, invite and review cards, the 12-gem
fold. Mine: expired and closing-soon states. Wallet: a failed withdrawal. The closed-alpha
screen. All covered by widget tests.
