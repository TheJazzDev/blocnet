---
category: Data Display
---
40px circular user image with initials fallback (Radix Avatar). Always provide `AvatarFallback` - it renders while the image loads or when it fails.

```tsx
import { Avatar, AvatarImage, AvatarFallback } from "blocnet-admin";

<Avatar>
  <AvatarImage src={user.avatarUrl} alt={user.displayName} />
  <AvatarFallback>AD</AvatarFallback>
</Avatar>

<Avatar className="h-8 w-8"><AvatarFallback className="text-xs">JD</AvatarFallback></Avatar>
<Avatar className="h-14 w-14"><AvatarFallback className="text-lg">SK</AvatarFallback></Avatar>
```

Parts: `Avatar` (root, sizes via `h-* w-*`), `AvatarImage` (`src`, `alt`), `AvatarFallback` (`bg-muted`, centered initials - keep to 1–2 letters).

Stack avatars with `-space-x-2` and a `ring-2 ring-background` on each for overlapping groups.
