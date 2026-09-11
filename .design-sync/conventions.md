## Blocnet conventions (read first)

**Dark-only admin kit.** Every screen is a dark surface. Wrap each design root in
`<div className="min-h-screen bg-background text-foreground font-sans">` – the tokens live on `:root`
(no provider needed), but the canvas colour only applies when you paint it yourself.
`Tooltip*` parts must sit inside a `TooltipProvider`; everything else works standalone.

**Styling idiom: Tailwind utility classes on semantic tokens.** Never use raw hex or
`bg-blue-500` for chrome – use the token families below. They are the only colour names in
`styles.css`; anything else renders unstyled.

| Family | Classes (all exist in `styles.css`) |
|---|---|
| Canvas / surfaces | `bg-background`, `bg-card`, `bg-popover`, `bg-muted`, `bg-sidebar`, `bg-accent` |
| Text | `text-foreground`, `text-muted-foreground`, `text-card-foreground`, `text-primary`, `text-destructive`, `text-accent-foreground` |
| Brand / actions | `bg-primary text-primary-foreground`, `bg-secondary text-secondary-foreground`, `bg-destructive text-destructive-foreground` |
| Borders / focus | `border-border`, `border-input`, `ring-ring`, `divide-border` |
| Tints (any token) | `bg-primary/10`, `bg-accent/20`, `border-primary/40`, `text-primary/80` – opacity steps 5…90 |
| Data colours | `bg-chart-1` … `bg-chart-5`, `text-chart-2` (indigo, teal, amber, green, orange) |
| Brand gradient | `bg-linear-to-r from-primary to-cyan-400/80` (the primary Button already uses it) |
| Radius | `rounded-md` (inputs/buttons), `rounded-lg`/`rounded-xl` (cards, dialogs), `rounded-full` (badges, avatars) |
| Type | `font-sans` = Geist, `font-mono` = Geist Mono; sizes `text-xs` … `text-3xl`; numbers get `tabular-nums` |
| Spacing / layout | `p-4 sm:p-6`, `gap-3`/`gap-4`, `space-y-2`, `grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3`, `flex items-center justify-between` |

Mobile-first: start small and scale up (`text-sm sm:text-base`, `p-4 sm:p-6 md:p-8`, `flex-col sm:flex-row`).
`sm:`/`md:`/`lg:` and `hover:` variants exist for every family above.

**Where the truth lives.** `styles.css` → `_ds_bundle.css` holds the compiled utilities and the
`:root` token values (`--background`, `--primary`, `--chart-1` …, oklch). `tokens/tokens.css` is the
token list alone. Each `components/<group>/<Name>/<Name>.prompt.md` shows the canonical
composition and lists that family's sub-parts (`CardHeader`, `DialogContent`, `TableRow`,
`SelectItem` …) – those are exported on `window.BlocnetUI` too, even though only the 19
roots have cards. Icons: `lucide-react` (bundled); put them as children of `Button`.

**Idiomatic screen skeleton** (verified render):

```jsx
const { Card, CardHeader, CardTitle, CardDescription, CardContent, Button, Badge, Input } = window.BlocnetUI;

<div className="min-h-screen bg-background text-foreground font-sans p-4 sm:p-6 md:p-8 space-y-6">
  <header className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
    <div>
      <h1 className="text-xl sm:text-2xl font-semibold">Projects</h1>
      <p className="text-sm text-muted-foreground">18 awaiting review</p>
    </div>
    <div className="flex items-center gap-2">
      <Input placeholder="Search projects…" className="w-64" />
      <Button>New project</Button>
    </div>
  </header>
  <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
    <Card>
      <CardHeader className="pb-2">
        <CardDescription>Active miners</CardDescription>
        <CardTitle className="text-2xl tabular-nums">12,480</CardTitle>
      </CardHeader>
      <CardContent className="flex items-center gap-2 text-xs text-muted-foreground">
        <Badge variant="secondary">+8.2%</Badge> vs. yesterday
      </CardContent>
    </Card>
  </div>
</div>
```
