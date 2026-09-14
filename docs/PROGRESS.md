# Home feed redesign — progress log

**Last updated 2026-09-14.** Covers the design programme and the implementation
that followed. Day-to-day findings live in [`UX_UI_TRACKER.md`](UX_UI_TRACKER.md);
this is the shape of the whole effort and the reasoning that is easy to lose.

**Where it stands:** the design is settled at round six, and phases A, B and C
are built, device-verified and pushed on `feature/home-feed-redesign`. Home is
done. The next phase is a different screen, not a continuation of this one.

---

## 1 · Foundations

Done before the redesign, and the reason it could move quickly.

| | |
|---|---|
| Design system | The console UI kit synced to Claude Design, so the design agent builds with real components. 19 components, 76 bundle exports. |
| Brand | Consolidated on **Signal Cyan**. User `#0891B2`, hunter `#22D3EE`. Chosen on contrast, not taste — see [Accent Directions](ARTIFACTS.md). |
| Scales | Type, spacing, radius and icon scales token-ised and migrated across 204 files. |
| Widget library | `lib/shared/widgets/`, ten widgets, derived from measured usage rather than invented. |

## 2 · The design, in six rounds

The important part of this log. Four rounds were thrown away, and the reason
matters more than the drawings.

**Rounds 1–4 built a dashboard, and all four were wrong for one reason.**
`PRODUCT.md` says Blocnet sells *not missing anything*. That is a reason to use
the product. The brief turned it into the literal shape of a screen, so round
two offered three directions — Deadline Ledger, Coverage Board, The Queue —
which are three names for a to-do list. There was never a social-feed option to
reject. Every round after refined a task manager, and the writing followed:
*needs you*, *handled it*, *dismiss to clear the count*.

It also deleted what makes Blocnet social: hunter avatars and role badges became
a grey byline, the hunter's own voice became clipped operational prose, five
working colours collapsed to one cyan, and a member who followed nothing got two
boxes reading "Empty slot" instead of a browsable feed.

**A second error inside the first.** Round three's lifecycle track claimed a
phase count (*"step 2 of 6"*). A hunter observes a third-party project from
outside and reports after the fact, so nobody on Blocnet can state a denominator.
Withdrawn in [`home-feed-r4.md`](design-briefs/home-feed-r4.md); the reasoning is
kept in [`PRODUCT.md`](PRODUCT.md) so it cannot be re-derived.

**Round 5 restarted from the real feed card** and got the direction right: Home
is a social feed, and *not missing anything* is a quality it should have, not a
structure to replace it with.

**Round 6 corrected six items** and is what we build:

- the live countdown, its red panel and its draining bar are gone — the bar
  could only represent a window's total length, which nobody knows;
- red cut to signal only;
- one tab set in every state;
- the *Ask* nudge aggregated;
- the shipped five-tier level badges put back.

Current design: [Blocnet Home Feed v2](ARTIFACTS.md) · brief
[`home-feed-r6.md`](design-briefs/home-feed-r6.md).

## 3 · What shipped

Workstream **WS-Q**, branch `feature/home-feed-redesign`.

### Phase A — the feed itself

- **Priority drives the whole card.** Before, every card carried the same faint
  tinted border, so a high-priority update looked like a low one. Now: red edge
  and warmed ground on high, darkened amber edge on medium, neither on low —
  which is what makes the other two legible.
- **The update title is no longer discarded.** The feed rendered only the body.
  The title is the most informative line an update has.
- **Cards became rows in a stream**, full-bleed with a hairline, not floating
  panels.
- **Tip moved into the action row**, where value is realised, instead of a
  profile.
- **Tabs settled to For you / Following / General**, and this was not a rename:
  what the app called "Updates" is Following, and "For you" is a blended feed
  mode that did not exist. `FeedBlend` shifts the mix with the follow count and
  never drops a followed post.
- **The caught-up state is earned**, with a receipt — and deliberately no
  "unread" count, because nothing tracks per-update reads.
- **Gems whose hunter went quiet now surface**, as a card in the stream quoting
  the hunter's last words.
- **Day one** carries an intro, a *Moving right now* list and a heading.

### Phases B and C — the backend that was blocking them

Policy set by the owner on 2026-09-12: *when a design is blocked on a backend
gap, build the gap and report the decisions.* Two migrations followed.

**`Update.deadlineAt`** (F-41). Nullable. **A past date is accepted on purpose**
so a hunter can report a window that has already shut and the app says so.
Two-year ceiling guards a year typo. Rendered as a stated time — *"Closes
Wednesday, 8:25pm"* — never a clock, with a test asserting no phrasing contains
a relative duration.

**Project attention** (F-42): `request-update`, `report-inactive`, `attention`.
Followers only, one nudge per member per gem per week, and **the hunter is
notified once per gem per week however many members ask**, carrying the count —
otherwise the feature becomes a way to pile on a hunter rather than reach one.
**Reporting does not reassign the gem**: that changes someone's standing, so a
moderator decides.

## 4 · What the device caught that tests did not

Worth keeping, because it is the argument for verifying on hardware.

1. **The redesign initially landed on the wrong layout.** `FeedViewMode` defaults
   to `list`; the first two commits changed `card`, which most users never see.
2. **A blank feed that threw nothing.** The urgency edge was a stretched `Row`
   child with no height to stretch to inside a sliver. The app looked healthy
   and rendered an empty page.
3. **The action row overflowed by 62px** once Tip became a fifth element, from a
   fixed 64px button width that was harmless with four.
4. **A header overflow that tracked the priority word's length** — 34px on
   "Medium", none on "Low" — invisible because the live data was all High.
5. **A contradiction between two correct components**: *"You're all caught up"*
   directly above *"@abtoonzz last posted 199 days ago"*. The radar reports new
   updates, and a gem nobody touches produces none, so silence read as coverage.
6. **A duplicated deadline line**, because one layout's insertion anchor was a
   substring of the other's.

Widget tests now render a real card at 390px, at each priority, in both layouts,
inside a sliver — where an overflow is a failure rather than a yellow stripe.

## 4b · The build-phase failure worth remembering

The design work cost six rounds because the *brief* was wrong. The build phase
then cost several rounds for a different reason, and it is the more avoidable
one.

**I built from memory of the design instead of from the design file.** The card
was produced by patching the screen's existing card toward the mock rather than
building the mock's card. Each time the owner found a mismatch I fixed that one
item and declared it done without re-checking anything else. Four rounds of
that: the card's internals, then the screen furniture around it, then the
ordering within states.

What it cost: the priority pill in the wrong row, the gem chip as a full-width
panel, a priority ring on the avatar, level artwork where a numbered disc
belongs, the Edge verdict missing entirely, an Alpha Radar card and an Edge
Engine card that appear in **none** of the design's five states, a permanent
Top Hunters rail that is a day-one affordance, and the tab order reversed.

**The method that works**, and that should be used on every screen after this:

1. Extract every state from the design file first — element order per state,
   not a glance at the picture.
2. Build to that list. Where the code has an existing widget that nearly fits,
   prefer rebuilding over adapting; adapting is what produces drift.
3. Before saying done, walk **all** states against the extracted list. Not the
   one that was queried.

The last pass found four more mismatches this way, before the owner did. That
is the difference, and it is the only evidence that matters.

One deliberate departure from the approved design is recorded in
`FeedCardEmphasis`: high priority lost its red edge and warmed ground after the
owner saw it on real data. The mock assumed one urgent card in six; crypto
updates are urgent far more often, so the ground turned long stretches of feed
red and the signal stopped being a signal.

## 5 · Numbers

| | |
|---|---|
| Commits on the branch | 29 (two from a parallel session) |
| Mobile tests | 260, from a 181 baseline when WS-Q opened |
| Analyzer | clean |
| Migrations | 2 |
| Design rounds | 6, of which 4 were discarded |

## 6 · Open

- **Two Home states are unverified on a device**: day one needs an account with
  zero follows, caught up needs one with no quiet gem. Both are correct in code
  and neither has been seen running.
- **F-37** (P1) raw infrastructure error strings still reach users through
  withdrawal failure reasons and wallet transaction metadata.
- **F-38** (P2) an unrefreshable expired session leaves the app in a misleading
  half-state; needs reproducing under a normal expiry.
- The **console and other mobile screens** are untouched. The round-six
  principles have now been validated on one screen, which was the point of
  building Home before designing more.
