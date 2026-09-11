import * as React from "react";
import { Separator } from "blocnet-admin";

export const Horizontal = () => (
  <div className="w-80 space-y-4">
    <div>
      <h4 className="text-sm font-medium">Account</h4>
      <p className="text-sm text-muted-foreground">Signed in as hunter@blocnet.io</p>
    </div>
    <Separator />
    <p className="text-sm text-muted-foreground">Member since March 2026</p>
  </div>
);

export const Vertical = () => (
  <div className="flex h-5 items-center gap-4 text-sm">
    <span>Docs</span>
    <Separator orientation="vertical" />
    <span>Source</span>
    <Separator orientation="vertical" />
    <span>Status</span>
  </div>
);
