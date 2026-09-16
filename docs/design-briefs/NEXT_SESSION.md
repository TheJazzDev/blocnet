# Start here — next session

> Rewritten 2026-09-16 at the end of the day. The 09-14 version recommended Discover next;
> that was superseded the same week by the app-map review. Read this, then
> [`../APP_MAP.md`](../APP_MAP.md) (the plan) and the last rows of
> [`../UX_UI_TRACKER.md`](../UX_UI_TRACKER.md) (what happened).

---

## Where things stand

| | |
|---|---|
| Branch | **`stage`** — all work now merges here. `feature/home-feed-redesign` is fully merged and no longer the working branch. Stage was deployed ~13:24 UTC on 09-16. |
| The plan | [`APP_MAP.md`](../APP_MAP.md) — every screen judged keep / rebuild / merge / move / cut against the loop, owner-approved (except: **Wallet stays in the bottom bar**). |
| Done | Step 1 cleanup · step 2 hunter reliability (backend) · step 3 **Hunter Hub** (design → build → device-verified) · Hand over · BNP in the wallet with member transfers · F-70 likes and saves on the server. |
| In flight elsewhere | A parallel session (**blocnet-34**) owns mining: findings F-44…F-69, workstreams S1–S5, and the **Mine** rebuild (design approved 09-16), which also absorbs the referral screen (APP_MAP step 6). |
| Next for this lane | **Gems** (APP_MAP step 4): brief ready at [`gems.md`](gems.md) — owner to run it in Claude Design. Then **Profile slim** (step 5). |
| Open findings (this lane) | F-37 raw withdrawal errors · F-38 expired-session half-state (seen again 09-16 when the emulator lost DNS) · F-71 intermittent levels-leaderboard spec · F-72 seeded dev profiles have no usernames |

## The method (unchanged, and it worked for the Hub)

1. **Brief from what the screen is *for***, not a field list.
2. **Bring the approved design into the repo** (`docs/artifacts/`) and **extract every state
   element by element into a build spec before code** — see
   [`hunter-hub-build-spec.md`](hunter-hub-build-spec.md). Record where the design contradicts
   itself and which reading was built (D1…Dn).
3. **Build to the list**, rebuilding rather than adapting.
4. **Walk every state against the list**, then **verify on the emulator**.
5. Blocked on the backend? **Build it** and report the decisions (owner's standing rule).

## Working with the parallel session

- **One migration at a time** on the shared dev DB (Postgres :5433). Ask blocnet-34 for the
  slot, tell it when the migration is merged. Never `db push`, never reset.
- **Merge into the main checkout only when `git status` is clean.**
- Finding numbers: blocnet-34 uses F-44…F-69; this lane uses **F-70…F-79**.
- Ask before using **emulator-5554** while the other session is on it.

## Local dev — things that bit us on 09-16

- **`bun run dev` now compiles to `backend/dist-dev`** (`tsconfig.dev.json`). Before that, every
  `bun run build` deleted `dist/` under the running server and sign-in failed with *"connection
  closed before full header"*. If you see that error, check `curl localhost:3080/api/health`
  first.
- After pulling a migration: **`bunx prisma generate`** (Prisma 7 `migrate dev` does not do it for
  you, and the build fails without it).
- Emulator: `adb reverse tcp:3080 tcp:3080`; run with
  `flutter run --dart-define-from-file=.env.local.json`. A cold boot drops the session — the
  owner has to sign in again (the password is not in the repo). If the app shows an empty feed
  and no space chip, the emulator has lost DNS: toggle its wifi.
- Dev data the owner chose to keep: `@babsman4all` co-owns Solana Radar, TON Drop Desk and
  Ethereum Watch; TON Drop Desk has 3 asks and 1 inactivity report; Hunter Sage is
  `@hunter_sage`.

## Not yet seen on a device

Hub: the Reliable / Slipping standing cards, a Due row, the invite and review cards, the
12-gem fold (dev gems are all under two weeks old). BNP member transfers. All covered by widget
tests.
