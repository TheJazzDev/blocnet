---
category: Feedback
---
Toast host (Sonner) preconfigured for the console: top-right, rich colors, close button, 4s duration. Mount once at the app root; fire toasts with Sonner's `toast()` from the `sonner` package.

```tsx
import { Toaster } from "blocnet-admin";
import { toast } from "sonner";

<Toaster />
toast.success("Project approved");
toast.error("Could not save changes");
```

Renders nothing until a toast is fired, so it has no static preview. All Sonner `ToasterProps` pass through (`position`, `duration`, `theme`).
