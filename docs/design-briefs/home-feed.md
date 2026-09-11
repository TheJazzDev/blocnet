# Design brief — Blocnet home feed

**Paste this into Claude Design, and attach the six screenshots in
`docs/design-briefs/reference/`.**

Those screenshots are there so you know the real icon language, the real content
density and the real copy. **They are not a layout to preserve.** The current
arrangement is what we are trying to get away from. Take the material, leave the
structure.

---

## Read this first, or nothing else will land

On X and Telegram, someone calls a token once and walks away. Followers pile in, farm
it, buy it. Then nothing. The caller has no obligation to say what happened next.

That leaves the user holding a job they cannot do. If you are farming fifteen projects
across six months, you personally have to remember that one opened KYC on Tuesday,
another ends its mining phase Friday, and a third moved its snapshot. Miss one and
months of work evaporates.

**Blocnet does not sell discovery. It sells not missing anything.**

A **hunter** finds a project — a **gem** — does the diligence, posts it, and is then
obligated to keep updating it through its entire lifecycle. One gem has exactly one
owner, because accountability that is shared is accountability that is nobody's. The
hunter is paid back in tips from members who made money, in reputation, and in paid
placements from projects that want their audience. They are held honest by liability:
call a scam and the community reports you and you lose your standing.

A **member** follows the five gems they actually care about out of two hundred, then
goes and lives their life. They are never tracking anything themselves. When their
hunter posts, they act.

Full context: `docs/PRODUCT.md` in the repo.

## The user, and their day

Crypto-native. Farming or holding across more projects than any person can track. They
are not browsing. They already used X this morning and it told them nothing they can
act on.

They open Blocnet for one reason: **to find out whether anything needs them.**

## The job of this screen

In priority order.

1. **Tell me nothing has slipped.** Across every gem I follow.
2. **Tell me what needs me, and by when.** A deadline I can still act on is the single
   most valuable thing in the product.
3. **Let me act on it** without hunting for the button.
4. **Show me my hunters are doing their job** — that the gems I follow are being kept
   current, not abandoned.
5. **Let me pay someone back** when their call made me money.

## The emotional target

One sentence, and everything should serve it:

> **"I would have missed that."**

The moment a member realises Blocnet just saved them is the whole product. Design to
produce that feeling as often as possible.

And the corollary most designers get backwards: **a quiet feed is this product
succeeding.** "Nothing needs you. All five gems current, checked two minutes ago" is
what people are paying attention for. It should read as **cover**, like a system that
has your back, not as an empty room apologising for itself. Do not treat the calm state
as a failure to fill.

## What a gem is, and the part that does not exist yet

A gem is a project a hunter found and now owns: an airdrop, a token in its mining phase,
an IDO, a testnet.

It moves through a **lifecycle** — mining, KYC, snapshot, IDO, distribution, ended —
and that movement is what a member actually needs to know.

**Two things the product needs and the codebase does not have yet:**

1. **A lifecycle stage on a gem.** Today `ProjectStatus` is only active/paused/hidden/
   archived, which are moderation states.
2. **A deadline on an update.** Nothing anywhere carries an action window.

**Design as though both exist.** We will build them. Do not design around their absence
— that is exactly how the current screen ended up unable to say the one thing that
matters. Assume a gem knows what phase it is in and that a time-sensitive update knows
when it closes.

## Real material

### Content that exists today

| Field | Values |
|---|---|
| Author | display name, @handle, avatar, level 1–15, role badge |
| Role badge | `HUNTER`, `CORE TEAM`, `MODERATOR`, `ADMIN`, or none |
| Gem | name, logo, follower count |
| Urgency | high, medium, low |
| Tag | Alpha, Airdrop, Partnership, Warning, Info, General |
| Title and body | a sentence to several paragraphs, often with emoji |
| Engagement | likes, comments, bookmark, share, **tip** |
| Alpha Radar | unseen high-urgency count, **already grouped per gem with a per-gem count** |
| Edge Engine (BEE) | per gem: signal count and a verdict of `act`, `watch` or `ignore` |

### Icon language

The app uses **Material Icons, rounded and outlined**, 210 of them. Use real Material
icon names, not invented glyphs. The ones it leans on:

`layers_outlined` · `bolt_rounded` · `radar_rounded` · `diamond_outlined` ·
`flag_outlined` · `trending_up_rounded` · `favorite_rounded` · `swap_horiz_rounded` ·
`verified_rounded` · `volunteer_activism_outlined` (tipping) · `visibility_outlined` ·
`chevron_right_rounded` · `account_balance_wallet_outlined` · `groups_outlined` ·
`explore_outlined` · `home_rounded` · `person_rounded` · `shield_rounded`

### Copy that is real

Hunters write like this, emoji included:

> "This is not just about mining ⛏️ You get to see updates on other airdrops. All in
> one. 👌 Stay tuned and mine bnt agressively 🔥"

> "Core Mining Pool Difficulty Update"

Gems in the live data: Core Mines, Bless50ing. Hunters: @jazzdev, @bless50ing,
@abtoonzz. The economy is **BNP** today, **BNT** at mainnet.

## Hard constraints

Already shipped and verified. Not negotiable.

- **Dark only.** Ground `#09090b`, surfaces `#18181b` / `#27272a`, borders `#27272a`.
- **Signal Cyan.** `#0891B2` in User space, `#22D3EE` in Hunter space. Red `#EF4444`
  is moderation and destructive only, never brand.
- **Type** (px): 11 caption, 13 label, 15 body, 17 subtitle, 20 title, 24 headline,
  32 display, 48 display-xl. Body never below 15.
- **Spacing** on a 4pt grid: 2, 4, 8, 12, 16, 24, 32, 48.
- **Corners**: 8 small, 12 default, 16 panels, 20 sheets, full for pills.
- **Platform font.** Flutter inherits the system face. Design in system-ui.
- **Do not rename or re-order the bottom tabs.** Six destinations stay as they are.
  Navigation is a separate decision and should not ride along with this.

## What is yours to change

Everything else. Do not assume the current screen's answer to any of these.

- Whether the feed is a list of posts at all. It might be a list of **gems and their
  state**, with updates underneath.
- How a deadline reads. This is the most important unsolved thing on the screen.
- How "you are covered" is expressed when nothing needs the user.
- Where the Edge Engine verdict lives and how much room it earns.
- How a hunter's reliability becomes visible — cadence and coverage, not just a badge.
- Where tipping appears. It currently hides in a profile, and it should be near the
  moment value is realised.
- Motion. There is none today, and a feed that never moves feels dead.

## What to produce

**Three genuinely different directions**, not three skins. Phone screens at 390 × 844.

Each direction must show **three states**, because the third is where the current app
fails hardest and where the product's promise is either kept or broken:

1. **Something needs you.** Two gems have time-sensitive updates, one closing soon.
2. **You are covered.** Five gems followed, everything current, nothing to do.
3. **New user.** Follows nothing, no signals yet.

Say in one line what each direction bets on, and one line on how it produces *"I would
have missed that."*

## What good looks like

- A member can answer "does anything need me?" in under two seconds, without reading.
- Deadlines are impossible to miss and obviously actionable.
- The calm state feels like insurance, not like an empty inbox.
- It could only be Blocnet. Swap the gem names and it should still be recognisable as
  this product and no other.

## What to avoid

- A generic crypto dashboard: a grid of equal stat cards with a corner icon in each.
- Purple-to-blue gradients. Phantom owns purple; the brand is cyan.
- Treating this as a social timeline. Engagement is secondary; coverage is the point.
- Invented glyphs where a real Material icon exists.
- Designing around the missing lifecycle and deadline data. Assume it.
