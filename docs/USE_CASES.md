# Blocnet use cases

> Companion to [`PRODUCT.md`](PRODUCT.md), which says *why* Blocnet exists.
> This one says *what people do in it*.
>
> Deliberately no build status here — that rots. Live status is in
> [`FEATURE_ATLAS.md`](FEATURE_ATLAS.md), open work in
> [`UX_UI_TRACKER.md`](UX_UI_TRACKER.md). **[decision]** marks something nobody has
> settled yet.

---

## The loop

Everything below hangs off one cycle. If a feature does not feed it, question the
feature.

```
  member follows a gem
          ↓
  hunter posts an update on it          ← the obligation, and the product
          ↓
  member is notified and acts            ← "I would have missed that"
          ↓
  member makes money
          ↓
  member tips the hunter in BNT
          ↓
  hunter's reputation rises
          ↓
  projects pay that hunter to post       ← hunter income, held honest by liability
          ↓
  more gems, better kept  →  more members  →  back to the top
```

Mining BNP is not in the loop. It is the drip that keeps people opening the app while
the loop is still too thin to do that on its own.

---

## Member

The person the product is for. Follows more projects than they could ever track alone.

### M1 · Join
Gets through the closed-alpha gate, signs up with email or Google, optionally enters a
referral code that binds them to someone's downline.

### M2 · Find a gem worth following
Browses Discover, filters by tag and urgency, or searches. Judges a gem on its hype
score, follower count, update activity, and **who owns it** — the hunter's track record
is part of the decision.
**[decision]** A member cannot currently weigh the hunter before following. Should the
owner's reliability be on the gem card?

### M3 · Follow a gem
The moment coverage begins. From here the member has delegated tracking to the hunter.
This is the single most important action in the product and should feel like it.

### M4 · Learn that something needs them
The core case. A hunter posts; the member gets a push; they open it and act — do the
KYC, claim before the snapshot, exit before the window shuts.
**[decision]** An update has urgency but no deadline, so the app cannot say *when* the
window closes. See PRODUCT.md, "Two gaps".

### M5 · Triage the feed
Opens the app cold and answers one question: *does anything need me?* Usually the honest
answer is no, and the app should say so with confidence rather than apologise for an
empty screen.

### M6 · Discuss an update
Comments, replies in a thread, reacts, mentions another user. Discussion attaches to a
specific update, not to the gem in general.

### M7 · Save for later
Bookmarks an update to come back to.

### M8 · Tip a hunter
Made money off a call, converts to BNT, tips. The value exchange that does not exist on
X or Telegram.
**[decision]** Tipping is reached from a profile today, not from the update that made
the money.

### M9 · Mine BNP
Starts a 24-hour cycle, comes back, claims. Earns at a rate affected by referrals and
power. Converts to BNT at mainnet.

### M10 · Grow a downline
Shares a referral code or link; sees total and active referrals; earns a rate bonus.

### M11 · Progress
Completes quests, submits proof, earns badges, climbs 15 levels.
**[decision]** Levels are meant to gate future participation. What they unlock is
undecided, so today they are a number that does nothing.

### M12 · Hold and move value
Wallet: sees balances, receives to a BSC address, sends internally, withdraws, submits
KYC when a withdrawal needs it.

### M13 · Surface a project they found
A member who is not a hunter can submit a project. A hunter picks it up, does the
diligence, and takes ownership. This is how the gem supply scales past the hunter roster.

### M14 · Talk to the community
General and Market Talk channels, not tied to any one gem.

### M15 · Report something
Reports an update, a comment or a post. If they are actioned themselves, they can appeal.
This is the enforcement that makes hunter liability real.

### M16 · Become a hunter
Applies for the role and sees the outcome of the application.

---

## Hunter

An analyst carrying ongoing responsibility for what they call. Not a promoter.

### H1 · Get the role
Applies, is reviewed, is granted `hunter`. Gains the Hunter space: a different profile
body, the Hunter Hub, and the composer.

### H2 · Claim a gem
Submits a project — name, symbol, site, tag, description, and a justification for why it
is worth the community's attention. On approval it becomes theirs. **One gem, one
owner**, so accountability is never diffuse.
**[decision]** Co-ownership is modelled server-side (`ProjectHunter`,
`ProjectHunterInvite`) and wanted by the founder, with no client on either end.

### H3 · Keep the gem current
**The obligation, and the reason the product exists.** Posts an update against an owned
gem, sets urgency, tags it. Every follower is notified.
**[decision]** Nothing tracks whether a hunter is actually keeping a gem current. There
is no staleness signal, for the hunter or for the members relying on them.

### H4 · Manage their gems
Sees what they own, what they contribute to, what they have submitted, and the updates
they have posted.

### H5 · Get paid
Receives tips and sees tip history in BNT.
**[decision]** VIP tiers for people who tip — earlier or deeper updates — are wanted but
unspecified.

### H6 · Build standing
Success rate, sentiment, audience reach, gems managed, season ranking.
**[decision]** What the reputation score actually counts, and whether members can see it,
is unsettled. Reliability of updating ought to weigh more than volume of posting.

---

## Moderator

### Mo1 · Work the reports queue
Filters by status and target, reviews reported content, resolves.

### Mo2 · Act on a user
Warns, mutes, suspends or restricts, with a reason recorded.

### Mo3 · Hear an appeal
Reviews an appeal against an action and decides.

---

## Admin and owner (console)

### A1 · Adjudicate a proposed gem
Reviews submissions and approves or rejects. The gate on gem quality.

### A2 · Grant roles
Governance roles for the console, community roles for moderation. Every grant is
confirmed and noted.

### A3 · Curate the taxonomy
Primary and secondary tags, which drive discovery filters.

### A4 · Run the economy
Mining cycle economics, tip fee policy and active currency, wallet kill-switches, RPC
endpoints, enabled assets, risk limits, prices.

### A5 · Run gamification
Creates and edits quests, reviews submitted proof, manages badges and the 15 levels.

### A6 · Approve money out
Withdrawal queue, KYC review.

### A7 · Reach everyone
Push, in-app and email broadcasts with an audience picker.

### A8 · Tune the Edge Engine
Runtime toggles, ML provider and limits, recompute, decision review.

### A9 · Audit
Every admin action recorded and reviewable.

---

## What the use cases expose

Reading these end to end, three things stand out, and all three are about the promise
rather than the plumbing.

1. **The core case (M4) cannot be fully delivered.** A member is meant to never miss a
   deadline, and no update carries one.
2. **The core obligation (H3) is unmeasured.** Nothing tells a member whether the hunter
   they are relying on has gone quiet, and nothing tells a hunter they are slipping.
3. **The reward (M8) is far from the moment that earns it.** Tipping sits in a profile,
   not beside the call that made someone money.
