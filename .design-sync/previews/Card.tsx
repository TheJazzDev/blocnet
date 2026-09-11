import * as React from "react";
import {
  Badge,
  Button,
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "blocnet-admin";

export const StatTile = () => (
  <Card className="w-72">
    <CardHeader>
      <CardTitle>Active miners</CardTitle>
      <CardDescription>Sessions in the last 24 hours</CardDescription>
    </CardHeader>
    <CardContent>
      <p className="text-3xl font-semibold tabular-nums">12,480</p>
      <p className="text-xs text-muted-foreground">+8.2% vs. yesterday</p>
    </CardContent>
  </Card>
);

export const WithFooterActions = () => (
  <Card className="w-96">
    <CardHeader>
      <div className="flex items-start justify-between gap-3">
        <div className="space-y-1.5">
          <CardTitle>Nebula Swap</CardTitle>
          <CardDescription>Cross-chain DEX aggregator on Base and Solana</CardDescription>
        </div>
        <Badge variant="secondary">Pending</Badge>
      </div>
    </CardHeader>
    <CardContent className="space-y-3 text-sm">
      <p className="text-muted-foreground">
        Submitted by <span className="text-foreground">@ada</span> · Edge score{" "}
        <span className="font-medium tabular-nums text-foreground">87</span>
      </p>
      <p>
        Nebula routes swaps across 14 liquidity venues and settles in under two seconds. The
        team shipped audited contracts and a public roadmap this quarter.
      </p>
    </CardContent>
    <CardFooter className="gap-2">
      <Button size="sm">Approve</Button>
      <Button variant="outline" size="sm">
        Request changes
      </Button>
    </CardFooter>
  </Card>
);

export const StatGrid = () => (
  <div className="grid w-full max-w-3xl grid-cols-1 gap-4 sm:grid-cols-3">
    {[
      ["Total users", "48,210", "+1,204 this week"],
      ["Projects live", "312", "18 awaiting review"],
      ["Tokens mined", "9.4M", "Season 3 · day 41"],
    ].map(([title, value, note]) => (
      <Card key={title}>
        <CardHeader className="pb-2">
          <CardDescription>{title}</CardDescription>
          <CardTitle className="text-2xl tabular-nums">{value}</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-xs text-muted-foreground">{note}</p>
        </CardContent>
      </Card>
    ))}
  </div>
);
