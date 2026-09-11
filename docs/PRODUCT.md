# What Blocnet is

> Written 2026-09-12 from the founder's own account of the product. This is the
> document that was missing: the codebase describes mechanics, not meaning, and
> reading it leaves you guessing at why any of it exists.
>
> Anything marked **[open]** is unresolved and needs a decision.

---

## The problem

On X and Telegram, someone posts a project once and walks away.

A caller names a token in its IDO, its mining phase, or an airdrop. Followers pile in,
farm it, buy it. Then nothing. The caller has no obligation to say what happened next.
Whether you made money or lost it is nobody's business but yours. Anyone can be an
influencer, any project can pay anyone to post, and the post is the end of the
relationship.

That leaves the user holding a job they cannot do. If you are farming fifteen projects
across six months, you have to personally remember that one of them opened KYC on
Tuesday, another ended its mining phase, and a third moved its snapshot. Miss one and
months of work evaporates. Nobody can hold that.

**The thing Blocnet sells is not discovery. It is not missing anything.**

## The mechanism

A **hunter** finds a project, does the diligence, and posts it. That part looks like an
influencer.

The difference is what happens after. **The hunter is obligated to keep updating that
project through its whole lifecycle.** KYC opened. Mining ends Friday. The team moved
the snapshot. That obligation is the product.

**One project has exactly one owner.** If Core DAO is already on Blocnet, it belongs to
the hunter who posted it. Accountability has to be singular or it is nobody's.
`Project.ownerAdminId` enforces this today. **[open]** Co-owner partners are wanted —
`ProjectHunter` and `ProjectHunterInvite` already exist in the schema for it, with no
client on either end.

A **member** follows the handful of gems they actually care about. There might be two
hundred gems on the platform; they follow five. Then they go and live their life. When
the hunter posts, they get a notification and act on it. They are never tracking
anything themselves. That is the entire value exchange.

Members can also submit a project they found. A hunter picks it up, does the diligence,
and takes ownership.

## Why a hunter does this

Four things, and they compound.

1. **Tips.** A member farms a gem for six months and makes money. They tip the hunter in
   BNT, because the hunter found it and kept them informed. This does not exist on X or
   Telegram at all, and it is the thing that makes the obligation worth honouring.
2. **Reputation.** Post good gems, keep them updated, and your score rises. The score is
   built on reliability, not reach.
3. **Paid placements.** Projects approach high-reputation hunters directly: post us, your
   followers trust you. That is real income.
4. **Liability.** If a hunter takes money to post something that rips people off, the
   community reports them and they can lose their standing. Skin in the game is what
   keeps point 3 honest.

A hunter is an **analyst** who carries ongoing responsibility for what they call. Not a
promoter.

## The economy

- **BNP — Blocnet Points.** Mined today by any user. A daily drip that gives people a
  reason to open the app while the network is still forming.
- **BNT — Blocnet Token.** Launches on BSC mainnet. At launch, mined BNP converts to BNT.
- **BNT is what you tip with.** Withdraw gains from a gem, convert, tip your hunter.
- **[open]** Hunter VIP tiers for people who tip, with earlier or deeper updates.

So: **the feed is the product. Mining is the habit that brings people back before the
feed is dense enough to do that on its own. Tipping is how value flows back.** They are
not three equal features and the app currently treats them as if they were.

## Who it is for

Any crypto user who follows more projects than they can personally track. They are not
here to browse. They are here so that nothing slips.

## What lives in the app

| Surface | What it is for |
|---|---|
| Feed | Updates on the gems you follow. The core. |
| Gems | Discover and follow projects. |
| Hunter Hub | Where hunters manage their gems and post updates. |
| Comments | Discussion attached to a specific update. |
| Community | General chat, not tied to any one gem. |
| Wallet | In-app BNP/BNT, transfers, withdrawals. |
| Mining | The daily cycle that earns BNP. |
| Quests, badges, levels | Gamification. **[open]** Levels are meant to gate future participation; what they unlock is undecided. |
| Blocnet Edge Engine (BEE) | AI over community activity. Looks at what is happening and tells you which path to follow. |
| Moderation | Reports, appeals, restrictions. The enforcement behind hunter liability. |

The product is explicitly **not** limited to what is built. If a feature serves
community-driven updates better, it belongs.

## What this means for design

Consequences that follow from the thesis, and that the current app does not reflect.

- **The unit is a gem's lifecycle, not a post.** A member cares that Core Mines moved
  from mining to KYC. The update is how they learn it; the state is what they want.
- **A quiet feed is the product succeeding.** "Nothing needs you, all five gems current,
  checked 2 minutes ago" is the reassurance people are paying attention for. It should
  feel like cover, not like an empty room. This inverts the usual read of an empty state.
- **Time-sensitivity is the spine.** "KYC closes in 2 days" is the whole job. Urgency as
  a coloured label is a weak proxy for it.
- **A hunter's reliability should be visible and earned.** Update cadence and coverage,
  not a badge. The badge says what they are; the number says whether they do it.
- **Tipping belongs at the moment value is realised**, not buried in a profile.

## Two gaps in the data model

Both sit directly under the premise, and neither exists today.

1. **No lifecycle stage on a project.** `ProjectStatus` is `active`/`paused`/`hidden`/
   `archived` — moderation states. There is nothing for mining, KYC, IDO, snapshot,
   ended. The app cannot currently say where a gem is in its life.
2. **No deadline on anything.** No `expiresAt`, `endsAt` or action window on `Update`.
   The product exists so people do not miss deadlines, and a deadline is not a concept
   the schema has.

Everything else the design needs is already there.

## Open questions

- What exactly does a hunter's reputation score count, and is it visible to members?
- What do levels unlock?
- Who arbitrates a hunter dispute, and what does "losing standing" mean concretely?
- Does a member see which hunter owns a gem before they follow it?
- What is the moment that makes someone glad they opened the app today? Still unanswered,
  and worth answering, because it is what the feed should be built around.
