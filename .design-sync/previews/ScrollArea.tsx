import * as React from "react";
import { ScrollArea, ScrollBar, Separator } from "blocnet-admin";

const updates = [
  "Mainnet contracts audited by Zellic",
  "Season 3 mining rewards distributed",
  "Edge Engine v2 scoring live",
  "Hunter onboarding revamped",
  "Wallet KYC tier 2 enabled",
  "Community posts get threaded replies",
  "Referral downlines now capped at 5 levels",
  "Quest verification moved server-side",
  "Push notifications for urgent updates",
  "Level badges shipped to mobile",
];

export const Vertical = () => (
  <ScrollArea className="h-64 w-72 rounded-md border border-border">
    <div className="p-4">
      <h4 className="mb-3 text-sm font-medium">Recent updates</h4>
      {updates.map((u) => (
        <div key={u}>
          <p className="text-sm">{u}</p>
          <Separator className="my-2" />
        </div>
      ))}
    </div>
  </ScrollArea>
);

export const Horizontal = () => (
  <ScrollArea className="w-96 whitespace-nowrap rounded-md border border-border">
    <div className="flex w-max gap-3 p-4">
      {["Nebula Swap", "Orbit Lend", "Photon Bridge", "Quasar Pay", "Nova Vault", "Comet DEX"].map((p) => (
        <div key={p} className="w-40 shrink-0 rounded-lg border border-border bg-card p-3 text-sm">
          <p className="font-medium">{p}</p>
          <p className="text-xs text-muted-foreground">Edge score 8{p.length}</p>
        </div>
      ))}
    </div>
    <ScrollBar orientation="horizontal" />
  </ScrollArea>
);
