# Design brief — Hunter Hub

**Paste this into Claude Design.** Attach, as the visual vocabulary to reuse, the approved
*Blocnet Home Feed v2* canvas, and a screenshot of today's Hunter Hub as the thing being
replaced — **not** a layout to preserve. Design this one screen only.

---

## What this screen is for

Blocnet exists because on X and Telegram a caller posts a project once and walks away.
On Blocnet, the person who posts a gem — the **hunter** — is **obligated to keep it
updated for as long as it runs**. Members follow a handful of gems and stop tracking them
themselves; they rely on the hunter to tell them when KYC opens, when mining ends, when the
snapshot moves. That obligation *is* the product.

A hunter opens the Hub to answer one question:

> **Which of my gems need me right now, and who is waiting on me?**

…and then to act on it: post the update. Everything else on the screen is secondary to
that. Their standing, their tips, their audience — those are the *consequence* of doing
this job well, and they belong on the screen as a quiet receipt, not as the headline
furniture.

Today's Hub has the priorities upside down. It leads with a tip balance, a "success rate"
that measures how often the hunter labelled a post urgent, a season leaderboard and an
"Elite Hunter" banner — and it never shows the hunter which of their gems has gone quiet.
Members can already tap **Ask the hunter** on a quiet gem; today that request reaches the
hunter nowhere visible. This redesign fixes that.

## Who is looking at it

An analyst, not a promoter. They own somewhere between one and a dozen gems. They are
proud of their record and slightly anxious about slipping. They should be able to open
the Hub, see in two seconds that everything is fine — or exactly which gem isn't — and get
to the composer in one tap.

## The reliability the Hub reports

Owner decision: a hunter's **reliability** is the score members judge them by. It is built
only from things the platform actually observes:

- **Coverage** — how many of their gems were updated in the last 14 days. *"4 of 5 gems
  current."* This is the headline number.
- **Response** — when members asked for an update, how often one followed within a week.
- **Cadence** — the typical number of days between their updates.
- **Standing** — one word derived from coverage: **Reliable**, **Slipping**, **Quiet**,
  or **New** (no gems yet, or first gem under two weeks old).

Reach sits beside it, visibly separate: tips received (in BNT/BNP), followers across
their gems. Reach is not reliability, and the design should make that distinction legible.

## Each gem on the board

The body of the screen is the hunter's gems, **most in need first**. Each gem shows:

- name, logo, primary tag, follower count
- its **state**: *Current* · *Due* (10+ days since last update) · *Quiet* (14+ days)
- the **last update** — its title and when (*"Mining phase extended · 12 days ago"*); a gem
  never updated says so and counts from the day it was listed
- **members waiting** — how many asked for an update this week (*"31 members waiting"*),
  shown only when non-zero
- **open reports** — members who reported the gem as unmaintained, shown only when
  non-zero; this is the escalation a moderator sees
- the **next stated deadline** on the gem, if any (*"Closes Friday 18:00 UTC"* — a stated
  time, never a countdown)
- a **Post update** action that opens the composer with this gem already selected

Tapping the gem opens its own page: the hunter's updates on it as a timeline, each one
editable.

Also on the Hub, only when they exist: **pending invites** to co-own a gem (accept /
decline) and **gems submitted for review** with their status. And one entry to submit a
new gem.

## States to show — all six, on one canvas

1. **All current.** Five gems, all updated recently, nobody waiting. This must feel like an
   earned calm — the same spirit as Home's *"You're all caught up"* — not an empty room.
2. **One gem slipping badly.** Five gems; one is Quiet at 19 days with 31 members waiting
   and 2 open reports; one is Due at 11 days; three current. Standing: Slipping.
3. **Day one as a hunter.** Role just granted, no gems yet. What a hunter does first:
   submit a gem, or accept an invite. Standing: New.
4. **Invites and reviews.** Two gems owned, one pending invite, one gem under review.
5. **A dozen gems.** How the list holds up at 12, with mixed states. Nothing should need a
   second screen to find the gem that needs attention.
6. **The gem page.** Opened from state 2's quiet gem: its timeline of updates (edit on
   each), the waiting count, the reports, Post update.

## Rules that are not negotiable

- **Never invent a number to fill a slot.** If the platform does not track it, it is not on
  the screen. No "profit generated", no "accuracy", no "rank #3 this season".
- **Never claim knowledge the platform does not have.** The hunter reports a third-party
  project from the outside. No lifecycle rails, no "step 2 of 6", no progress bar toward an
  end nobody knows.
- **Red budget: one red object per card, and red means moderation or destruction.** Open
  reports may use it. *Quiet* is the hunter's own obligation, not an alarm raised by
  someone else — find a treatment that is serious without being red, and do not stack
  red with the Ruby level badge (`#E23D4A`).
- **Deadlines are stated times**, never clocks or draining bars.
- **Hunter space accent is Signal Cyan `#22D3EE`.** Use the shipped five-tier level badges
  (Iron, Jade, Amethyst, Gold, Ruby) beside the hunter's name, as the Home feed does.
- **Remove:** Season ranking (the full reliability leaderboard lives on the Gems tab),
  the Elite Hunter banner, the "Success rate" tile, the made-up ticker on gem cards.
- Phone width 390, dark theme, same type and spacing scale as the Home Feed v2 canvas.
- **Bottom bar in the Hunter space:** Home · Gems · Hub · Mine · Wallet · Profile, with
  one-word labels. The composer button stays; from the Hub it opens *Post update*.

## Copy to use as written

- Standing words: **Reliable**, **Slipping**, **Quiet**, **New**.
- Gem states: **Current**, **Due**, **Quiet**.
- *"{n} members waiting"* · *"{n} reports"* · *"Last update {time} ago"* ·
  *"No updates yet · listed {time} ago"*.
