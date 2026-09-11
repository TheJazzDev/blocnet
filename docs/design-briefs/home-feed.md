# Design brief — Blocnet home feed

**Paste this into Claude Design.** It deliberately does not describe the current screen.
The existing layout is what we are trying to get away from, and showing it would anchor
the work to it.

---

## The product

Blocnet is a mobile social network for crypto. People follow projects ("gems"), read
updates posted by vetted **hunters**, mine a token by running a daily cycle, complete
quests, and hold a wallet. It is social first and financial second: the feed is where
people live, and the money features hang off it.

The audience is crypto-native and young. They already use Phantom, Rainbow, Jupiter and
Farcaster daily, and they judge an app in about four seconds. The bar is not "clean
admin dashboard." The bar is an app someone opens because it feels good to open.

## The screen

The home feed. First thing after login, most-visited surface in the product.

### Its jobs, in priority order

1. **Show me what is new** in the projects I follow, with a sense of how urgent it is.
2. **Make me feel the pulse of the network** — that things are happening right now,
   even on a quiet day.
3. **Get me to react** — like, comment, bookmark, share, tip.
4. **Surface who is worth following** — hunters with a track record.
5. **Tell me when the system has something for me** — a personalised "Edge" signal, or
   a radar alert that a followed project is moving.

Job 2 is the one currently failing hardest, and it is the reason this redesign exists.

## The material you have

Every update in the feed carries:

| Field | Values |
|---|---|
| Author | display name, @handle, avatar, level (1–15), role badge |
| Role badge | `HUNTER`, `CORE TEAM`, `MODERATOR`, `ADMIN`, or none |
| Project | name and logo — the "gem" the update is about |
| Urgency | `high`, `medium`, `low` |
| Tag | Alpha, Airdrop, Partnership, Warning, Info, General |
| Title and body | body can be a sentence or several paragraphs, and often carries emoji |
| Timestamp | minutes to months old |
| Engagement | like count, comment count, bookmark state, share |

Also available on this screen, if you want them:

- **Alpha Radar** — whether the user is caught up, or has N unseen high-urgency updates.
- **Edge Engine** — an ML brief. Per followed project it emits a signal count and a
  verdict of `act now`, `watch`, or nothing. Often empty for new users.
- **Top Hunters** — a ranked row of hunters, each with an avatar and a name.
- **Live counts** — followers, updates today, miners active. Real numbers exist for these.

## Hard constraints

These are not negotiable because they are already shipped and verified.

- **Dark only.** Ground `#09090b`, surfaces `#18181b` and `#27272a`, borders `#27272a`.
- **Accent is Signal Cyan.** `#0891B2` in the normal (User) space, `#22D3EE` in Hunter
  space. Red `#EF4444` is reserved for moderation and destructive actions, never brand.
- **Type scale** (px): 11 caption, 13 label, 15 body, 17 subtitle, 20 title, 24 headline,
  32 display, 48 display-xl. Body copy must not go below 15.
- **Spacing** on a 4pt grid: 2, 4, 8, 12, 16, 24, 32, 48.
- **Corners**: 8 small, 12 default, 16 panels, 20 sheets, full for pills.
- **Platform font.** The app inherits the system face, so design in system-ui, not a
  brand font.
- Bottom tab bar with six destinations stays. A floating compose button stays.

## What you are free to change

Everything else. Specifically, please do not assume the current screen's answers to any
of these:

- Whether the feed is a list of cards at all. Consider density, grouping by project or
  time, a hero item, mixed cell sizes, horizontal rails.
- How urgency reads. It is currently a small coloured pill and it disappears.
- Where system status (radar, Edge) lives, or whether it is on this screen.
- Whether Top Hunters is a row, and where it sits.
- How the network's activity is made visible when the user's own feed is quiet.
- Motion. A feed that never moves feels dead; we have no motion design at all today.

## What to produce

**Three genuinely different directions**, not three variants of one idea. Each as a
phone screen at 390 × 844, showing the feed with real-feeling content: project names
like Nebula Swap, Orbit Lend, Core Mines; hunters like @ada, @satoshi, @jazzdev; bodies
that read like real crypto updates, including one with emoji.

For each direction, show the quiet state too — a user who follows nothing and has no
signals. That is every new user's first impression and it is where the current design
fails worst.

Say in one line what each direction is betting on.

## What "good" looks like here

- A first screen that is mostly content, not mostly chrome.
- Urgency and freshness legible at a glance, without reading.
- Somewhere the eye rests — one element per screen that is allowed to be large.
- It should look like it belongs next to Phantom and Jupiter, not next to an admin panel.

## What to avoid

- Generic dashboard layout: a grid of equal stat cards with an icon in each corner.
- Purple-to-blue gradients. Phantom owns purple and the brand is cyan.
- Anything that needs data we do not have. Stick to the fields listed above.
- Making the quiet state feel like an error.
