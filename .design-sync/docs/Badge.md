---
category: Data Display
---
Small status pill (rounded-full, 12px semibold). Four variants; pick by meaning, not color.

```tsx
import { Badge } from "blocnet-admin";

<Badge>Featured</Badge>                       // gradient primary - highlights
<Badge variant="secondary">Pending</Badge>    // cyan tint - neutral status
<Badge variant="outline">Draft</Badge>        // quiet, bordered
<Badge variant="destructive">Suspended</Badge>
```

- `variant`: `default`, `secondary`, `outline`, `destructive`.
- It is a `<div>`; use `className="gap-1"` and a 12px icon (`className="size-3"`) for icon badges.
- Roles/levels/tiers in Blocnet use `secondary`; moderation flags use `destructive`.
