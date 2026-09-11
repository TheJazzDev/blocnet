import * as React from "react";
import { Input, Label } from "blocnet-admin";
import { Search } from "lucide-react";

export const WithLabel = () => (
  <div className="w-80 space-y-2">
    <Label htmlFor="handle">Username</Label>
    <Input id="handle" placeholder="@satoshi" />
    <p className="text-xs text-muted-foreground">Letters, numbers and underscores only.</p>
  </div>
);

export const Types = () => (
  <div className="w-80 space-y-3">
    <Input type="email" placeholder="you@blocnet.io" />
    <Input type="number" placeholder="0.00" />
    <Input type="password" defaultValue="hunter2hunter2" />
  </div>
);

export const SearchField = () => (
  <div className="relative w-80">
    <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
    <Input placeholder="Search projects…" className="pl-9" />
  </div>
);

export const States = () => (
  <div className="w-80 space-y-3">
    <Input defaultValue="Read only value" disabled />
    <Input
      aria-invalid
      defaultValue="not-an-email"
      className="border-destructive focus-visible:ring-destructive"
    />
  </div>
);
