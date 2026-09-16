# Blocnet app map — what stays, what merges, what goes

> Written 2026-09-16. A product review of every mobile screen against
> [`PRODUCT.md`](PRODUCT.md) and the loop in [`USE_CASES.md`](USE_CASES.md).
> The September audit asked *is this screen broken?* This one asks *should this
> screen exist, and is it in the right place?*
>
> Status of each recommendation: **proposed** until the owner decides, then
> recorded in the decisions log of [`UX_UI_TRACKER.md`](UX_UI_TRACKER.md).
> Live build status stays in [`FEATURE_ATLAS.md`](FEATURE_ATLAS.md).

---

## 1 · The honest diagnosis

The app is wide and the loop is thin.

Six bottom tabs, three spaces, ~45 routes. Nearly every surface in `PRODUCT.md`
exists. But the product is one loop — *member follows → hunter updates → member
acts → member tips → hunter's standing rises* — and the app is weakest exactly on
that loop:

1. **The feed can only be as good as hunter output, and nothing helps a hunter
   keep a gem current.** Hunter Hub is tips, a derived "success rate", a
   leaderboard and a banner. It has no list of *your gems and how stale each one
   is*, no way to post from a gem, and no sign of members asking for an update.
   We shipped **Ask the hunter** on the member side (F-42); the hunter's
   notification for it (`project_update_requested`) is unmapped and opens Home.
   The nudge lands nowhere.
2. **A member cannot judge a hunter.** `PRODUCT.md` says reliability, not reach,
   is the score. The numbers on screen today are not that: "Success rate" is the
   share of posts a hunter labelled high or mid priority; "Season ranking" is a
   post count over the last 500 updates loaded on the phone; "Tip balance" is
   lifetime tips received. Four separate "top hunters" lists all compute that
   same post count.
3. **The same job is done in several places, each a little differently.**
   "Everything, newest first" is General *and* Trending *and* three Priority
   screens. "My gems" is Discover › My Gems *and* Profile › Following *and* the
   Hub row *and* Manage My Gems — with three different ownership rules.
4. **Screens say the wrong thing about themselves.** Wallet's headline reads
   *Pre-launch* although BNP, USDT and other assets can already be sent and
   received, and its Swap button leads to "not available yet". Profile shows
   *Hunter stats: 0%* to members who are not hunters.

So the reason the app does not feel valuable yet is not polish. It is that the
one exchange it exists for is not supported end to end, and the breadth around it
dilutes what is there.

**The principle for everything below:** a screen earns its place by serving the
loop, or by being the habit (mining) that holds people until the loop is dense
enough to hold them itself. Everything else merges, moves down, or goes.

---

## 2 · The target shape

### Bottom bar (User space): six tabs, renamed and re-scoped

| # | Today | Proposed | Why |
|---|---|---|---|
| 1 | Home | **Home** — Following · For you | The feed. General leaves (§3). |
| 2 | Discover | **Gems** — Discover · Your board · Hunters | Where you choose what to follow *and who to trust*. Absorbs General, Trending, Priority, My Gems, Top Hunters. |
| 3 | Community | **Community** | Unchanged for now. Not the loop, but the product doc names it and it works. |
| 4 | Mining | **Mine** — cycle, BNP balance, referrals | The habit. Absorbs the referral screen, which today lives under Profile although the file is in `mining/`. |
| 5 | Wallet | **Wallet** | Stays. BNP, USDT and other assets move today. **Decided 2026-09-16** — an earlier draft proposed moving it out of the bar. |
| 6 | Profile | **Profile** | Slimmed (§3). |

Hunter space keeps the same swap it has today: slot 3 becomes **Hunter Hub**.
Moderation space: slot 3 becomes **Moderation**. Both unchanged in mechanism.

The nav is icons only today. "Gems" and "Mine" are new names and need labels;
at six tabs labels must stay to one short word.

### The one missing idea: a hunter's reliability

Both the member side (M2, *can I trust this hunter?*) and the hunter side (H3,
*am I keeping up?*) need the same number, and it does not exist. **This is the
first decision to make**, because Hunter Hub and Gems are both designed around
it. A proposal, computable from data we already store:

- **Coverage** — of the gems a hunter owns, the share updated in the last 14 days
  (the same 14 days `QuietGems` already uses on Home).
- **Cadence** — median days between updates across their gems.
- **Response** — when members ask for an update, how often one follows within
  N days (F-42 records the asks).

Shown to members on the gem card and the hunter's profile; shown to the hunter as
their own to-do. It replaces "success rate", which measures nothing a member
cares about. Tips and followers stay visible, but as reach, not as reliability.

---

## 3 · Screen by screen

**Verdicts:** **keep** as is · **rebuild** keep the job, redesign the screen ·
**merge** fold into another screen · **move** keep, but somewhere else · **cut**
delete · **fix** keep, repair a defect (no design needed).

### Home
| Screen / part | Verdict | Notes |
|---|---|---|
| Following / For you tabs, cards, day one, caught up, quiet gems | keep | Redesigned in WS-Q. |
| **General tab** | **cut → Gems** | Its content is "all posts, newest first" plus four chips that open Trending and Priority. Both jobs move to Gems. The tab is the last old-design surface on Home. |
| Top-hunters rail (day one) | fix | Tap is `(_) {}`. Point it at the hunter profile once reliability exists. |
| `CatchUpBanner`, `AlphaRadarCard`, `EdgeBriefTeaserCard`, `TopHuntersRow` | cut | Orphaned by the redesign; nothing renders them. |
| Edge fetch on every Home load | fix | `EdgeEngineStore` still loads brief + feed on each open, only to feed the card's verdict chip. Load only what the chip needs. |

### Gems (today: Discover)
| Screen / part | Verdict | Notes |
|---|---|---|
| Discover sub-tab | **rebuild** | Gem card should answer M2: what it is, how active, **who keeps it and how reliably**. Hype score is computed on the phone as `followers×0.05 + updates×0.3`; it is a popularity proxy. "Sort: Hype Score" looks like a control and is not. |
| My Gems sub-tab | **merge → "Your board"** | Your followed gems, each with its newest update and whether it's quiet. Replaces Profile › Following too. Its "New updates" stat is actually *all* updates. |
| Filter sheet | rebuild | Applies only to Discover but shows on both sub-tabs. Priority belongs on updates, not gems. |
| Trending screen | cut | Home For you already ranks; old `UpdateCard` design. |
| High / Mid / Low priority screens | cut | Three routes for one list, reachable only from General. |
| Top Hunters screen | **merge → "Hunters"** | One ranking, by reliability, from the server. Replaces all four client-side post counts (incl. Hunter Hub's "Season ranking"). |
| Gem detail | rebuild with Gems | Share and bookmark are stubs, twice. Should show the owner's reliability and the gem's update history as its timeline. |
| Global search | fix | Gem and update results are not tappable. |

### Community
| Screen | Verdict | Notes |
|---|---|---|
| Feed, discussion, create post | keep | Not redesigned; not first. |
| My Reports | **move** | A community feature reachable only via Profile › Settings › Privacy. Belongs on the report flow / Community. |
| Saved community posts | fix | Saved to `/me/bookmarks` and shown nowhere. |

### Mine (today: Mining)
| Screen | Verdict | Notes |
|---|---|---|
| Mining dashboard | keep, later refresh | The habit. Works. |
| Referral code screen | **merge → Mine** | Referrals are a mining-rate mechanic; today "Referrals: N active" is on Mining and the code is two taps into Profile. The downline is fetched on every refresh and shown nowhere. |
| Leaderboard, hourly history | keep | One tap deep, fine. |

### Wallet
| Screen | Verdict | Notes |
|---|---|---|
| Wallet tab | keep, fix headline | Stays in the bar (decided). Lead with real balances — BNP and the assets that move today — not a *Pre-launch* headline. |
| Swap | cut until real | Pre-launch stub. Matches the 2026-09-11 decision: coming-soon entries are hidden until real. |
| Receive on asset detail | fix | Copies the address; the main Receive opens a QR. One behaviour. |
| `/wallet` and `/profile` routes | fix | Push second copies of tab screens (Wallet with no back button). Route to the tab. |

### Profile
| Screen / part | Verdict | Notes |
|---|---|---|
| Hero, edit, settings, help, blocked, deactivate | keep | |
| **Hunter stats / Community voice / Hunter signals** | **move → Hunter Hub** | Duplicates the Hub, and shows "0%" to members who are not hunters. Profile shows the hunter's *reliability* once, compactly, for hunters only. |
| Content section (Submit / Manage gems / Manage updates) | move → Hunter Hub | Third copy of these entry points. |
| Activity / Following / Saved tabs | rebuild | Following → Gems › Your board. Activity rows go nowhere. Saved stays. The "Following" stat counts *people* while the tab lists *gems*. |
| Badges, Quests, Levels | **merge → one "Progress" screen**, later | Three entries for one idea, and levels unlock nothing yet (open question in `PRODUCT.md`). Low priority. |
| Tip history (sent) | keep | |

### Hunter space
| Screen | Verdict | Notes |
|---|---|---|
| **Hunter Hub** | **rebuild — first** | Built around the obligation: *your gems*, each with days since last update, members waiting, open reports, and **Post update** right there. Tips received and reliability as the header. Cut: Season ranking (duplicate, not seasonal), Elite banner (fake target, dead chevron), "Success rate". |
| Manage My Gems | merge → Hub | Read-only list with a dead chevron. |
| Manage Updates | merge → Hub / gem | Add **edit**: `PATCH /updates/:id` exists and nothing calls it, though Profile promises "Review and edit". |
| Create Update | keep, small rebuild | Project picker should show each gem's staleness and waiting count, and open pre-selected when launched from a gem. |
| Submit New Gem | keep | Add a proposal status view (today only a snackbar). |
| Become Hunter | keep | Route `admin_application_reviewed` here, not Profile; add "Open Hunter space" to the unlocked dialog. |
| `project_update_requested` notification | **fix, urgent** | Map it to the Hub / that gem. Today F-42's nudge dead-ends on Home. |

### Moderation space
| Screen | Verdict | Notes |
|---|---|---|
| Hub, Reports, Appeals | keep | |
| Gem "report inactive" | **fix** | Report targets are post/comment/user only, so F-42's inactive-gem reports never reach the queue; `project_reported_inactive` is unmapped. |
| Hub stats | fix | Show 0 on error; duplicate the queue's overview card. |

### Onboarding & notifications
| Part | Verdict | Notes |
|---|---|---|
| Closed-alpha rejection | fix | A snackbar. Needs a screen that says what to do. |
| Getting Started | keep, move | Only reachable from Help; its Mining/Wallet buttons stack duplicate screens. |
| Notification Insights | cut | Read-only digest, nothing tappable; the radar strip and caught-up card do this job now. |
| Cross-space notification sheet | fix | Offers only "Close". Should offer "Switch and open". |

### Console
Not reviewed here. Per the handoff, it waits until two mobile screens share the
new vocabulary.

---

## 4 · The plan

One screen at a time, each with its own brief → design → build → device check,
using the method in [`design-briefs/NEXT_SESSION.md`](design-briefs/NEXT_SESSION.md).

| Step | What | Kind | Why this order |
|---|---|---|---|
| 0 | **Owner decides this map**, and the reliability definition in §2 | decision | Everything after is shaped by it. |
| 1 | **Cleanup pass**: cut orphans and the General tab, map the two F-42 notifications, fix the dead taps and duplicate routes listed above | code, no design | Cheap, makes the app honest, and removes surfaces we'd otherwise design around. |
| 2 | **Reliability** — backend: compute coverage / cadence / response per hunter, one endpoint, one leaderboard | backend | Hunter Hub and Gems both need it. Build the gap first (owner's standing rule). |
| 3 | **Hunter Hub** — brief, design, build | screen | Supply side of the loop. The feed is only as good as what hunters post, and the member-side nudge already exists with nowhere to land. |
| 4 | **Gems** — Discover + Your board + Hunters, absorbing General / Trending / Priority / My Gems / Top Hunters | screen | Demand side. Second screen a new member sees. |
| 5 | **Profile slim** — remove hunter duplicates, fix tabs | screen | Mostly subtraction once 3 and 4 exist. |
| 6 | **Mine + Wallet** — referral merge, wallet headline shows real balances | screen | The habit; low risk. |
| 7 | Community, Progress (badges/quests/levels), console | later | After the vocabulary has settled across the loop screens. |

**Changed from the 2026-09-14 handoff:** it recommended Discover next. This
review puts **Hunter Hub** before Gems, for the reason in §1.1 — and puts a
cleanup pass and the reliability metric ahead of both.

---

## 5 · Decisions (owner, 2026-09-16)

1. **Reliability** (coverage, cadence, response) is the hunter score members see. — agreed
2. **General tab** is cut; its job moves to Gems. — agreed
3. **Wallet stays in the bottom bar.** BNP, USDT and other assets can be sent and received today. — owner overrode the draft
4. **Hunter Hub before Gems.** — agreed
5. **Notification Insights, Trending, Priority screens** are cut. — agreed

Execution: full speed, parallel sub-agents; design briefs for Hunter Hub and Gems go to Claude Design.
