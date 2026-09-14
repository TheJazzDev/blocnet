# Start here — next screen

Paste this into a new session. It is written for someone who was not here for
the Home feed work.

---

## What just happened

The Home feed was redesigned and rebuilt. Read
[`PROGRESS.md`](../PROGRESS.md) first — it is short, and §4b is the part that
will save you the most time.

Two things it records that matter more than the feature list:

**The design phase cost six rounds because the brief was wrong, not the
drawing.** The brief took a sentence from `PRODUCT.md` describing why Blocnet
is worth using and turned it into the literal shape of a screen. Four rounds of
polished, coherent, wrong work came out of that. If a brief is describing
mechanics rather than what the product means to the person using it, stop and
fix the brief.

**The build phase then cost four more rounds because I built from memory of the
design instead of from the design file.** Every correction was reactive — fix
the item named, declare it done, get corrected again. The owner's words, and
they are fair: *"When we redesign something, we look at the design and we take
time to iterate over the design. Once the design has been approved, replicating
the design should not be a problem because there is an existing design that must
be followed. It must be followed to the letter."*

## The method, non-negotiable

1. **Extract every state from the design file before writing any code.** Not a
   glance at the picture — the element order per state. For the Home design that
   was one script over `docs/artifacts/*.html` producing five lists.
2. **Build to those lists.** Where the screen has an existing widget that nearly
   fits, rebuild rather than adapt. Adapting is what produces drift, and the
   owner has explicitly authorised retiring code: *"If we need to retire existing
   code and rebuild it based on the new design, we should do that."*
3. **Walk every state against the list before saying done.** Not just the state
   you were asked about.
4. **Verify on the emulator, not only in tests.** Six defects in the Home work
   passed a clean analyzer and a full suite and only appeared on a device — one
   of them a blank feed that threw no exception.

## The standing rules

- **Blocked on a backend gap? Build it.** Owner's instruction, 2026-09-12:
  *"Once we have a design and something is blocking because we need to modify
  the backend, just add it and report back on the modifications."* Prisma
  changes go through `bunx prisma migrate dev`, never `db push`, and the schema
  edit and migration commit together.
- **Report the decisions you took**, especially the judgement calls. See the
  `F-41 + F-42` commit for the shape.
- **Never invent a number to fill a slot in a design.** The caught-up card has
  no "unread" count because nothing tracks per-update reads.
- **Never claim knowledge the platform does not have.** A hunter observes a
  third-party project from outside, so no lifecycle denominators, no "step 2 of
  6", no progress bar toward an end nobody knows.
- **Track in [`UX_UI_TRACKER.md`](../UX_UI_TRACKER.md)** — a finding row per item
  and a session-log line per session. The convention is already there.

## Where things stand

| | |
|---|---|
| Branch | `feature/home-feed-redesign`, pushed, 30 commits |
| Base | `stage` |
| Mobile tests | 260, analyzer clean |
| Current design | [Blocnet Home Feed v2](../ARTIFACTS.md) · brief [`home-feed-r6.md`](home-feed-r6.md) |
| Open findings | F-37 (raw error strings reach users), F-38 (expired session half-state) |

**Two Home states have never been seen running**, because they need account
state the test login does not have: day one needs zero follows, caught up needs
no quiet gem. Both are correct in code. Verifying them means temporarily
changing follows in the dev database — ask before doing that.

## The recommended next screen: Discover

Reasons, in order of weight:

1. The feed card and the follow row are already built and Discover is the
   surface that reuses them most directly.
2. Home's day-one screen already borrows Discover's job, so the two have to
   agree or the seam shows. They currently do not, because Discover is still on
   the old design.
3. It is the second screen a new member sees, so it carries the most traffic of
   anything still un-redesigned.

Leave the console until the mobile vocabulary has settled across two screens
rather than one.

**Do not design several screens at once.** One at a time keeps a wrong brief
cheap, which is the whole lesson of the six rounds.

## First step for Discover

Write the brief before anything else, and write it about what Discover is *for*,
not what it contains. Home's brief only worked on the fifth attempt, when it
started from the real screen and the product thesis instead of a field list.
Read [`PRODUCT.md`](../PRODUCT.md) and [`USE_CASES.md`](../USE_CASES.md) first.

Screenshots of the shipping app live in [`reference/`](reference/) — attach them
as the thing to build on, explicitly not as a layout to preserve.
