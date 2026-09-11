---
category: Layout
---
Surface container for grouped content: stats, forms, detail panels, list items. Rounded 12px, `bg-card` with a subtle border.

```tsx
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter, Button } from "blocnet-admin";

<Card>
  <CardHeader>
    <CardTitle>Active miners</CardTitle>
    <CardDescription>Sessions in the last 24 hours</CardDescription>
  </CardHeader>
  <CardContent>
    <p className="text-3xl font-semibold tabular-nums">12,480</p>
    <p className="text-xs text-muted-foreground">+8.2% vs. yesterday</p>
  </CardContent>
  <CardFooter>
    <Button variant="outline" size="sm">View report</Button>
  </CardFooter>
</Card>
```

Parts: `Card` (root), `CardHeader` (p-6, stacks title + description with 6px gap), `CardTitle` (`<h3>`-styled, semibold), `CardDescription` (`text-sm text-muted-foreground`), `CardContent` (p-6 with no top padding), `CardFooter` (p-6 without top padding, flex row - actions go here).

Lay cards out with `grid gap-4 sm:grid-cols-2 lg:grid-cols-3`. Use `CardHeader` + `CardContent` for stat tiles; add `CardFooter` only when there are actions.
