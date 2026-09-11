---
category: Forms
---
Single-value picker (Radix Select) styled like `Input`. Parts are exported flat; compose the trigger + content pair.

```tsx
import { Select, SelectTrigger, SelectValue, SelectContent, SelectItem,
  SelectGroup, SelectLabel, SelectSeparator } from "blocnet-admin";

<Select defaultValue="published">
  <SelectTrigger className="w-48">
    <SelectValue placeholder="Status" />
  </SelectTrigger>
  <SelectContent>
    <SelectGroup>
      <SelectLabel>Status</SelectLabel>
      <SelectItem value="draft">Draft</SelectItem>
      <SelectItem value="published">Published</SelectItem>
      <SelectItem value="archived">Archived</SelectItem>
    </SelectGroup>
  </SelectContent>
</Select>
```

Parts: `Select` (root - `value`, `defaultValue`, `onValueChange`, `disabled`), `SelectTrigger` (36px, shows chevron), `SelectValue` (`placeholder`), `SelectContent` (popover list; `position="popper"` is default), `SelectItem` (`value`, `disabled`; shows a check on the selected row), `SelectGroup`, `SelectLabel`, `SelectSeparator`, `SelectScrollUpButton`, `SelectScrollDownButton`.

Give the trigger an explicit width (`w-40`…`w-64` or `w-full`); it does not size to its content.
