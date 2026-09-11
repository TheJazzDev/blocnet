import * as React from "react";
import { Input, Label } from "blocnet-admin";

export const WithInput = () => (
  <div className="w-80 space-y-2">
    <Label htmlFor="email">Email address</Label>
    <Input id="email" type="email" placeholder="you@blocnet.io" />
  </div>
);

export const Required = () => (
  <div className="w-80 space-y-2">
    <Label htmlFor="name">
      Project name <span className="text-destructive">*</span>
    </Label>
    <Input id="name" placeholder="Nebula Swap" />
  </div>
);

export const DisabledPeer = () => (
  <div className="w-80 space-y-2">
    <Input id="locked" className="peer" defaultValue="Locked by admin" disabled />
    <Label htmlFor="locked">Wallet address</Label>
  </div>
);
