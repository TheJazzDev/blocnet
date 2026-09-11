# Blocnet Artifacts

Live, formatted versions of the audits, plans and design studies produced for Blocnet.
Each one is a private Claude artifact owned by the Blocnet account, and each has a
**snapshot committed to this repo** under [`docs/artifacts/`](artifacts/) so the content
survives independently of the hosting.

The URLs are stable: republishing an artifact updates it in place and keeps the same
link. They are private to the account unless shared from the artifact's own share menu.

| Artifact | Link | Snapshot | What it is |
|---|---|---|---|
| **Blocnet Accent Directions** | [open](https://claude.ai/code/artifact/9b62ac43-9070-4093-ac8b-6ab32c14b08b) | [`blocnet-accent-directions.html`](artifacts/blocnet-accent-directions.html) | Four accent directions on the real mobile home screen, with a User / Hunter / Moderation toggle and WCAG contrast per colour. The study behind the Signal Cyan decision. |
| **Blocnet Feed Directions** | [open](https://claude.ai/code/artifact/e47f4e48-4505-4939-9e27-9be774c699e8) | [`blocnet-feed-directions.html`](artifacts/blocnet-feed-directions.html) | Claude Design's three answers to the home feed brief — Ticker, Radar First, Gems Not Posts — each with its live state and its new-user quiet state at 390×844. Originated in the design project as *Blocnet Home Feed - Three Directions.html*. |
| **Blocnet Home Feed** | [open](https://claude.ai/code/artifact/a7d92470-71d3-4616-963d-a075660bca06) | [`blocnet-home-feed.html`](artifacts/blocnet-home-feed.html) | Audit and redesign proposal for the home feed, measured off the running app. 53% of the first screen goes by before any real content. Current and proposed layouts side by side. |
| **Blocnet Scale Specimen** | [open](https://claude.ai/code/artifact/663c88b7-4cbf-4255-9950-6ea03e8271e7) | [`blocnet-scale-specimen.html`](artifacts/blocnet-scale-specimen.html) | The proposed type, spacing and corner scales, measured from the Flutter source and rendered at true size beside the app as it ships. Carries the body-size decision (13px mechanical vs 15px promoted). |
| **Blocnet Feature Atlas** | [open](https://claude.ai/code/artifact/0279da3b-3cb9-475b-a237-330e98e02614) | [`blocnet-feature-atlas.html`](artifacts/blocnet-feature-atlas.html) | Every feature across mobile, console and backend with a live-verified status, the cross-surface matrix, the dead-code register, and the prioritized UX findings. Companion to [`FEATURE_ATLAS.md`](FEATURE_ATLAS.md). |
| **Fix Ledger** | [open](https://claude.ai/code/artifact/573d2f74-11e7-403c-88b0-15697aec58d6) | [`fix-ledger.html`](artifacts/fix-ledger.html) | The cross-stack bug audit that preceded the UX pass: 18 fixed and deployed, ordered by where fixing pays off. Superseded for tracking by [`UX_UI_TRACKER.md`](UX_UI_TRACKER.md); kept as the record of that session. |
| **Blocnet Level Badges** | [open](https://claude.ai/code/artifact/77634d19-02fa-460f-b562-b8cf6c917f80) | [`blocnet-level-badges.html`](artifacts/blocnet-level-badges.html) | The 15-level badge ladder in two versions: the original sheet, and the five-tier redesign (Iron, Jade, Amethyst, Gold, Ruby) with one colour and frame shape per tier. 3 MB — every badge is an inline SVG. |

## Design system

The console UI kit is synced to Claude Design as a live design system, so the design
agent builds with the real components rather than generic ones.

| | |
|---|---|
| Project | [Blocnet Design System](https://claude.ai/design/p/ac45a2a1-0d3c-443e-a3d0-6a5a5e22b701) |
| Source | `console/components/ui` — 19 components, 76 bundle exports |
| Sync inputs | [`.design-sync/`](../.design-sync/) — config, notes, conventions, per-component docs, previews |
| Re-sync | See [`.design-sync/NOTES.md`](../.design-sync/NOTES.md) |

## Adding to this list

Publish the artifact, then add a row above with its URL and drop a copy of the HTML in
`docs/artifacts/`. Keep the snapshot and the link together — the link is how you edit it,
the snapshot is how you still have it if the link ever goes away.
