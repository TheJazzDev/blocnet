---
category: Feedback
---
Centered spinner with a label for loading panels and pages (min height 96px). Not for inline button loading - use a `Loader2` icon inside `Button` for that.

```tsx
import { LoadingSpinner } from "blocnet-admin";

<LoadingSpinner />
<LoadingSpinner label="Fetching leaderboard…" />
<LoadingSpinner className="min-h-64" />
```

- `label`: text next to the spinner (default "Loading...").
- `className`: adjust height/placement of the outer flex container.
