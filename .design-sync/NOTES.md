# design-sync notes (Blocnet console UI kit)

- **Source**: `console/components/ui` (shadcn-style, Radix + CVA + Tailwind v4). The console is a Next.js app with no library build, so the converter runs in synth-entry mode (`--entry ./console/dist/index.js` deliberately does not exist; `[NO_DIST]` is expected).
- **Declarations**: `node .design-sync/build-dts.mjs` emits `console/dist/types/**.d.ts` + `index.d.ts` barrel with the console's own `typescript`; `console/package.json` `"types": "dist/types/index.d.ts"` points the converter at it (inert for Next). Without this every `<Name>Props` is an empty stub. `console/dist/` is gitignored.
- **CSS**: Tailwind v4 must be compiled. `node .design-sync/build-css.mjs` runs `@tailwindcss/postcss` over `.design-sync/tailwind/entry.css` (imports `console/app/globals.css`, scans the whole console for used classes, plus a safelist of layout/color utilities for the design agent) into `console/.ds-css/styles.css` = `cfg.cssEntry`. ~470 KB minified.
- **Canvas**: the console is dark-only and sets the body canvas inside `@layer base`. The preview card template hardcodes an unlayered white body, and unlayered beats layered, so `entry.css` restates `html body { background-color: var(--background); color: var(--foreground) }` unlayered (specificity 0,0,2 so it also beats the inline `body{background:#fff}` that comes after the stylesheet links).
- **Fonts**: Geist / Geist Mono come from next/font (`geist` npm package) at runtime in the app; `.design-sync/fonts/geist.css` declares static `@font-face` rules for the variable woff2 files under `console/node_modules/geist/dist/fonts/` (cfg.extraFonts). Family names match `--font-sans`/`--font-mono` in globals.css.
- **Sub-parts**: the 55 compound parts (CardHeader, DialogContent, TableRow, …) are excluded from the card list via `componentSrcMap: null` - they still ship in the bundle (76 exports on `window.BlocnetUI`) and are documented in the parent's `.design-sync/docs/<Root>.md`, which also sets the group via `category:` frontmatter.
- **Browser for render checks**: no Playwright browser download - use the user's installed Google Chrome: `DS_CHROMIUM_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"` for `package-validate.mjs`, `package-capture.mjs`, `resync.mjs`. Only the `playwright` npm package is installed in `.ds-sync/` (`PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1`).
- **Toaster** (Sonner host) renders nothing without a fired toast and `toast()` is not exported from the bundle - intentionally left on the floor card.
- **Build order for a re-sync** (from the repo root): `node .design-sync/build-css.mjs && node .design-sync/build-dts.mjs` (= cfg.buildCmd), then the driver with `--node-modules ./console/node_modules --entry ./console/dist/index.js`.
- **Tokens**: `build-css.mjs` also writes a pseudo-package `console/node_modules/@blocnet/console-tokens/{package.json,tokens.css}` (the `:root` block of globals.css, verbatim) because the converter only copies tokens from a node_modules package (`cfg.tokensPkg` + `cfg.tokensGlob`). Without it the README token index lists Tailwind's `--tw-*` internals. Re-created on every buildCmd run; fine after a fresh install.
- **Utility safelist**: `styles.css` only contains classes the console uses + the `@source inline(...)` safelist in `.design-sync/tailwind/entry.css`. A class outside that set silently does nothing (caught once: `w-14` on the Avatar Sizes story). When a preview or a design needs a new scale step, extend the safelist, not the component.
- **Card overrides** (`cfg.overrides`): open overlays (Dialog, DropdownMenu, Select, Tooltip) use `cardMode: single` + a viewport so the popover renders inside the card; wide stories (Card, Table, Tabs, Textarea, Switch, ScrollArea, LoadingSpinner) use `cardMode: column` after `[GRID_OVERFLOW]` warns.
- **Known render warns**: none - the final validate is warning-free (`validate-4.log`, driver-1.log).

- **Build order matters: previews before CSS.** `build-css.mjs` scans `.design-sync/previews/` via `@source`. If you author a new preview and rebuild the bundle *without* re-running `build-css.mjs` first, any utility class only that preview uses is missing from `styles.css` and the card renders subtly wrong with no error. Caught once on `Collapsible` (`group-data-[state=closed]:-rotate-90` silently absent, chevrons never rotated). **Always run `cfg.buildCmd` before `package-build.mjs`.**
- **Rotate/transform utilities** are safelisted in `tailwind/entry.css` (`rotate-*`, `group-data-[state=closed]:*`, `data-[state=open]:*`). Radix components signal state through `data-state`, so a design that animates a chevron or caret needs those variants present.
- **Brand accent is Signal Cyan** as of 2026-09-11: mobile `userAccent` #0891B2 / `hunterAccent` #22D3EE, console `--primary` `oklch(0.609 0.111 221.5)`. Both flow into the design system automatically through `globals.css` → `build-css.mjs`. `--chart-1` is deliberately left periwinkle: categorical data colour is independent of the accent.

## Known false positive: the `--tw-*` token count

The project's self-check reports **568 tokens** where Blocnet has **33**. Breakdown: 387
Tailwind bookkeeping vars (`--tw-translate-*`, `--tw-scale-*`, `--tw-border-style`,
`--tw-divide-*-reverse`, `--tw-outline-style`), 148 Tailwind default-theme vars, and the
33 real ones. Every one is attributed to `_ds_bundle.css`; none to `tokens/tokens.css`.

**Ignore it.** Confirmed with Claude Design 2026-09-12: the internals are correctly scoped
to their utility classes, carry no design meaning, and the design system renders and works
correctly as shipped. Blocnet's real tokens are the 33 under `:root` in `tokens/tokens.css`,
which the `@blocnet/console-tokens` pseudo-package already isolates (that fix cleaned up
the README index; it does not reach this scanner).

**Not fixable from either side.**

- *In the design project* — `styles.css` and `_ds_bundle.css` are synced source and
  read-only there. Standing rule from the user: **no changes to the synced files.**
- *Here* — `_ds_bundle.css` is the converter's copy of `cfg.cssEntry`, and the compiled
  utilities must be in it or no design renders. Splitting them into a file "the scanner
  doesn't read" means guessing which paths it scans, and a wrong guess drops CSS out of
  the `@import` closure and breaks every rendered design. Not worth it.
- *Upstream* — the classifier is in the bundled `design-sync` skill
  (`bundled-skills/<version>/…/design-sync`), which is versioned and replaced on upgrade,
  so a local edit there would not survive. The real fix is to exclude `--tw-*` from token
  extraction in that skill. Reported through `/feedback`.

Expect this check to fire on **every** run until that ships. It is not a regression and
needs no action.

## Re-sync risks

- `console/app/globals.css` is the single source of tokens, fonts and the body canvas; any change there flows through `build-css.mjs` automatically, but a rename of `--font-sans` family names must be mirrored in `.design-sync/fonts/geist.css`.
- The dark canvas depends on the unlayered `html body` rule in `tailwind/entry.css`; if the card template ever links stylesheets after its inline `<style>`, the rule still wins on specificity, but check the contact sheet for white cells after a converter upgrade.
- `console/package.json` `"types"` must stay `dist/types/index.d.ts`; removing it silently degrades every `<Name>Props` to an empty stub (validate does not fail on that).
- Previews compose real console usage (Blocnet copy: projects, hunters, miners). If a component's variant set changes in `components/ui/*.tsx`, the matching `.design-sync/docs/<Name>.md` and `previews/<Name>.tsx` need a manual edit - docs are hand-written, not generated.
- Toolchain assumed: node 22, bun-installed `console/node_modules` (react 19.2, tailwindcss 4.1, typescript 5.8), Google Chrome at the DS_CHROMIUM_PATH above (Playwright 1.63 driver, no bundled browser).
- Not verified: Toaster (floor card by design); hover/focus/drag states; the Sonner `toast()` API is not part of the bundle.
