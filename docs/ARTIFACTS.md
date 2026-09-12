# Blocnet Artifacts

Formatted versions of the audits, plans and design studies produced for Blocnet. Each is
a private Claude artifact owned by the Blocnet account. **Republishing an artifact keeps
its link**, so these URLs are stable.

**Trimmed 2026-09-12.** This index used to snapshot every artifact ever published, which
grew to twelve rows and 3.4 MB and became an archive pretending to be a reference — with
five superseded feed directions sitting as peers of the current one, which is how a design
round anchors on the wrong file. Only live references keep a local snapshot now. Superseded
work keeps its link and its reasoning; deleted snapshots remain recoverable from the commit
that added them.

The account also holds artifacts for Settrium, Asiko, COZA and OHC FC. Those are
deliberately **not** listed; this index is Blocnet only.

## Build from this

| Artifact | Link | Snapshot | What it is |
|---|---|---|---|
| **Blocnet Home Feed v2** | [open](https://claude.ai/code/artifact/e2b81377-f1a4-4d54-bb7a-e38351fbf5dd) | [`blocnet-home-feed-v2.html`](artifacts/blocnet-home-feed-v2.html) | **The home screen we build.** Home is a social feed; urgency is card treatment, not structure. A deadline is one line in the hunter's own phrasing, stored as a timestamp and rendered as a stated fact — no clock, no progress bar. Five states plus five spec panels: card at rest vs urgent, follow progression, the deadline four ways, the level ladder, and the Ask nudge before and after the tap. Brief: [`home-feed-r6.md`](design-briefs/home-feed-r6.md). |
| **Blocnet Feature Atlas** | [open](https://claude.ai/code/artifact/0279da3b-3cb9-475b-a237-330e98e02614) | [`blocnet-feature-atlas.html`](artifacts/blocnet-feature-atlas.html) | Every feature across mobile, console and backend with a live-verified status, the cross-surface matrix and the dead-code register. Companion to [`FEATURE_ATLAS.md`](FEATURE_ATLAS.md). |
| **Blocnet Level Badges** | [open](https://claude.ai/code/artifact/77634d19-02fa-460f-b562-b8cf6c917f80) | — | The five-tier badge ladder (Iron, Jade, Amethyst, Gold, Ruby) with one colour and frame shape per tier. **No snapshot:** it was 3 MB of inline SVG duplicating assets the repo already versions at [`mobile/assets/badges/`](../mobile/assets/badges/); the tier rules live in [`level_tier.dart`](../mobile/lib/features/levels/domain/level_tier.dart). |

## Why the current design looks the way it does

Decisions now encoded in code. The artifact is the reasoning, including the rejected
options and the contrast maths, which the code does not carry.

| Artifact | Link | Snapshot | Decision it produced |
|---|---|---|---|
| **Blocnet Accent Directions** | [open](https://claude.ai/code/artifact/9b62ac43-9070-4093-ac8b-6ab32c14b08b) | [`blocnet-accent-directions.html`](artifacts/blocnet-accent-directions.html) | Signal Cyan. User `#0891B2`, Hunter `#22D3EE`, now in [`theme.dart`](../mobile/lib/app/theme.dart). Carries WCAG contrast per candidate. |
| **Blocnet Scale Specimen** | [open](https://claude.ai/code/artifact/663c88b7-4cbf-4255-9950-6ea03e8271e7) | [`blocnet-scale-specimen.html`](artifacts/blocnet-scale-specimen.html) | The type, spacing, radius and icon scales, now in [`lib/app/tokens/`](../mobile/lib/app/tokens/). Carries the 13px-vs-15px body decision. |

## Superseded

Links only, no snapshots. Kept because the path to the current design matters; the
reasoning that retired each one is in [`PRODUCT.md`](PRODUCT.md) and the briefs.

| Artifact | Link | Retired because |
|---|---|---|
| Blocnet Home Feed (social, round five) | [open](https://claude.ai/code/artifact/92fa4e4d-d67b-486e-b794-a4963d7bf9ad) | Round six corrects six items; the direction itself stands. |
| Coverage Board Corrected (round four) | [open](https://claude.ai/code/artifact/6d7cf7fe-47d7-402e-951e-25422dd532b1) | The board direction read as a task manager and broke the zero-follow case. |
| Blocnet Coverage Board (round three) | [open](https://claude.ai/code/artifact/29d94194-b9d9-4bab-8c76-7e040ee014ff) | Same, plus its lifecycle rail claimed a phase count nobody can know. |
| Blocnet Feed Directions v2 (round two) | [open](https://claude.ai/code/artifact/80164976-6cd6-4cf0-9637-35065f5c5ac5) | All three directions were one idea: a to-do list. |
| Blocnet Feed Directions (round one) | [open](https://claude.ai/code/artifact/e47f4e48-4505-4939-9e27-9be774c699e8) | Briefed from a field list rather than the product. |
| Blocnet Home Feed audit (round zero) | [open](https://claude.ai/code/artifact/a7d92470-71d3-4616-963d-a075660bca06) | A density optimisation of the existing screen, not a redesign. |
| Fix Ledger | [open](https://claude.ai/code/artifact/573d2f74-11e7-403c-88b0-15697aec58d6) | Superseded for tracking by [`UX_UI_TRACKER.md`](UX_UI_TRACKER.md). |

## Design system

The console UI kit is synced to Claude Design, so the design agent builds with the real
components rather than generic ones.

| | |
|---|---|
| Project | [Blocnet Design System](https://claude.ai/design/p/ac45a2a1-0d3c-443e-a3d0-6a5a5e22b701) |
| Source | `console/components/ui` — 19 components, 76 bundle exports |
| Sync inputs | [`.design-sync/`](../.design-sync/) — config, notes, conventions, per-component docs, previews |
| Re-sync | See [`.design-sync/NOTES.md`](../.design-sync/NOTES.md), which also records the `--tw-*` token-count false positive |

## Related documents

| | |
|---|---|
| What Blocnet is | [`PRODUCT.md`](PRODUCT.md) |
| What people do in it | [`USE_CASES.md`](USE_CASES.md) |
| Home feed brief (**current**) | [`design-briefs/home-feed-r6.md`](design-briefs/home-feed-r6.md) |
| Earlier briefs, with their withdrawal notes | [`design-briefs/`](design-briefs/) |
| Screenshots of the shipping app | [`design-briefs/reference/`](design-briefs/reference/) |
| Implementation tracking | [`UX_UI_TRACKER.md`](UX_UI_TRACKER.md) |

## Adding to this list

Publish, then add a row with the URL. **Only add a local snapshot if someone would open
the file to answer a question** — not as an archive. When work is superseded, move its row
to *Superseded*, drop the snapshot, and say in one line why it was retired.
