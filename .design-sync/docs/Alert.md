---
category: Feedback
---
Inline callout for status, warnings and errors. Two variants; an optional leading `lucide-react` icon slots into the grid automatically.

```tsx
import { Alert, AlertTitle, AlertDescription } from "blocnet-admin";
import { Info, AlertTriangle } from "lucide-react";

<Alert>
  <Info />
  <AlertTitle>Edge Engine sync scheduled</AlertTitle>
  <AlertDescription>Scores refresh every 6 hours. Manual runs are logged.</AlertDescription>
</Alert>

<Alert variant="destructive">
  <AlertTriangle />
  <AlertTitle>Wallet service unreachable</AlertTitle>
  <AlertDescription>Withdrawals are paused until the Turnkey connection recovers.</AlertDescription>
</Alert>
```

Parts: `Alert` (`variant`: `default` | `destructive`), `AlertTitle` (medium, single line), `AlertDescription` (`text-sm text-muted-foreground`, may contain a paragraph or list).
