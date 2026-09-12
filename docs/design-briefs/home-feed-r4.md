# Design brief — home feed, round four: the track was wrong

> **⚠️ DIRECTION SET ASIDE 2026-09-12.** This brief is sound on its own terms and the
> design it produced met it. The whole *board* direction was then rejected on review: it
> had turned a social feed into a task manager, and it broke the day-one experience for a
> member who follows nothing. Superseded by [`home-feed-r5.md`](home-feed-r5.md), which
> restarts from the real feed card. Kept for the record and for the track reasoning in
> section 1, which still stands.

**Paste this into Claude Design together with the round-three canvas**
(*Blocnet Coverage Board*, the refined B). Read [`PRODUCT.md`](../PRODUCT.md) first if you
have not.

---

## What this round is

Round three refined Direction B and got most of it right. **Keep it.** One element is
wrong, and it sits at the centre of every row: the lifecycle track. It is wrong because
the brief told you to build it, and you built it correctly. This round removes it and
replaces it.

**Everything in the round-three canvas stands unless this document names it.** The pinned
summary, the per-gem rows, expand-in-place, the covered state with its receipt, the
stalled-hunter state, the twenty-gem fold, the new-user board, the type scale, the tab
bar — all good, all kept.

## 1 · The error, so it is not re-derived

Round three asked for a track reading `Step 2 of 6 · KYC`, built from an ordered set of
named phases a hunter defines per gem, from a template chosen by gem type. That cannot
exist, for four independent reasons. Any one of them is fatal.

- **The denominator is unknowable.** A hunter does not run the project. They observe a
  third-party crypto project from the outside and report what they find, after it happens.
  "of 6" is a claim about the future that nobody on Blocnet is positioned to make — not
  the hunter, not the project owner, not the platform.
- **There is no phase vocabulary in the system.** Blocnet has a primary tag (the chain:
  Core, Solana, Ethereum, Ice Open Network, Telegram Network, Binance Smart Chain) and
  secondary tags (Airdrops, IDO, Mining, Farming, Staking, Launching, Partnership,
  Governance, Token Burn, NFT, Trading, Gaming, Wallet, Security, Metaverse). Those are
  **categories of activity, not stages**. Nothing anywhere in the product knows the words
  KYC, Snapshot, Claim or Distribution.
- **A gem is several categories at once.** Secondary tags are a list of up to twenty, set
  when the project is created. One project is legitimately Airdrop *and* Mining *and*
  Staking simultaneously. A single linear rail cannot represent that even in principle.
- **Most updates are not stages.** "Update your app to get the new feature" is a real,
  urgent, board-worthy update. It belongs on the board and sits nowhere on a lifecycle.

## 2 · What is actually true about a gem

This is the whole of it. Design against this list and nothing else.

| Fact | Where it comes from | Certainty |
|---|---|---|
| Name, symbol, description | Project, set at creation | certain |
| Chain | Primary tag, one value, set at creation | certain |
| Categories | Secondary tags, 0–20 values, set at creation | certain |
| Who covers it | Assigned hunter | certain |
| When the hunter last posted | Newest update's timestamp | certain |
| What is going on right now | **The newest update** — title, body, urgency | certain |
| How much it matters | Urgency: high / medium / low | certain |
| Follower count | Follows | certain |
| Edge verdict | `act` / `watch` / `ignore` + a signal count | certain |
| What phase the project is in | **nothing knows this** | — |
| How many phases there are | **nothing knows this, and nothing can** | — |

**The unit of state is the update, not a position on a rail.** A gem's situation is its
newest update and whether that update still needs you.

## 3 · The replacement

Two small things we are willing to add to the data model, because they are knowledge the
hunter genuinely has **at the moment they post**, which the phase set was not:

**a. An optional stage label on an update.** Short free text the hunter types while
writing — `KYC`, `Snapshot`, `App update`, `Sale opens`. Not from a fixed list. Not
ordered. No count. It answers "what is this about" in one or two words and nothing more.
Often absent; the design must be as good without it as with it.

**b. A deadline on an update.** When the thing this update describes closes. Nullable, and
null most of the time. This is what makes a countdown real rather than drawn, and what
lets the pinned summary count be computed honestly.

**Design against these two fields and the round-three facts. Nothing else is being added.**

**Hard rules for this round:**

- **No denominator anywhere.** Never `of 4`, never `of 6`, never a progress percentage.
  Nothing that implies a known end.
- **No fixed phase set, no templates, no per-gem phase editor.** That screen is not being
  built.
- **A filled-rail metaphor is only allowed if it cannot be read as progress toward a
  known end.** The segmented track from round three reads as exactly that, so it goes
  unless you can show a version that does not.

**The real problem to solve, stated plainly:** the rail *was* B's visual identity, and
removing it takes the spine out of every row. Do not just delete it and leave a gap.
Find what carries a row now. The candidates are the stage label as a chip, urgency, the
deadline, the hunter's freshness, and the update title itself — the title is the most
informative thing on the row and round three gave it the least room.

**Optional, and subordinate:** if a row wants history, the only honest version is what
the hunter has already posted, newest first, with no future and no count. A list, not a
rail. Try it if it earns its space; drop it if it does not.

## 4 · Carry over two unresolved items from round three

**a. Tipping is a rule, not a flourish.** Round three put the engagement row with
`Tip @jazzdev` on exactly one card in the whole canvas; every other urgent row got a small
tip icon instead. The treatment is right and it needs to be consistent. Any row that
expands because it needs you carries the same row, with tip visually distinct because it
is the one that closes the loop.

**b. The Edge Engine only ever shows one verdict.** Round three drew `watch` and never
`act` or `ignore`. `act` is the interesting one and the reason the ask existed: show a
gem where Edge says `act` sitting next to a real deadline, and make it clear which of the
two the member should read first. Show `ignore` too, even if the answer is that it stays
silent.

## 5 · What to produce

**One direction — corrected B.** The same five states, rebuilt with the track replaced:

1. Something needs you (two gems, one closing in hours)
2. You are covered
3. A hunter has gone quiet on one of your gems
4. Twenty gems followed
5. New user

Plus, in place of round three's track-spec panel, **a row-anatomy panel** showing the same
gem row in four conditions:

- a **high**-urgency update with a stage label and a deadline
- a **high**-urgency update with **no** stage label and **no** deadline
- a **low**-urgency update, which is most of them
- a gem whose newest update is weeks old (the stalled case, at row scale)

Note in one line what carries a row now that the rail is gone.

## 6 · Unchanged constraints

- Dark only. Ground `#09090b`, surfaces `#18181b` / `#27272a`, borders `#27272a`.
- Signal Cyan `#0891B2` User, `#22D3EE` Hunter. Red is moderation and destructive only.
- Spacing on a 4pt grid. Corners 8 / 12 / 16 / 20 / full.
- Material Symbols Rounded, real icon names.
- Platform font, system-ui. **32px is the ceiling.**
- **Do not rename or re-order the bottom tabs.** Home / Discover / Community / Mining /
  Wallet / Profile. Round three got this right after two rounds of getting it wrong.
