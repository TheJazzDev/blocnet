---
category: Navigation
---
Tabbed sections (Radix Tabs). The list is a pill group on `bg-muted`; the active trigger gets a primary→cyan gradient.

```tsx
import { Tabs, TabsList, TabsTrigger, TabsContent } from "blocnet-admin";

<Tabs defaultValue="overview" className="w-full">
  <TabsList>
    <TabsTrigger value="overview">Overview</TabsTrigger>
    <TabsTrigger value="updates">Updates</TabsTrigger>
    <TabsTrigger value="team">Team</TabsTrigger>
  </TabsList>
  <TabsContent value="overview" className="mt-4">…</TabsContent>
  <TabsContent value="updates" className="mt-4">…</TabsContent>
  <TabsContent value="team" className="mt-4">…</TabsContent>
</Tabs>
```

Parts: `Tabs` (`value`/`defaultValue`, `onValueChange`), `TabsList`, `TabsTrigger` (`value`, `disabled`), `TabsContent` (`value`).

Use `TabsList className="grid w-full grid-cols-3"` for full-width equal tabs.
