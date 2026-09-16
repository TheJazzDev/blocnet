# Design brief — Gems (today: Discover)

**Paste this into Claude Design after the Hunter Hub brief is approved** — they share the
reliability vocabulary, and Hub settles it first. Attach the approved *Blocnet Home Feed v2*
canvas as the visual vocabulary, and the shipping Discover screenshot
(`reference/02-discover.png`) as the thing being replaced, **not** a layout to preserve.
Design this one tab only.

---

## What this tab is for

A Blocnet member follows a handful of gems and then stops tracking them — the hunter who
owns each gem is obligated to post every time it moves. So the most important decision a
member makes on Blocnet is not *what to read*. It is **what to put on their board, and
whose word to rely on for it.** Following a gem is delegating the tracking of it to a
specific person.

This tab is where that decision is made, and where the member looks after what they chose.
It answers three questions, one per view:

1. **Discover — what is worth following?** Gems on the platform, and for each one: what it
   is, whether it is alive, and **who keeps it and how reliably**.
2. **Your board — how are my gems doing?** The gems I follow, each with its newest update
   and whether its hunter has gone quiet.
3. **Hunters — whose word is good?** The people who keep gems, ranked by reliability.

Today's Discover answers none of these well. Its card leads with a "hype" decimal that is
really followers and post count, never shows when the gem was last updated, and shows the
hunter as a name with no record behind it. The "My Gems" sub-tab repeats Profile's
Following list. Home's old *General* tab, Trending and three priority screens all showed
"every post, newest first" — those are being removed, and the part of their job worth
keeping (*what's moving across Blocnet right now*) lands here.

## The reliability vocabulary (settled in the Hunter Hub brief)

Each hunter has a **standing** — **Reliable**, **Slipping**, **Quiet**, or **New** — derived
from **coverage** (*"4 of 5 gems current"*: share of their gems updated in 14 days). Also
**response** (how often they post after members ask) and **cadence** (typical days between
updates). Reach — followers, tips — is shown separately and never presented as trust.

## The gem card

The card must let a member decide in one look. Show:

- name, logo, primary tag and up to two secondary tags (Airdrop, Mining, IDO…)
- **the newest update's title and when** (*"KYC opened · 2 days ago"*), or *"No updates yet"*
- the next **stated deadline** if one exists (*"Closes Friday 18:00 UTC"*)
- **the hunter who keeps it**: avatar, name, level badge, **standing word** and coverage
- follower count
- **Follow** — the single most important action in the product; it should feel like it.
  Once followed, the card says so and offers the notification preferences that already
  exist.

Tapping the card opens the gem page (below). Tapping the hunter opens their profile.

## The views

**Discover.** Ranked list of gems. Sort options that mean something: *Most active*
(recent updates), *Most followed*, *Newest*. Filter by tag category. A short section at the
top, **Moving across Blocnet**, shows the handful of gems with the most recent updates —
this is what replaces the old General/Trending job. Drop the hype decimal.

**Your board.** The member's followed gems, **most in need of them first**: a gem with a
deadline this week, then gems with updates since the member last looked, then the rest.
A gem whose hunter has gone quiet says so, with the **Ask the hunter** action already
shipped on Home. Unfollow from here. Zero follows → an empty state that sends the member to
Discover in their terms (*"Pick the gems you're farming — a hunter keeps each one
covered"*), not an apology.

**Hunters.** Leaderboard by reliability: standing, coverage, response, gems kept,
followers. One ranking for the whole app — it replaces four different "top hunters" lists.
Tapping a hunter opens their public profile.

**Gem page** (opened from any card). The gem's details; its hunter with standing and
coverage; **its updates as a timeline**, newest first, with deadlines; follow; members
waiting if its hunter is quiet. This page replaces today's gem dialog.

## States to show — all on one canvas

1. **Discover, default.** Eight gems with mixed hunters: one Reliable, one Slipping, one
   Quiet, one New. *Moving across Blocnet* above.
2. **Discover, filtered to a tag with no results.** Honest empty state; clear filter.
3. **Your board, a working board.** Six gems: one with a deadline tomorrow, two with new
   updates, one quiet gem with 31 members waiting, two current and calm.
4. **Your board, zero follows.**
5. **Hunters.** Ten hunters across all four standings; the member's own followed hunters
   distinguishable.
6. **Gem page** for the quiet gem in state 3, and for a healthy gem — side by side.

## Rules that are not negotiable

- **Never invent a number to fill a slot.** No hype decimals, no price, no APY, no
  "potential".
- **Never claim knowledge the platform does not have.** A hunter observes a third-party
  project from the outside: no lifecycle stages, no "step 2 of 6", no progress bars.
- **Red budget: one red object per card**, and red means moderation or destruction. A
  Quiet hunter is information for the member, not an alarm; do not stack red with the Ruby
  level badge (`#E23D4A`).
- **Deadlines are stated times**, never countdowns.
- **User space accent is Signal Cyan `#0891B2`.** Use the shipped five-tier level badges.
- Priority (High/Medium/Low) belongs to updates, not gems — do not filter gems by it.
- Phone width 390, dark theme, same type and spacing scale as the Home Feed v2 canvas.
- **Bottom bar (User space):** Home · Gems · Community · Mine · Wallet · Profile, with
  one-word labels. Search stays in the app bar.

## Copy to use as written

- Views: **Discover**, **Your board**, **Hunters**. Section: **Moving across Blocnet**.
- Standing words: **Reliable**, **Slipping**, **Quiet**, **New**.
- *"Kept by @{hunter}"* · *"{x} of {y} gems current"* · *"Last update {time} ago"* ·
  *"No updates yet"* · *"{n} following"*.
