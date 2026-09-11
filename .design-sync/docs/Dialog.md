---
category: Overlays
---
Modal dialog (Radix Dialog) with a blurred overlay and a centered 512px panel. Parts are exported flat.

```tsx
import { Dialog, DialogTrigger, DialogContent, DialogHeader, DialogTitle, DialogDescription,
  DialogFooter, DialogClose, Button, Input, Label } from "blocnet-admin";

<Dialog>
  <DialogTrigger asChild><Button>Invite moderator</Button></DialogTrigger>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Invite moderator</DialogTitle>
      <DialogDescription>They will get content-moderation access only.</DialogDescription>
    </DialogHeader>
    <div className="space-y-2">
      <Label htmlFor="inv">Email</Label>
      <Input id="inv" type="email" placeholder="name@blocnet.io" />
    </div>
    <DialogFooter>
      <DialogClose asChild><Button variant="outline">Cancel</Button></DialogClose>
      <Button>Send invite</Button>
    </DialogFooter>
  </DialogContent>
</Dialog>
```

Parts: `Dialog` (root - `open`, `onOpenChange`), `DialogTrigger` (`asChild`), `DialogContent` (panel; includes the overlay and a top-right close X), `DialogHeader` (stacked, centered on mobile), `DialogTitle`, `DialogDescription`, `DialogFooter` (actions; stacks on mobile, right-aligned row on `sm+`), `DialogClose` (`asChild`), `DialogOverlay`, `DialogPortal`.

Widen with `className="sm:max-w-2xl"` on `DialogContent`. Destructive confirmations: `variant="destructive"` for the confirm button, `outline` for cancel.
