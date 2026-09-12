# Design brief — home feed, round five: it is a feed, not a dashboard

**Paste this into Claude Design with the six screenshots in
[`reference/`](reference/).** Those screenshots are **the thing to build on**, not a
layout to replace. Read [`PRODUCT.md`](../PRODUCT.md) first.

---

## 0 · What happened, so it is not repeated

Rounds two, three and four built a dashboard. It was reviewed against the real app and
rejected. The cause was the brief, not the drawing, and it is worth stating plainly.

`PRODUCT.md` says Blocnet does not sell discovery, it sells *not missing anything*. That
is a **reason to use the product**. Round two turned it into the literal shape of the
home screen and offered three directions — *Deadline Ledger*, *Coverage Board*, *The
Queue*. Those are three names for one idea: a to-do list. Every round after refined a task
manager, and the writing followed: *needs you*, *handled it?*, *dismiss to clear the
count*, *not being kept*. Opening it felt like opening a ticket queue at work.

Worse, it deleted the things that make Blocnet a social network:

| The real app has | The dashboard replaced it with |
|---|---|
| A hunter's round avatar, display name, @handle and a HUNTER / CORE TEAM role badge | a 13px grey byline |
| The hunter's own voice, emoji and all | clipped operational prose |
| Purple, cyan, red, amber and orange doing categorical work | one cyan on grey |
| Real project logos | grey letter tiles |
| A browsable curated feed for a brand-new user | two boxes reading "Empty slot" |

**Do not produce a dashboard. Do not rename things into obligation language.** No
"coverage", no "needs you", no counts of chores waiting.

## 1 · What the home screen is

**A social feed of hunter updates.** People posting about gems they cover, to members who
follow those gems. That is the product and it is already right. This round keeps it and
adds intelligence as **treatment inside the feed** — an urgent post that looks urgent —
rather than as a new organising structure.

## 2 · The card as it exists today

From `feed_card.dart`, top to bottom:

1. **Header** — author avatar, display name, level badge, role chip (HUNTER, CORE TEAM),
   timestamp, and a priority pill (HIGH / MEDIUM / LOW)
2. **Project chip** with a gradient — *"in Bless50ing"*
3. **Secondary tags** — AIRDROPS, MINING, IDO…
4. **Update text** — the hunter's own words
5. **Action row** — like · comment · share | bookmark

Above the feed sit three blocks: an **Alpha Radar** card, a **Blocnet Edge Engine**
teaser, and a **Top Hunters** row of circular avatars. The feed has two tabs, *Updates*
and *General*.

Everything here may be restyled, reordered, merged or cut — but the **kind** of thing it
is must survive. Judge any change by whether a member can still see who is talking, hear
how they talk, and reach the project in one tap.

## 3 · What to add — five problems, not five solutions

**a. An urgent post should feel urgent before it is read.** Today HIGH is a small red pill
in the corner of an otherwise identical card. A member thumbing past at speed should feel
the difference. Priority is the field that already exists and already carries this.

**b. A time-critical post should say when it closes.** We are adding a **nullable deadline
to an update**. When it is set, the card carries a live countdown. When it is not — which
is most of the time — nothing is drawn and nothing is implied.

**c. A gem whose hunter has gone quiet should surface on its own.** The whole promise
rests on hunters keeping gems current, and today nothing tells a member that the hunter
they rely on has not posted in 23 days. This is the product's real failure mode. It needs
a home **in the feed**, not a separate mode or a second screen.

**d. "Nothing new" is the product keeping its promise, and it currently looks like a
disabled state.** The Alpha Radar card says *"You are fully caught up"* in a grey box.
That is the moment a member learns they can stop checking. Make it feel earned.

**e. Tipping is missing from the action row.** Like, comment, share and bookmark are
there; tip is not. Tip is the one that pays a hunter for the obligation they just
honoured, and the feed is where the value lands.

## 4 · The empty case — the most important state in this brief

**A member who follows nothing must get a screen worth scrolling.** Today the app already
does this well and the dashboard broke it: Discover serves a curated feed sorted by a hype
score, with project logos, chain, follower and update counts, who hunted each gem, and a
Follow button on every row.

Design the home screen for a member with **zero follows**. It should be browsable,
specific and genuinely interesting on day one, and the path into following something
should be obvious without a single empty box on screen. Decide and show how much of
Discover's job Home should do in this state, and how the screen changes as the member
follows their first, third and tenth gem.

## 5 · Facts to design against

- **Tags.** A project has one **primary tag** — the chain (Core, Solana, Ethereum, Ice
  Open Network, Telegram Network, Binance Smart Chain) — and up to twenty **secondary
  tags** — the categories (Airdrops, IDO, Mining, Farming, Staking, Launching,
  Partnership, Governance, Token Burn, NFT, Trading, Gaming, Wallet, Security, Metaverse).
- **Priority** on an update is high / medium / low.
- **Edge Engine** emits, per gem, a signal count and a verdict of `act`, `watch` or
  `ignore`.
- **Updates carry no images.** Title, text, tags, priority, counts. Do not design
  photo-led cards; there are no photos.
- **Hunter reliability is knowable** from when they last posted. Nothing else about it is.

**The trap, stated so it is not walked into again.** Nobody on Blocnet knows what
lifecycle stage a project is in, or how many stages it has. A hunter observes a
third-party project from outside and reports after the fact. **No phase rails, no
denominators, no "step 2 of 6", no progress toward a known end.** Round four was withdrawn
over exactly this.

## 6 · Constraints

- Dark only. Ground `#09090b`, surfaces `#18181b` / `#27272a`, borders `#27272a`.
- Signal Cyan `#0891B2` User, `#22D3EE` Hunter — that is the **brand** accent.
  **Do not collapse the palette to monochrome.** Role badges, category tags and priority
  keep their own colours; the app reads as flat and administrative without them.
- Red is moderation, destructive and HIGH priority only.
- Spacing on a 4pt grid. Corners 8 / 12 / 16 / 20 / full.
- Material Symbols Rounded, real icon names.
- Platform font, system-ui. **32px is the ceiling.** Body copy 15px, labels 13px.
- **Do not rename or re-order the bottom tabs.** Home / Discover / Community / Mining /
  Wallet / Profile.
- The app has three spaces — user, hunter and moderation — and **all three render this
  same Home screen**. Design the user space; note anything that would obviously differ.

## What to produce

The home feed in five states:

1. **A member with zero follows** — the day-one screen
2. **A normal day** — a mixed feed, mostly low and medium priority
3. **Something urgent is live** — one high-priority post with a deadline, in a feed that
   also contains ordinary posts
4. **Fully caught up** — nothing new since the last visit
5. **A hunter has gone quiet** on a gem the member follows

Plus **the card itself, at rest and in its urgent form, side by side**, so the difference
between the two is legible on its own.

Note in one line what makes an urgent post feel urgent without turning the feed into a
task list.
