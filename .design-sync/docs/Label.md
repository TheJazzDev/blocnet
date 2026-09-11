---
category: Forms
---
Form field label (Radix Label). 14px medium text; dims automatically when a sibling `peer` control is disabled.

```tsx
import { Label, Input, Switch } from "blocnet-admin";

<Label htmlFor="email">Email address</Label>
<Input id="email" type="email" />

<div className="flex items-center gap-3">
  <Switch checked={enabled} onCheckedChange={setEnabled} id="notif" />
  <Label htmlFor="notif">Push notifications</Label>
</div>
```

Always link with `htmlFor` to the control's `id`. Mark required fields with a `<span className="text-destructive">*</span>` inside the label.
