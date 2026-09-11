---
category: Layout
---
Disclosure container (Radix Collapsible). Used in the console for collapsible sidebar nav groups; works anywhere a section should expand and collapse in place.

```tsx
import { Collapsible, CollapsibleTrigger, CollapsibleContent, Button } from "blocnet-admin";
import { ChevronDown } from "lucide-react";

<Collapsible defaultOpen>
  <CollapsibleTrigger className="group flex w-full items-center justify-between rounded-md px-2 py-1.5 text-xs font-semibold uppercase tracking-wide text-muted-foreground hover:text-foreground">
    Economy
    <ChevronDown className="size-4 transition-transform group-data-[state=closed]:-rotate-90" />
  </CollapsibleTrigger>
  <CollapsibleContent className="mt-1 space-y-0.5">
    <a className="block rounded-md px-2 py-1.5 text-sm text-muted-foreground hover:bg-accent/70 hover:text-foreground" href="#">Wallet users</a>
    <a className="block rounded-md px-2 py-1.5 text-sm text-muted-foreground hover:bg-accent/70 hover:text-foreground" href="#">Withdrawals</a>
  </CollapsibleContent>
</Collapsible>
```

Parts: `Collapsible` (root — `open`, `defaultOpen`, `onOpenChange`, `disabled`), `CollapsibleTrigger` (`asChild`; carries `data-state="open" | "closed"`), `CollapsibleContent`.

- The content is removed from the layout when closed, so the surrounding stack reflows. For a persistent height, use `Tabs` instead.
- Rotate the chevron off the trigger's `data-state` rather than tracking open state yourself.
- Uncontrolled by default. Pass `open` + `onOpenChange` only when something outside the group needs to drive it.
