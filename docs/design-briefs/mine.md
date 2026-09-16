# Design brief — Mine (today: Mining)

**Paste this into Claude Design.** Build it in the *Blocnet Design System* project so the
real components are used. Attach, as the visual vocabulary to reuse, the approved
*Blocnet Home Feed v2* canvas. Attach today's screens as **the thing being replaced — not
a layout to preserve**: `reference/03-mining.png` (idle), `reference/03b-mining-running.png`,
`reference/03c-referral-code.png`, `reference/03d-mining-leaderboard.png`.
Design this one tab and its three sub-screens only.

---

## What this tab is for

Blocnet's product is the feed: a hunter keeps each gem updated so members do not have to
track it themselves. Early on, the feed is not yet dense enough to bring people back every
day by itself. **Mining is the habit that brings them back in the meantime.** It is not a
second product, and it should not look like a crypto-mining dashboard.

A member opens Mine to answer one question: **"Is my cycle running, and when do I
collect?"** Two more questions sit under it:

- **"What have I got, and what is it worth?"** Mined points are **BNP (Blocnet Points)**.
  When BNT (the Blocnet token) launches on BSC mainnet, mined BNP converts to BNT. There is
  no price today and the screen must not suggest one.
- **"How do I earn faster?"** Only one way: **invite friends who stay active.** Each active
  friend adds +5% to your rate, up to +100%.

Today's screen answers none of these clearly:
- **Idle and running look almost the same.** Both show "5 BNP/h" and "Claim after 24h", so
  a member cannot tell whether they are earning.
- **The main button is a disabled grey "Claim in 23:59:57" for a whole day.**
- **"Mining Power 10.0 TH/s" is invented.**
- **Two tiles repeat each other** ("Total Earned", "Claimed").
- **Nothing says unclaimed points are lost after 48 hours** until they already are.
- **The referral code sits two taps deep under Profile** and never says it speeds mining up.

## How mining actually works (design to these facts)

- A **cycle** lasts **24 hours** and pays **120 BNP** at the base rate, 5 BNP an hour.
  Admins can change both numbers, so they must render from data and never be baked into
  the layout.
- Points accrue **hourly**. The screen can show "38 BNP so far".
- When the cycle ends, it becomes **ready to claim**. The member has **48 hours** to claim.
  After that the cycle is **forfeited**, with no payout.
- **Claiming** adds the points to the balance and **starts the next cycle automatically**.
  A member who claims daily only ever presses one button.
- **Boost:** +5% per active friend, capped at +100%. An **active friend** is someone who
  mined in the last 7 days.
- Friends link to you with your **8-character code** within 24 hours of signing up.
- The **balance** is claimed BNP. It is also credited to the member's Wallet as BNP; the
  Wallet asset row for it is being added.
- There is a **leaderboard** of members by lifetime claimed BNP, and an **hourly history**
  of the last 48 checkpoints.

**Owner decisions 2026-09-16:** cycle progress is a ring around the mining core, not hour segments. "How mining works" is a popover from the ? icon (and auto-opens once), never an inline card that pushes the page down. Copy is short and plain: numbers and times, no narration ("Ready tomorrow at 09:20 · 15h left", "49 of 132 BNP", "5 BNP/hr", "Claiming starts your next cycle.").

**This is Blocnet's own system, so the app knows the exact end time.** The rule against
progress bars and clocks, used on Home and Hub, is about third-party projects whose future
nobody knows. It does **not** apply here: a cycle progress ring or bar is honest. Even so,
lead with a **stated time** (*"Ready at 12:05 tomorrow"*) and keep any live countdown
secondary.

## The Mine tab, top to bottom

1. **Cycle card.** This is the whole point of the screen, and its state must be obvious at a
   glance, even in the corner of your eye.
   - One status sentence and one stated time, for example *"Mining · ready at 12:05
     tomorrow"*, or *"Ready to claim · claim by Fri 12:05"*.
   - Progress through the cycle, and BNP mined so far.
   - The rate as a sentence: *"5 BNP an hour · +10% from 2 friends"*.
   - **One primary action whose meaning changes:** **Start mining**, then **Claim 120 BNP**.
     While a cycle runs there is **no disabled button**. Show a quiet
     **Remind me when it's ready** toggle instead; reminders are being built.
   - A little motion is welcome if it is restrained. The current orb and equaliser can go.
2. **Balance.**
   - BNP balance, large.
   - Beneath it: *"Converts to BNT at launch."*
   - No USD, no APY, no "worth".
   - A link to Wallet.
3. **Earn faster (referrals, merged here from Profile).**
   - Active friends and the boost they give, including the cap (*"2 active · +10% of
     +100% max"*).
   - Your code, with **Share** as the primary action and Copy as the secondary.
   - A short line on what "active" means.
   - If the member can still link a referrer (first 24 hours), an **Enter a friend's code**
     row. Otherwise show nothing about it; do not show a "bind window closed" message.
   - The friends list: name, level badge, and active or inactive. **No email addresses.**
4. **Leaderboard preview.**
   - The top 3, plus **your own row pinned** with your rank.
   - Links to the full board.
   - Members with 0 BNP are not ranked.
5. **Hourly history.** One row linking to the sub-screen, with a one-line summary.

**First visit only:** a dismissible three-line explainer above the cycle card, covering
what BNP is, that you claim once a day, and that unclaimed cycles expire after 48 hours.

## Sub-screens

- **Leaderboard.**
  - Ranked list with your row pinned at the bottom while it is off-screen.
  - Rank, avatar, name, level badge, lifetime BNP, and a quiet *"mining now"* marker.
  - Pagination.
  - Tapping a row opens the member's profile.
  - Gold, silver and bronze are allowed for ranks 1–3 only.
- **Hourly history.**
  - Grouped by cycle; each hour shows points and one of three states: **Claimed**,
    **Waiting to claim**, **Expired**.
  - The cycle header states its outcome.
- **Friends** (reached from *Earn faster*): the full friends list, with the same rows as
  the preview.

## States to show — all on one canvas

1. **First visit, idle.** Explainer visible, Start mining.
2. **Running, hour 9 of 24,** with 2 active friends (+10%), and the reminder toggle on.
3. **Ready to claim,** 30 hours left in the claim window.
4. **Ready to claim, closing soon:** 3 hours left. Urgent but **not red**; red is reserved
   for moderation and destruction.
5. **Just claimed.** Claim confirmation (+126 BNP) and the next cycle already running.
6. **Cycle expired.** The notice says plainly what was lost and why, and has a real
   dismiss target. Start mining is available again.
7. **Mining paused by Blocnet** (admin switch off). An honest message, balance still
   visible, no Start button.
8. **Couldn't load.** Error and retry. **Never show a made-up idle card.**
9. **Leaderboard,** a page of 10 with your row pinned at #27.
10. **Hourly history** with all three states.
11. **Earn faster, expanded,** in two versions: a member still able to enter a friend's
    code, and one with 0 friends. The empty state should be an invitation, not an apology.
12. **Two push notifications,** as they appear on the lock screen: **cycle ready**, and
    **claim window closing**.

## Rules that are not negotiable

- **Never invent a number to fill a slot.** No TH/s, no hashrate, no USD, no APY, no
  "estimated value".
- **One primary action on the screen.** Never a disabled primary button standing in for a
  status.
- **Red budget:** red means moderation or destruction only. Expiry and "closing soon" need a
  serious treatment that is not red. Do not stack red with the Ruby level badge
  (`#E23D4A`).
- **Status is never colour alone.** Every state has words; touch targets are at least 44 px.
- **User space accent is Signal Cyan `#0891B2`** (Hunter space `#22D3EE`; this tab appears
  in both). Use the shipped five-tier level badges (Iron, Jade, Amethyst, Gold, Ruby).
- Phone width 390, dark theme, the same type and spacing scale as the Home Feed v2 canvas.
  Mobile text sizes stay moderate.
- **Bottom bar:** Home · Gems · Community · Mine · Wallet · Profile, with one-word labels.
  In Hunter space, slot 3 is Hub.

## Copy to use as written

- Tab: **Mine**. Sections: **Balance**, **Earn faster**, **Leaderboard**, **Hourly history**.
- Actions: **Start mining** · **Claim {n} BNP** · **Remind me when it's ready** ·
  **Share code** · **Copy** · **Enter a friend's code**.
- *"Mining · ready at {time}"* · *"Ready to claim · claim by {time}"* ·
  *"{n} BNP so far"* · *"{rate} BNP an hour · +{x}% from {n} friends"* ·
  *"Converts to BNT at launch."* · *"Active = mined in the last 7 days."*
- Expired: *"Your cycle ending {date} wasn't claimed within 48 hours, so its {n} BNP
  expired."*
- Push: *"Your BNP is ready — claim {n} BNP"* ·
  *"{n} BNP expires in {h} hours — claim now"*.
