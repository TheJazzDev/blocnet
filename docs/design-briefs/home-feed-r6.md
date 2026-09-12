# Design brief — home feed, round six: five corrections

**Paste this into Claude Design with the round-five canvas** (*Blocnet Home Feed -
Social*). That direction is **approved**. This is a correction pass, not a redesign — do
not produce alternatives, do not restructure the feed, and do not revisit anything not
listed here.

---

## 1 · The live countdown goes — replaced by a stated time

**The biggest change, and the one that cascades.** Round five gave the urgent card a
ticking clock reading `06:12:44`, a red panel around it, and a draining progress bar. All
of it goes.

The reasoning is the product's, not a style preference. **The hunter already knows when
the window closes, and says so when they post.** *"KYC shuts tonight."* *"Snapshot is
Friday 18:00 UTC."* That is the fact. A clock counting down to the second adds no
information and implies precision the platform is not entitled to.

The bar is worse than redundant. Its full width can only represent the window's **total
length**, and nobody knows that — the hunter is reporting a third-party project from
outside. It is the withdrawn phase rail returning in a different costume. Cut it.

**What replaces it:** the deadline, stated once, in text, the way the hunter would say it.
Quiet, factual, legible at a glance, no animation of any kind.

**Data note, so this is designed correctly.** The field stays a **nullable timestamp** on
the update, because expiry has to be computable (a passed window must be able to grey
itself out, and notifications need to fire before it). **Store structured, render plainly.**
The design's job is the rendering.

**Show four renderings of the deadline on a card:**

1. **Days out** — e.g. *"Closes Friday 18:00 UTC"*
2. **Today** — e.g. *"Closes tonight"* — the only case that may carry any emphasis
3. **No deadline at all** — the common case; nothing is drawn and nothing is implied
4. **Already passed** — e.g. *"Window closed 9 days ago"*, stated rather than hidden

## 2 · Cut the red down to one object per card

Round five stacks four red things on the urgent card: a glowing red priority pill, a red
left edge, a red countdown panel and a red bar. Two of those leave with section 1. **Keep
one of the remaining two.** A post that is merely time-critical should not look like a
moderation event, and high priority will land most weeks — if it shouts every time, the
colour stops meaning anything.

**There is also a collision you cannot see from the mock.** The Ruby tier badge is
`#E23D4A`, and the urgent card's hunter is `@jazzdev` at level 15, which **is** Ruby. So a
red badge, a red pill and a red edge all sit on one card. See section 5.

**Red budget: one red object per card.** Red otherwise stays moderation and destructive.

## 3 · Settle the feed tabs — they currently change between states

Three different tab sets appear across one canvas:

| Where | Tabs shown |
|---|---|
| Day one | For you · Following · General |
| Every other state | Updates · General |
| Progression panel | says *Following* appears at three gems |

*Updates*, *For you* and *Following* are three different concepts used interchangeably.
**Pick one set, name each tab for what it actually contains, and use it in every state.**
It has to work at zero follows, at three and at ten. If the set genuinely must change as
the member's board fills, show the change as a deliberate transition rather than an
inconsistency, and say what triggers it.

## 4 · "Ask the hunter" needs a recipient model

The quiet-hunter card has a one-tap **Ask @ada**. In the mock that is a button; in reality
it is an unanswered product question. An earlier round noted *31 members are also
waiting*. **If thirty-one members tap it, does the hunter receive thirty-one
notifications?**

Design the interaction, not just the affordance:

- What the member sees **immediately after tapping** — the button cannot just sit there
- Whether the nudge is **private to the hunter** or **visible to other followers**
- Whether it **aggregates** (*"31 members are waiting on an update"* delivered once) —
  this is very likely the right answer, so show it
- Whether reaching a threshold **feeds the reassignment flow** the card already mentions,
  and if so make that legible to the member so the tap feels consequential

## 5 · Use the level badges that already exist

Round five renders levels as identical grey pills reading `LV 11`, `LV 14`, `LV 15`. There
is a **built, shipped five-tier badge system** with its own colour and frame shape per
tier, and fifteen named SVG badges bundled in the app. The feed is throwing it away.

| Tier | Levels | Shape | Colour |
|---|---|---|---|
| Iron | 1–3 | Circle | `#8A96A8` |
| Jade | 4–6 | Hexagon | `#2AA876` |
| Amethyst | 7–9 | Shield | `#8B5CF6` |
| Gold | 10–12 | Octagon | `#F0B429` |
| Ruby | 13–15 | Seal | `#E23D4A` |

The fifteen badges are, in order: newcomer, explorer, pathfinder, contributor, builder,
advocate, veteran, champion, elite, expert, guardian, master, legend, titan, pioneer.

**What to do.** Put the real badge beside the hunter's name at a size that stays
recognisable in a feed row (roughly 16–20px), and let the tier colour do the work the grey
pill is currently wasting. A member should be able to tell a seasoned hunter from a new one
without reading a number.

**Show one card three times** — with an **Iron**, an **Amethyst** and a **Ruby** hunter —
so the ladder is legible. Ruby is red, so resolve it against the red budget in section 2.

## 6 · What stays exactly as it is

Everything not listed above, and specifically: the card's fields and their order; the
avatar, display name, role chip, project chip and category tags; the hunter's own voice
and emoji; the full action row with **Tip**; the priority-drives-the-whole-card treatment
(edge, warmed ground, title from 17 to 20px) which is the round's best idea; the
chronological feed with no pinning and no task sections; the day-one screen borrowing
Discover's job; the earned caught-up state that keeps going below the fold; the
quiet-hunter card authored by Blocnet quoting the hunter's last words; Edge as a chip
below the tags, coloured on `act` only, grey on `watch`, never rendered on `ignore`; the
follow-progression panel; the bottom tabs.

**Unchanged constraints.** Dark only, ground `#09090b`, surfaces `#18181b` / `#27272a`.
Signal Cyan `#0891B2` / `#22D3EE`. 4pt grid, corners 8 / 12 / 16 / 20 / full. Material
Symbols Rounded. 32px type ceiling, 15px body, 13px labels. No phase rails, no
denominators, no progress toward a known end.

## What to produce

1. **Something urgent is live** — rebuilt with the stated deadline and one red object
2. **A hunter has gone quiet** — with the "Ask" interaction resolved, including its
   post-tap state
3. **The card at rest vs urgent**, side by side, redone
4. **A deadline panel** — the four renderings from section 1
5. **A badge panel** — the same card with an Iron, an Amethyst and a Ruby hunter

Plus the settled tab set applied to every state you redraw. Note in one line what carries
urgency now that the clock is gone.
