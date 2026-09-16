# Hunter Hub — build spec (extracted from the approved design)

> Source of truth: [`../artifacts/blocnet-hunter-hub.html`](../artifacts/blocnet-hunter-hub.html)
> (Claude Design project *Blocnet Design System*, file *Blocnet Hunter Hub.html*, approved
> 2026-09-16). Brief: [`hunter-hub.md`](hunter-hub.md).
>
> Method (from [`NEXT_SESSION.md`](NEXT_SESSION.md)): every state below was extracted from
> the design file **before** code. Build to these lists. Walk every state against them before
> calling it done. Verify on the emulator.

---

## Tokens used by the design (map to `AppColors`; add any that are missing)

| Role | Hex |
|---|---|
| ground | `#09090b` · surface `#18181b` · border `#27272a` · row hairline `#1b1b1f` |
| hunter accent | `#22D3EE` (text/pips) · button fill `#0891B2` |
| text | `#fafafa` · muted `#a1a1aa` · dim `#71717a` · caption `#6b6b73` · body-2 `#d4d4d8` · faint `#8b8b93` |
| quiet (orange) | `#FB923C` — edge 3px, ground `linear(#1b1510→#121011)`, chip bg `#fb923c26` |
| due (amber) | chip `#F59E0B` on `#f59e0b26`; edge 3px `#78350f` |
| reports (red) | `#F87171` — the only red on the screen |
| pending invite | violet `#A78BFA` on `#a78bfa24` |
| current tick | `#3f9c86` |
| reliability card | reliable: `linear(#111a1d→#101113)` + inset 1px `#22d3ee2e`; slipping: `linear(#1d1710→#121110)` + inset `#fb923c33`; new: `#101012` + inset `#232327` |
| reach tiles | `#101012` + inset `#1f1f23`, radius 12 |

Chain chip colours (by primary tag): CORE `#FB923C`, TELEGRAM `#38BDF8`, SOLANA `#34D399`,
ETHEREUM `#818CF8`, BSC/Binance `#FBBF24`, ICE `#22D3EE`; bg = colour at ~12% alpha; unknown
tag → neutral `#27272a`/`#a1a1aa`. Gem logo = two-letter monogram on a gradient of the same
hue (projects have no logo column).

Type: 32 coverage figure · 24 day-one title · 20 gem-page name · 17 name/metrics · 15 row
titles/body · 13 meta · 11 caps labels (letter-spaced). Radii: card 16, tiles/inv 12, logo 12
(40px) / 8 (32px) / 14 (52px), buttons 10, chips pill.

---

## Shell (all Hub states)

1. Status bar
2. **App bar** — see decision D5
3. Identity row: avatar 44 · **name** · tier-shaped level badge (18px, shows level number) ·
   `HUNTER` chip · second line `@handle · {Tier} · {Level name}`
4. …state body…
5. **FAB, extended pill** bottom-right: `✎ Post update` (opens composer, no gem selected). Day
   one: `+ Submit a gem`.
6. **Bottom bar with labels:** Home · Gems · Hub · Mine · Wallet · Profile. Icons: home,
   diamond, shield (filled when on), bolt, account_balance_wallet, person. Active = accent.
   (User space: slot 3 = Community; Moderation space: slot 3 = Moderate.)

## State 1 · All current (5 gems, nobody waiting)
1. Shell 1–3
2. Reliability card (reliable style): `RELIABLE` chip · right label `LAST 14 DAYS` →
   `5 of 5` + `gems current` → sentence *"Every gem you own has an update from the last 14
   days."* → pips (one per gem, cyan) → divider → metrics `4 of 4 RESPONSE` · `5 days CADENCE`
   · `0 WAITING`
3. Reach row: `volunteer_activism 18,240 BNP · TIPS` | `groups 26,465 · FOLLOWERS`
4. Section `layers YOUR GEMS` · right `5 CURRENT`
5. Five condensed current rows: 32px monogram · name · chain chip · `{followers} · {ago}` · tick
6. FAB `Post update` · bottom bar

## State 2 · One gem slipping (5 gems: 1 quiet, 1 due, 3 current)
1. Shell 1–3
2. Reliability card (slipping style): `SLIPPING` · `LAST 14 DAYS` → `3 of 5 gems current` →
   *"Halo Points is quiet at 19 days. Terra Vault is due."* → pips 3 cyan + 2 orange →
   `2 of 5 RESPONSE` · `9 days CADENCE` · `38 WAITING`
3. **No reach row** (see D6)
4. Section `YOUR GEMS` · `2 NEED YOU`
5. Quiet row (expanded, orange edge + warm ground): 40px monogram · name · chain chip ·
   `4,730 following` · `QUIET` chip → *"Farming round 2 is live · last update 19 days ago"* →
   meta `how_to_vote 31 members waiting` (cyan icon) · `flag 2 reports` (red) → buttons
   `✎ Post update` (filled) · `Open gem` (outline)
6. Due row (amber edge): same header with `DUE` → last line → `schedule Closes Friday 18:00
   UTC` (only if a future deadline) → `7 members waiting` → (actions: see D2)
7. Section `CURRENT` · `3 GEMS` (no icon)
8. Three condensed current rows

## State 3 · Day one (no gems)
1. Shell 1–3 (Iron badge)
2. Zero card: shield ring 72 → **"You're a hunter now"** → *"A gem is a project you found and
   now own. You post it, and you keep posting every time it moves — that obligation is what
   members follow you for."* → step 1 **Submit your first gem** / *Diligence, then a first
   update* › → step 2 **Or accept an invite** / *Co-own a gem already running* ›
3. Section `STANDING`
4. Reliability card (new style): `NEW` · right `NO GEMS YET` → *"Coverage starts counting once
   your first gem is two weeks old. Nothing is scored before there is something to report."*
   (no fraction, no pips, no metrics)
5. Section `HOW RELIABILITY IS MEASURED`
6. Three lines: *Coverage — gems updated in the last 14 days. / Response — asks that got an
   update within a week. / Cadence — your typical days between updates.*
7. FAB `+ Submit a gem` · bottom bar
No reach row.

## State 4 · Invites and reviews (2 gems current, 1 invite, 1 in review)
1. Shell 1–3
2. Reliability card (reliable): `2 of 2` · *"Both gems have an update from the last 14 days."*
   · 2 pips · `3 of 3` · `4 days` · `0`
3. **No reach row** (D6)
4. Section `mail NEEDS YOUR ANSWER`
5. Invite card (cyan inset): 32px monogram · name · `INVITE` chip (violet) → *"**@abtoonzz** is
   handing over coverage. 12,740 followers, 34 updates posted, last one 2 days ago. Accept and
   the obligation is yours."* → `Accept` (filled) · `Decline` (outline), equal width
6. Review card (neutral inset): monogram · name · `IN REVIEW` chip (grey) → *"Submitted 2 days
   ago. A moderator is checking the diligence. You'll get a notification either way."*
7. Section `layers YOUR GEMS` · `2 CURRENT`
8. Two condensed current rows

## State 5 · A dozen gems (2 quiet, 1 due, 9 current)
1. Shell 1–3
2. Reliability (slipping): `9 of 12` · *"Two quiet, one due. Aegis Node is the oldest at 21
   days."* · 12 pips (9 cyan, 3 orange) · `6 of 9` · `7 days` · `52`
3. No reach row
4. Section `YOUR GEMS` · `3 NEED YOU`
5. Quiet row — **compact copy**: *"… · 21 days ago"* (no "last update"), `28 waiting`,
   `3 reports`, buttons
6. Quiet row (compact) with `19 waiting`, buttons
7. Due row (compact) with deadline and `5 waiting`, **no buttons**
8. **Fold line**: tick · *"9 current, all posted this week"* · expand_more (expands to the
   condensed rows)

## State 6 · Gem page (opened from a quiet gem)
1. Status bar
2. Header: back · *"Your gem"* (15) · more_horiz
3. Gem header: 52px monogram · name (20) · chain chip · `4,730 following` · `QUIET`
4. Wait card (warm): `how_to_vote 31 members are waiting` → *"They asked for an update this
   week. One post clears all of them — they're notified the moment you publish."* (only if > 0)
5. Report card (red inset): `flag` · **2 reports** · *Unmaintained* (only if > 0)
6. Buttons: `✎ Post update` (filled, gem pre-selected) · `Hand over` (orange outline) — D4
7. Timeline (1px rail, 11px nodes, newest node cyan):
   - Gap card (warm) `more_horiz 19 days without an update` — only when the gem is quiet
   - Event: `20 AUG · HIGH` … `✎ Edit` → title (15/650) → `412 likes · 38 comments · 2,100
     BNP tipped` (tips omitted when zero)
   - …older events, same shape
8. Bottom bar (Hub on). **No FAB.**

## Row anatomy (the spec panel)
- **Current:** one line — logo, name, chain, followers, last touched, tick.
- **Never updated:** due physique, *"No updates yet · listed 12 days ago"* (muted), single
  button `✎ Post the first update`.
- **Due:** amber edge; last line; deadline if stated; waiting.
- **Quiet:** orange edge + warmed ground; last line; waiting + reports; **the only state with
  inline actions**.
- Waiting and reports render **only when non-zero**. Red appears once, on the report count.
  Rows never carry a tier badge.

## Behaviour stated in the design
- **Posting clears the wait**: publishing an update on the gem zeroes its waiting count; the
  members in the wait are notified (they follow the gem, so the existing update notification
  covers it).
- **At 50 waiting** the gem enters the moderation queue for reassignment; the hunter and the
  member see the same threshold.
- **No member names reach the hunter** — waiting is a count only.
- Composer opens from the FAB with no gem, from any row with that gem pre-selected; it keeps
  the deadline field.
- Edit on a timeline event opens the composer in edit mode (`PATCH /updates/:id`).

---

## Decisions taken where the design contradicts itself

- **D1 · "gems current" counts state *Current* only.** The canvas numbers (3 of 5 with one due,
  9 of 12 with one due) count a Due gem as not current, while the label says "last 14 days".
  Built to the numbers: fraction and pips = gems in state Current (< 10 days); pip is orange for
  Due and Quiet. **Standing** (Reliable / Slipping / Quiet / New) still comes from the server's
  14-day coverage, as agreed.
- **D2 · Due rows carry no inline buttons.** State 2 shows them, but the anatomy panel says
  quiet is the only state with inline actions and state 5 agrees. Built to the written rule;
  the whole due row opens the gem page. Exception: a never-updated gem gets *Post the first
  update*.
- **D3 · Compact copy when the fold is active** (state 5): "· N days ago", "N waiting".
  Otherwise the full copy (state 2). Current rows fold behind one line when something needs
  the hunter **and** more than three gems are current; with three or fewer they list under
  a `CURRENT · N GEMS` header. Fold text says *"all posted this week"* only when true.
- **D4 · Hand over** needs a hunter-to-hunter handover invite that does not exist yet (invites
  are admin-only and mean co-own). It needs a schema change, which is sequenced after the BNP
  migration lands. Until then the button is **not rendered** (nothing tappable that isn't real).
- **D5 · App bar.** The canvas shows *Hub · history · settings* in place of the shared app bar.
  Home kept the shared bar (search, bell, space chip) and the space chip is how a hunter leaves
  the Hunter space, so the Hub keeps it too, titled **Hub**, with **history** added (opens *My
  updates*). **Settings is dropped**: there are no hunter settings to open.
- **D6 · Reach row** appears only in state 1 of the canvas. Built as: shown when nothing needs
  the hunter (reach is a receipt, and receipts wait until the work is done).
