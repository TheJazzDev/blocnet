---
category: Forms
---
Boolean toggle (36×20). Controlled only: pass `checked` and `onCheckedChange`.

```tsx
import { Switch, Label } from "blocnet-admin";

<div className="flex items-center justify-between rounded-lg border border-border bg-card p-4">
  <div>
    <Label htmlFor="mining">Mining enabled</Label>
    <p className="text-xs text-muted-foreground">Pause to stop new sessions.</p>
  </div>
  <Switch id="mining" checked={miningOn} onCheckedChange={setMiningOn} />
</div>
<Switch checked disabled />
```

Checked track is `bg-primary`, unchecked is `bg-muted-foreground/40`. Use `disabled` for locked settings.
