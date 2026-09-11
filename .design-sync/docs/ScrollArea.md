---
category: Layout
---
Scrollable region with the DS's slim custom scrollbar (Radix ScrollArea). Give it a fixed height (or width for horizontal) - it clips to its box.

```tsx
import { ScrollArea, Separator } from "blocnet-admin";

<ScrollArea className="h-72 w-64 rounded-md border border-border">
  <div className="p-4">
    <h4 className="mb-3 text-sm font-medium">Recent updates</h4>
    {updates.map((u) => (
      <div key={u.id}>
        <p className="text-sm">{u.title}</p>
        <Separator className="my-2" />
      </div>
    ))}
  </div>
</ScrollArea>
```

Parts: `ScrollArea` (root + viewport + vertical `ScrollBar` built in), `ScrollBar` (`orientation="horizontal"` to add a horizontal bar inside a `ScrollArea`).
