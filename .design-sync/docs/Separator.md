---
category: Layout
---
Thin divider line (`bg-border`). Horizontal by default; `orientation="vertical"` for inline separators.

```tsx
import { Separator } from "blocnet-admin";

<div className="space-y-4">
  <h4 className="text-sm font-medium">Account</h4>
  <Separator />
  <p className="text-sm text-muted-foreground">Signed in as hunter@blocnet.io</p>
</div>

<div className="flex h-5 items-center gap-4 text-sm">
  <span>Docs</span><Separator orientation="vertical" /><span>Source</span><Separator orientation="vertical" /><span>Status</span>
</div>
```

`decorative` (default `true`) hides it from assistive tech; pass `decorative={false}` when the separator carries meaning.
