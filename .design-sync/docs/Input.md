---
category: Forms
---
Single-line text field. A styled native `<input>`: every native attribute (`type`, `placeholder`, `value`, `disabled`, `required`) passes through.

```tsx
import { Input, Label } from "blocnet-admin";

<div className="space-y-2">
  <Label htmlFor="handle">Username</Label>
  <Input id="handle" placeholder="@satoshi" />
</div>
<Input type="email" placeholder="you@blocnet.io" />
<Input type="number" placeholder="0.00" />
<Input placeholder="Search projects…" className="max-w-sm" />
<Input disabled value="Read only" />
```

- Height is 36px (`h-9`), full width by default - constrain with `max-w-*` on the input or its wrapper.
- Pair with `Label` (`htmlFor` ↔ `id`) and helper text in `text-xs text-muted-foreground`.
- Error state: add `aria-invalid` and `className="border-destructive focus-visible:ring-destructive"`.
- For search fields, wrap in a `relative` div and absolutely position a `lucide-react` icon with `pl-9` on the input.
