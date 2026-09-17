# Blocnet visual language (mobile)

> Decided 2026-09-17. The owner rejected the Claude Design look ("too AI") and
> will not run more design rounds. **Every new or changed screen is built
> directly in this language.** No design canvases, no new visual ideas.

Reference screenshots of the old app: [`reference/`](reference/).

The shared pieces live in `lib/shared/widgets/` (`widgets.dart`): `AppPill.caps`,
`AppButton` (compact 40px size, `outline` / `tinted` variants), `AppListRow`,
`AppRowGroup`, `AppHairline`, `AppStatTile`, `AppIconSquare`, `AppSurface`. The one
toast is `AppSnackbar` (`lib/widgets/app_snackbar.dart`); never
`ScaffoldMessenger`, whose snack bars sit under sheets.

Screens already in this language (copy their patterns):

| Screen | Where | Helpers worth reusing |
|---|---|---|
| Home feed | `features/projects/presentation/widgets/home/` | `HomePanel`, `HomePanelHeader` (`home_panel.dart`), `feed_card/*`, `feed_follow_row.dart`, `feed_top_hunters.dart` |
| Hunter Hub + gem page | `features/hunter/presentation/widgets/hub/` | `HubType`, `HubTone` (`parts/hub_styles.dart`) |
| Mine | `features/mining/presentation/` | `MineSectionHeader`, `MineLinkRow` |

## Tokens

- Colours: `AppColors` only. Accent is `primary500` / `primary400`, which follow
  the space (bright cyan `#0deef2` in Hunter space, blue `#2563EB` in User space).
  Status: `tagAirdrop` orange, `warning500` amber, `tagWarning` red,
  `successColor` green, `tagPartnership` purple (the HUNTER role).
  **No new hex values in feature code.**
- Sizes: `AppText` (10 caption · 12 label · 14 body · 16 subtitle · 18 title ·
  22 headline · 28 display · 40 displayXl), `AppSpace` (2·4·8·10·14·20·28·40),
  `AppRadius` (8·12·14·20·pill), `AppIcon` (12·16·18·24·28·40). Keep sizes
  moderate on a 375px phone.

## Patterns

- **Card:** `bgSurface`, 1px `borderSubtle`, `AppRadius.md`, `AppSpace.card`
  padding, content **left-aligned**.
- **Card / section header:** small icon + 10px bold uppercase label with 1.0
  letter-spacing in `textFaint`; optional trailing action ("View All" in the accent).
- **Pill / tag:** outlined, faint tint of its colour (~12–14%), coloured border
  (~35%), coloured 10–12px bold caps text (the old HIGH / HUNTER / AIRDROPS pills).
- **List row:** leading icon (accent) or tinted icon square, bold title, muted
  subtitle, chevron; rows separated by a hairline or sitting in one card.
- **Stat tile:** tinted icon square + small label + value, in a card. Two per row.
- **Feed post:** avatar in a left column; name, role pill, time; "in <gem>" with
  the priority pill on the right; tags; title; body; evenly spaced action row.
- **Buttons:** filled accent (black text on cyan, white on blue), or dark
  outlined; 40–48px tall, `AppRadius.md`.

## Don't

- Centred hero cards with rings/ticks, rows of big numbers with uppercase
  captions under them, gradient grounds, glowing coloured side edges.
- Narrated copy. Say the number or the time: "Ready at 12:04", not
  "Claiming adds it to your balance and starts the next cycle straight away".
