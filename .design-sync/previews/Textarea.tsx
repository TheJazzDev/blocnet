import * as React from "react";
import { Label, Textarea } from "blocnet-admin";

export const WithLabel = () => (
  <div className="w-96 space-y-2">
    <Label htmlFor="notes">Moderation note</Label>
    <Textarea id="notes" placeholder="Why is this update being rejected?" rows={4} />
    <p className="text-xs text-muted-foreground">Visible to the project team.</p>
  </div>
);

export const Filled = () => (
  <Textarea
    className="w-96"
    rows={4}
    defaultValue="Nebula routes swaps across 14 liquidity venues and settles in under two seconds. The team shipped audited contracts this quarter."
  />
);

export const Disabled = () => <Textarea className="w-96" disabled defaultValue="Locked while the update is under review." />;
