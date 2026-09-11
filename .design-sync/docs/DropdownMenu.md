---
category: Actions
---
Contextual action menu anchored to a trigger (usually a ghost or outline `Button`). Built on Radix; every part is exported flat from the bundle.

```tsx
import { DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem,
  DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuShortcut, DropdownMenuCheckboxItem,
  DropdownMenuRadioGroup, DropdownMenuRadioItem, DropdownMenuGroup, Button } from "blocnet-admin";

<DropdownMenu>
  <DropdownMenuTrigger asChild>
    <Button variant="outline" size="sm">Actions</Button>
  </DropdownMenuTrigger>
  <DropdownMenuContent align="end" className="w-56">
    <DropdownMenuLabel>Project</DropdownMenuLabel>
    <DropdownMenuSeparator />
    <DropdownMenuItem>Edit <DropdownMenuShortcut>⌘E</DropdownMenuShortcut></DropdownMenuItem>
    <DropdownMenuItem>Assign hunter</DropdownMenuItem>
    <DropdownMenuCheckboxItem checked>Featured</DropdownMenuCheckboxItem>
    <DropdownMenuSeparator />
    <DropdownMenuItem className="text-destructive">Archive</DropdownMenuItem>
  </DropdownMenuContent>
</DropdownMenu>
```

Parts: `DropdownMenu` (root, `open`/`onOpenChange`), `DropdownMenuTrigger` (`asChild`), `DropdownMenuContent` (`align`, `side`, `sideOffset`), `DropdownMenuItem` (`inset`, `disabled`, `onSelect`), `DropdownMenuLabel`, `DropdownMenuSeparator`, `DropdownMenuShortcut`, `DropdownMenuGroup`, `DropdownMenuCheckboxItem` (`checked`), `DropdownMenuRadioGroup` + `DropdownMenuRadioItem` (`value`), `DropdownMenuSub` + `DropdownMenuSubTrigger` + `DropdownMenuSubContent`, `DropdownMenuPortal`.

Content is a dark popover (`bg-popover`, `border-border`) with 8px inset items; destructive actions get `className="text-destructive"`.
