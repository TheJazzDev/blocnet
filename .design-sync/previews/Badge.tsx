import * as React from "react";
import { Badge } from "blocnet-admin";
import { Sparkles } from "lucide-react";

export const Variants = () => (
  <div className="flex flex-wrap items-center gap-2">
    <Badge>Featured</Badge>
    <Badge variant="secondary">Pending</Badge>
    <Badge variant="outline">Draft</Badge>
    <Badge variant="destructive">Suspended</Badge>
  </div>
);

export const StatusRow = () => (
  <div className="flex flex-wrap items-center gap-2 text-sm">
    <span className="text-muted-foreground">Nebula Swap</span>
    <Badge variant="secondary">Published</Badge>
    <Badge variant="outline">DeFi</Badge>
    <Badge>
      <Sparkles className="mr-1 size-3" /> Top 10
    </Badge>
  </div>
);
