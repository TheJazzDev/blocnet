---
category: Actions
---
Primary interactive control. Six visual variants and four sizes, all driven by props - never restyle a button with color utilities.

```tsx
import { Button } from "blocnet-admin";

<Button>Approve project</Button>
<Button variant="secondary">Save draft</Button>
<Button variant="outline">Cancel</Button>
<Button variant="ghost" size="sm">View details</Button>
<Button variant="destructive">Suspend user</Button>
<Button variant="link">Learn more</Button>
<Button size="icon" aria-label="Refresh"><RefreshCw /></Button>
<Button disabled>Processing…</Button>
```

- `variant`: `default` (gradient primary - one per view, the main action), `secondary`, `outline`, `ghost`, `destructive`, `link`.
- `size`: `default` (h-9), `sm` (h-8), `lg` (h-10), `icon` (9×9 square - pass an `aria-label`).
- Icons: put a `lucide-react` icon as a child; the button sizes it to 16px and adds the gap automatically.
- `asChild` renders the styles onto the child element (e.g. an `<a>`), useful for links that look like buttons.
- Loading states: keep the label, add `disabled`, and prefix a spinning `Loader2` icon with `animate-spin`.
