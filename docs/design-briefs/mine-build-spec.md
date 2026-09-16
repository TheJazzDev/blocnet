# Mine — build spec (extracted from the approved design)

> Source of truth: [`../artifacts/blocnet-mine.html`](../artifacts/blocnet-mine.html)
> (approved 2026-09-16, with the ring and the explainer popover). Brief and owner decisions:
> [`mine.md`](mine.md).
>
> Method ([`NEXT_SESSION.md`](NEXT_SESSION.md)): every state below was extracted from the
> design file **before** code. Build to these lists and walk every state against them before
> calling it done. Copy in `code` is verbatim; `{braces}` are rendered from data.

---

## Tokens — design px → `lib/app/tokens`

**Type** (`AppText`)

| Design px | Used for | Token |
|---|---|---|
| 32 / 700 | balance number | `display` |
| 28 / 700 | ring centre number | `headline` (24) — nearest step that keeps a 4-digit cycle inside the 100 px ring interior; `display` would be the table's absorb step, but mobile sizes stay moderate |
| 24 / 700 | Earn faster boost `+10%` | `headline` |
| 20 / 680 | "when" line, error title | `title` |
| 17 / 680–700 | primary button, zero-friends title, code, sub-screen header title | `subtitle` |
| 15 | notify row, row titles, leaderboard names/amounts, history hour rows, notice title, popover title, buttons (44) | `body` |
| 13 | side column, rate lines, popover lines, row subtitles, handles, history cycle header, balance note, Dismiss / Got it / Copy | `label` |
| 11 | status pill, pill right label, section labels, friend/history pills, ring unit | `caption` |
| 9 | tier badge number | `TierLevelBadge` (size 18) |

**Space** (`AppSpace`): 2 → `hair` · 4 → `xs` · 5–8 → `sm` · 10–12 → `md` · 14–18 → `lg` ·
24 → `xl` · 32 → `xxl`.

**Radius** (`AppRadius`): 16 cycle card → `lg` · 14 popover → `lg` · 12 cards/rows/buttons(52)
→ `md` · 10 code box/buttons(44)/entry row → `md` · 8 Got it/Dismiss/pager → `sm` · pills → `full`.

**Icon** (`AppIcon`): `.mi` 20 → `md` · `.mi.s` 16 → `sm` · `.mi.xs` 14 → `sm` · `.mi.l` 28 →
`lg` · `.mi.xl` 40 → `xl`.

**Fixed sizes** (not on a scale, kept literal): ring 116 (stroke 7 % of size, radius 44 %),
primary button 52, secondary button 44, small button 36 (inside a 44 target), switch 44×26 in a
44 row, avatar 36, tier badge 18, header 48, pager button 32 visual in a 44 target.

**Colour** (`MinePalette`, `features/mining/presentation/mine_palette.dart`, reusing
`AppColors` where the hex already exists)

| Role | Hex | Source |
|---|---|---|
| ground | `#09090b` | `AppColors.bgBase` |
| flat card | `#101012` + inset `#232327` (cycle) / `#1f1f23` (sections) | `hubCard`, `hubCardEdge`, `hubTileEdge` |
| accent fill (buttons, meter, switch) | `#0891B2` | `hunterFill` |
| accent (ring, links, boost, icons) | `#22D3EE` | `chainIce` |
| accent soft (pill text) | `#67e8f9` | `hunterSoft` |
| ready pill text | `#a5f3fc` | local |
| running ground | `#0f1b1f → #101113`, inset `#22d3ee2e` | local |
| ready ground | `#0f2126 → #101214`, inset `#22d3ee` 32 %↔64 % (3.2 s) | local |
| closing-soon ground | `#1f1a10 → #121110`, inset `#f59e0b52` | local |
| paused ground | `#101012`, inset `#3f3f46` | `hubCard`, `borderMuted` |
| amber | `#F59E0B`; text `#FBBF24`; on-amber `#1c1204` | `dueAmber`, `chainBsc`, local |
| text | `#fff` · `#e4e4e7` · `#d4d4d8` · `#c4c4cc` · `#a1a1aa` · `#8b8b93` · `#71717a` · `#6b6b73` · `#52525b` | `zinc*` + local `#c4c4cc` |
| ring track | `#232327` | `hubCardEdge` |
| rank 1/2/3 | `#F0B429` / `#C0C6CE` / `#C97B3C` | local |
| mining-now | `#3f9c86` | `currentTick` |
| claimed receipt | `#0f1b1f`, inset `#22d3ee33` | local |
| expired notice | `#141412`, inset `#f59e0b33` | local |
| pinned row | `#0f1417` 95 %, top border `#22d3ee38` | local |
| code box | `#0b0f11`, inset `#22d3ee2e` | local |
| friend-code row | `#0d0d0f`, inset `#1f1f23` | local |
| divider inside cards | white 7 % | local |

No red anywhere on the tab.

---

## Shell

1. Shared app bar (as Hub D5): title **`Mine`**, then `history` (opens Hourly history) and
   `help` (opens the popover; drawn filled `#27272a` disc while open).
2. Tab body, scrollable, pull to refresh.
3. Bottom bar: `Mine` label is already shipped.

## Cycle card — five states + paused + couldn't load

Order inside every card: **pill row → when line → core (ring + side) → primary button →
note → notify row**. Only the parts listed for a state render.

| | Idle | Running | Ready | Closing soon | Paused |
|---|---|---|---|---|---|
| ground | flat | running | ready (edge breathes 3.2 s) | closing soon | paused |
| pill | `pause_circle` `NOT MINING` (grey) | `bolt` `MINING` (cyan) | `check_circle` `READY TO CLAIM` | `timer` `CLOSING SOON` (amber) | `pause_circle` `PAUSED BY BLOCNET` |
| right label | `Cycle · {cycleHours}h` | `Hour {h} of {cycleHours}` | `Cycle complete` | `Claim window` | `All members` |
| when (bold) | `Start mining` | `Ready {today/tomorrow/Fri} at {HH:mm}` | `Ready to claim` | `Expires in {n}h` | `Mining is paused` |
| when (muted) | ` · {perCycle} BNP a day` | ` · {n}h left` | ` · expires {EEE HH:mm}` | ` · {today/tomorrow} at {HH:mm}` | ` · your balance is safe` |
| ring | empty track | cyan, fraction = elapsed / cycle, glow breathes 2.4 s | cyan, full | amber, fraction = claim window left / claim window | empty track |
| ring centre | `bolt` · `0 BNP` | `bolt` · **{mined}** · `of {cyclePoints} BNP` | `check_circle` · **{points}** · `BNP` | `timer` · **{points}** · `BNP` | `pause_circle` · `Paused` |
| side | `{rate} BNP/hr` · boost line | `{rate} BNP/hr` · boost line | `{rate} BNP/hr` · boost line | `Claim before {HH:mm}` · `or it's gone` | (empty) |
| button (52) | `bolt` `Start mining` | — | `savings` `Claim {points} BNP` | `savings` `Claim {points} BNP` (amber) | — |
| note | — | — | `Claiming starts your next cycle.` | — | — |
| notify row | only once the member has mined before (state 6 shows it, state 1 does not) | `notifications_active` `Notify me when it's ready` + switch | — | — | see D3 |

Boost line: `+{x}% from {n} friends` / `+5% from 1 friend` / `No boost yet`.
`{perCycle}` = base per cycle with today's boost (120 → 132 with +10 %).
"a day" is used when the cycle is 24 h; otherwise `a cycle`.
Closing soon starts at **6 hours** left (the backend's reminder threshold).

**Couldn't load** (no snapshot, load failed) — centred block instead of the card and sections:
72 ring disc with `cloud_off` → `Can't reach Blocnet` (title) → `Your cycle keeps running. Try
again in a moment.` (body) → full-width primary `refresh` `Retry` → `Last balance **{n} BNP**`
(only when a balance is cached on the device).

## State 1 · First visit, idle
1. App bar (`help` active)
2. Cycle card — idle, `Start mining · 120 BNP a day`, `5 BNP/hr` · `No boost yet`, `Start mining`
3. Section `account_balance_wallet` `Balance`
4. Balance card: **0** `BNP` → `Converts to BNT at launch.` → divider →
   `account_balance_wallet` `View in Wallet` `chevron_right`
5. Section `trending_up` `Earn faster`
6. Row `group_add` **`Invite friends`** / `+5% per active friend` `chevron_right`
7. (below the fold) Leaderboard preview
8. Scrim (below the app bar) + popover under `?`: **`How mining works`** →
   `bolt` `Mine BNP in 24-hour cycles.` → `check_circle` `Claim within 48 hours, or the cycle
   expires.` → `swap_horiz` `BNP converts to BNT at launch.` → `Got it`. Opens by itself once;
   nothing on the page moves.

## State 2 · Running, hour 9 of 24
1. App bar
2. Cycle card — running: `MINING` · `Hour 9 of 24` → `Ready tomorrow at 09:20 · 15h left` →
   ring 35 % · `49` `of 132 BNP` · `5 BNP/hr` `+10% from 2 friends` → notify row (on)
3. Section `Balance` → balance card `8,412`
4. Section `Earn faster` · right `+10%`
5. **Earn faster card** (inline, see D1): **`+10%`** `2 active friends · max +100%` → meter
   (20 segments, 2 filled) → `Active means mined in the last 7 days.` → code box `key`
   **`BNC4K92X`** → `ios_share` `Share code` (fill) · `Copy` (outline, small)
6. Section `leaderboard` `Leaderboard` · right `You · #27`
7. Leaderboard preview: top 3 rows + your row

## State 3 · Ready to claim, 30 h left
1. App bar
2. Cycle card — ready: `READY TO CLAIM` · `Cycle complete` → `Ready to claim · expires Fri
   15:20` → full ring · `132` `BNP` · side → `Claim 132 BNP` → `Claiming starts your next cycle.`
3. Balance
4. Section `Earn faster` · `+10%` → row **`2 active friends · +10%`** / `+5% per active friend,
   max +100%`
5. Leaderboard preview · Hourly history row

## State 4 · Closing soon, 3 h left
1. App bar
2. Cycle card — closing soon: `CLOSING SOON` · `Claim window` → `Expires in 3h · today at
   15:20` → amber ring 6.25 % · `132` `BNP` · `Claim before 15:20` `or it's gone` → amber
   `Claim 132 BNP`
3. Balance → Earn faster row (as state 3) → Leaderboard preview → Hourly history row

## State 5 · Just claimed
1. App bar
2. **Receipt** (cyan): `check_circle` **`+126 BNP claimed`** → `Next cycle started.`
3. Cycle card — running, `Hour 1 of 24`, `Ready tomorrow at 09:41 · 23h left`, `5` `of 126 BNP`,
   `+5% from 1 friend`, notify row
4. Balance `8,538` → Earn faster row **`1 active friend · +5%`** → …

## State 6 · Cycle expired
1. App bar
2. **Expired notice** (amber edge): `timer_off` **`132 BNP expired`** → `Your 14 Sep cycle
   wasn't claimed within 48 hours.` → `Dismiss` (36 visual, 44 target). Dismissal is stored
   per cycle on the device.
3. Cycle card — idle: `Start mining · 132 BNP a day`, `+10% from 2 friends`, `Start mining`,
   notify row (off)
4. Balance
5. Section `schedule` `Hourly history` → row `history` **`Last 2 days`** / `1 claimed · 1 expired`
   (see D2 for order)
6. Earn faster row → Leaderboard preview

## State 7 · Paused by Blocnet
1. App bar
2. Cycle card — paused (see table). No button.
3. Balance
4. Earn faster row **`2 active friends · +10%`** / `Applies when mining is back`
5. Hourly history row `Last 2 days` / `2 claimed · 264 BNP`

## State 8 · Couldn't load
App bar → the centred error block above. No card, no sections.

## State 9 · Leaderboard
1. Header `arrow_back` **`Leaderboard`**
2. Section `leaderboard` `All-time BNP` · right `Page {p} of {n}`
3. Ten rows: rank (gold/silver/bronze for 1–3, grey otherwise) · avatar 36 · **name** + tier
   badge · `@handle` + (`bolt` `mining now` in `#3f9c86` when `sessionStatus == running`) ·
   amount (claimed total)
4. Pager: `chevron_left` · `Page {p} of {n}` · `chevron_right`
5. **Pinned row** (your row, same anatomy, name reads **`You`**) above the bottom edge while
   your row is not on screen. Hidden when the API sends no `me`.
Tap a row → public profile sheet.

## State 10 · Hourly history
1. Header `arrow_back` **`Hourly history`**
2. Per cycle (grouped by `sessionId`, newest first):
   - header (`#101012`, hairlines): `{d MMM} · now` (the live cycle) or `{d MMM} · {n} BNP`
     (claimed total; `0 BNP` for expired) · pill `NOT CLAIMED` (amber) / `CLAIMED` (cyan) /
     `EXPIRED` (grey)
   - hour rows: `{HH:00}` · `{points} BNP` · `Waiting` (amber) / `Claimed` (`#3f9c86`) /
     `Expired` (grey; amount struck through)

## State 11a · Earn faster — can still enter a code
1. Header **`Earn faster`**
2. Card: **`+10%`** `2 active friends · max +100%` → meter → **`+5%`` per active friend, max
   +100%. Active means mined in the last 7 days.` → code box → `Share code` · `Copy` →
   `how_to_reg` `Have a friend's code?` · `Today only` (only while the bind window is open and
   no referrer is linked)
3. Section `groups` `Your friends` · right `{active} of {total} active`
4. Card of friend rows: avatar · **name** + tier badge · pill `ACTIVE` (cyan) or `{n} DAYS`
   (grey, days since last mined) → footer `{Name}'s +5% counts again when they mine.` (when
   one friend is inactive). No emails.

## State 11b · Earn faster — no friends yet
1. Header **`Earn faster`**
2. Card: `group_add` (40) → **`Invite a friend, earn {perCycleWithOne} BNP a day`** → `+5% per
   active friend, max +100%.` → code box → `Share code` · `Copy` → friend-code row (if open)
3. Section `bolt` `Your rate now`
4. Card: **`120 BNP`** (white) `a day · 5 BNP/hr` → empty meter → `No boost yet.`

## State 12 · Push notifications
Backend-owned (`mining-reminder.messages.ts`). Not part of this client build.

## Motion
Running ring glow 2.4 s, ready card edge 3.2 s. Nothing else moves. Both stop under reduced
motion and while the tab is hidden (TickerMode / Visibility).

---

## Decisions where the design is silent or contradicts itself

- **D1 · Inline Earn faster card vs row.** State 2 shows the full card; states 1, 3, 4, 5, 7
  show a one-line row. Rule built: the full card appears only when the cycle card has **no
  primary button** (running), so the screen never carries two primary actions. Otherwise the
  row. The row opens the Earn faster sub-screen.
- **D2 · Section order.** Balance → Earn faster → Leaderboard → Hourly history. State 6 puts
  Hourly history directly under Balance; built as: while the expired notice is showing, the
  history row moves up under Balance (that is where the lost cycle is recorded).
- **D3 · Paused notify row.** State 7 draws `Notify me when it's back`, but there is no
  notification type for mining resuming. Not built; the row is omitted until a
  `mining_resumed` type exists.
- **D4 · Paused with a finished cycle.** Not drawn. Claiming still works while paused, so a
  claimable cycle shows the ready / closing-soon card even when mining is paused.
- **D5 · Notify row on idle.** Shown only once the member has mined before (state 6 has it,
  state 1 does not).
- **D6 · Hour and time maths.** `Hour {h}` = elapsed hours rounded up (min 1); `{n}h left` =
  remaining hours rounded up, `{n}m left` under an hour; ring fraction is elapsed time over
  cycle time (the design's 35.42 % = 8.5 / 24).
- **D7 · Friend-code row label.** `Today only` when the bind window closes today, otherwise
  `Until tomorrow at {HH:mm}`.
- **D8 · Sub-screens** are pushed routes, so the bottom bar is not under them; the pinned row
  sits on the bottom safe area instead of above the bar.
- **D9 · Hourly history summary.** `{c} claimed · {e} expired` when any cycle expired,
  otherwise `{c} claimed · {n} BNP`; `{n} BNP so far` when only the live cycle exists. The row
  is hidden with no history.
- **D10 · Leaderboard preview.** Top 3 plus your row (when ranked below 3). The whole block
  opens the full board; the header's right label is `You · #{rank}`.
- **D11 · App bar.** As Hub D5: the shared bar stays (search, bell, space chip), titled
  `Mine`, with `history` and `help` added for the Mine tab only. This is the one edit to the
  main shell.
- **D12 · Copy the design does not draw.** Kept to the minimum and in the same voice:
  `Code copied` (after Copy), `Friend linked` (after a code is entered), the bind sheet
  (`Enter a friend's code`, `Link code`, `Codes are 8 characters.`, `That code doesn't
  exist.`), `No one has claimed BNP yet.`, `No hours mined yet.`,
  `Couldn't load your friends. Pull to retry.`, the `INACTIVE` pill for a friend who never
  mined, and `Inactive friends' +5% counts again when they mine.` for more than one.
- **D13 · Pushes (state 12)** are backend copy and were not changed here. The design reads
  `132 BNP ready to claim` / `Tap to claim and start your next cycle.` and `132 BNP expires
  in 3h` / `Claim it before it's gone.`; `mining-reminder.messages.ts` still sends
  `Your BNP is ready` / `Claim 132 BNP and start your next cycle.` and
  `132 BNP expires in 3 hours` / `Claim now or your 132 BNP is forfeited.`
