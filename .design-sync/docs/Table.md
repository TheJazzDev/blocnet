---
category: Data Display
---
Data table for admin lists (users, projects, quests). Semantic `<table>` parts, each exported flat; rows get a hover tint and a bottom border.

```tsx
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell, TableCaption, TableFooter, Badge } from "blocnet-admin";

<Table>
  <TableCaption>Projects awaiting review</TableCaption>
  <TableHeader>
    <TableRow>
      <TableHead>Project</TableHead>
      <TableHead>Hunter</TableHead>
      <TableHead>Status</TableHead>
      <TableHead className="text-right">Score</TableHead>
    </TableRow>
  </TableHeader>
  <TableBody>
    <TableRow>
      <TableCell className="font-medium">Nebula Swap</TableCell>
      <TableCell>@ada</TableCell>
      <TableCell><Badge variant="secondary">Pending</Badge></TableCell>
      <TableCell className="text-right tabular-nums">87</TableCell>
    </TableRow>
  </TableBody>
</Table>
```

Parts: `Table` (wraps in an `overflow-auto` div - safe for narrow screens), `TableHeader`, `TableBody`, `TableFooter`, `TableRow` (`data-state="selected"` tints the row), `TableHead` (48px, muted uppercase-free label), `TableCell` (p-4), `TableCaption`.

Right-align numeric columns with `className="text-right tabular-nums"`. Put the table inside a `Card` for a bordered panel.
