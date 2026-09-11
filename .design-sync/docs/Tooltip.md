---
category: Feedback
---
Hover/focus hint (Radix Tooltip). Wrap a subtree in `TooltipProvider` once, then compose `Tooltip` → `TooltipTrigger` + `TooltipContent`.

```tsx
import { Tooltip, TooltipProvider, TooltipTrigger, TooltipContent, Button } from "blocnet-admin";

<TooltipProvider>
  <Tooltip>
    <TooltipTrigger asChild>
      <Button variant="ghost" size="icon" aria-label="Refresh"><RefreshCw /></Button>
    </TooltipTrigger>
    <TooltipContent>Refresh leaderboard</TooltipContent>
  </Tooltip>
</TooltipProvider>
```

Parts: `TooltipProvider` (`delayDuration`), `Tooltip` (`open`, `defaultOpen`), `TooltipTrigger` (`asChild`), `TooltipContent` (`side`, `sideOffset`; dark `bg-popover` with 12px text).

Without a `TooltipProvider` ancestor the tooltip throws - the provider is required.
