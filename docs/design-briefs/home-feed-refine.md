# Design brief — home feed, round three: refine B

**Paste this into Claude Design along with the v2 canvas.** Read
[`PRODUCT.md`](../PRODUCT.md) first if you have not; everything here assumes it.

---

## The decision

**Direction B, Coverage Board, wins. A and C are dropped.** Do not produce further
alternatives. This round refines B into the thing we build.

B won because it is the only one whose structure *is* the product. The feed is not
posts, it is the gems you follow and what phase each one is in. Two details in it solved
problems nothing else did:

- **`@jazzdev · touched 2h ago`** on every row. Hunter reliability made visible, and it
  works both ways: a member sees their hunter is active, a hunter sees when they slip.
- **`Radar swept 14 sources · 2 min ago`** in the covered state. Reassurance that does
  real work instead of just saying "all good".

Keep everything B already does: the summary line, the per-gem rows, the lifecycle track,
rows that expand in place when they need you, one line each when they do not.

## 1 · Bring these three things over from C

C is dead, but it solved things B did not.

**a. Tipping at the moment of value.** C put a full engagement row inside the urgent
card, ending in **`Tip @jazzdev`**. That is exactly right and B has nothing like it.
Tipping is the hunter's reward for the obligation they just honoured, and today it hides
in a profile. When a row expands because it needs you, that row should carry like,
comment, bookmark, share and tip — with tip visually distinct, because it is the one
that closes the loop.

**b. An item that needs you must not be silently scrollable past.** C guaranteed this by
making the feed a queue you empty. B cannot do that without becoming C, so find B's own
answer. Options worth exploring: the summary count stays pinned while any row is
unhandled; a row that needs you cannot collapse until acted on or explicitly dismissed;
the tab bar carries the unhandled count. Pick one and show it.

**c. A receipt in the covered state.** C's *"Checked for you today"* list — five gems,
each with a timestamp and a check — is cleaner than B's version of the same idea. It
proves the work happened. Take it.

## 2 · Fix the lifecycle track — the real problem

> **⚠️ WITHDRAWN 2026-09-12. This section was wrong. Do not build from it.**
>
> It asked for a track reading `Step 2 of 6 · KYC`, built from an ordered set of named
> phases a hunter defines per gem. Claude Design built exactly that, correctly, and the
> result is in the round-three artifact. The premise underneath it does not hold.
>
> A hunter does not run the project. They observe a third-party crypto project from the
> outside and report what they find, after it happens. So the denominator is a claim about
> the future that nobody on Blocnet is positioned to make. There is also no phase
> vocabulary in the system to draw from: secondary tags are categories (Airdrops, IDO,
> Mining, Farming, Staking…), not stages, and nothing anywhere knows the words KYC,
> Snapshot or Distribution. Secondary tags are a list of up to twenty besides, so one gem
> is legitimately Airdrop *and* Mining *and* Staking at once, which no single linear rail
> can hold. And most updates are not stages at all — "update your app to get the new
> feature" is a real urgent update that sits nowhere on a lifecycle.
>
> The correction and its replacement are in
> [`home-feed-r4.md`](home-feed-r4.md). The rest of this brief still stands.

*Original text, kept for the record:*

B's track reads **Mining → KYC → Snapshot → IDO → Distribution** for every gem. That is
wrong. An airdrop, a mining project and an IDO do not share phases. ~~A hunter defines an
ordered set of named phases for their gem, starting from a template chosen by gem type and
editable from there, then marks which one is current.~~ *(This is the part that does not
work. See the withdrawal note above.)*

## 3 · Solve two things neither direction attempted

**a. A hunter who has gone quiet.** Every mock shows hunters being diligent. The product's
actual failure mode is a hunter who posts a gem, collects followers, and abandons it.
What does the board look like when a gem has not been touched in **23 days**? This is the
most important unshown state in the product, because the whole promise rests on the
obligation being kept. Show it, and show what a member can do about it.

**b. The Edge Engine has no home.** BEE is a significant part of Blocnet and it appears
in none of the v2 directions. It emits, per gem, a signal count and a verdict of `act`,
`watch` or `ignore`. The board model suits it: a verdict is a property of a gem, which is
what B's rows already are. Find it a place that does not compete with the deadline.

## 4 · Scale

Every mock shows five gems. Show the board with **twenty**. What collapses, what groups,
what the summary says, and whether "current" gems need a section that is closed by
default.

## 5 · Type

B's scale is right and does not need changing. For reference, what it already uses:
32px for the summary count, 24px for the covered headline, 17px for the countdown, 15px
body, 13px labels, 11px track labels. **Treat 32px as the ceiling** — the 48px countdown
from A and C is gone with them.

## 6 · Unchanged constraints

- Dark only. Ground `#09090b`, surfaces `#18181b` / `#27272a`, borders `#27272a`.
- Signal Cyan `#0891B2` User, `#22D3EE` Hunter. Red is moderation and destructive only.
- Spacing on a 4pt grid. Corners 8 / 12 / 16 / 20 / full.
- Material Symbols Rounded, real icon names. The v2 round did this well.
- Platform font, system-ui.
- **Do not rename or re-order the bottom tabs.** This was asked last round and the tabs
  came back as Feed / Gems / Mine / Quests / Wallet / You with Community dropped. The
  live app is Home / Discover / Community / Mining / Wallet / Profile. Navigation is a
  separate decision and must not ride along with this screen.

## What to produce

**One direction — refined B** — in these states:

1. Something needs you (two gems, one closing in hours)
2. You are covered
3. A hunter has gone quiet on one of your gems
4. Twenty gems followed
5. New user

Plus the three track situations from section 2. Note in one line what you chose for the
"cannot be missed" mechanic and why.
