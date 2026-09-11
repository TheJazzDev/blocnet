---
category: Forms
---
Multi-line text field with the same border, background and focus ring as `Input`. Minimum height 60px; grows with `rows`.

```tsx
import { Textarea, Label } from "blocnet-admin";

<div className="space-y-2">
  <Label htmlFor="notes">Moderation note</Label>
  <Textarea id="notes" placeholder="Why is this update being rejected?" rows={4} />
  <p className="text-xs text-muted-foreground">Visible to the project team.</p>
</div>
```

All native `<textarea>` attributes pass through (`rows`, `maxLength`, `disabled`, `value`, `onChange`).
