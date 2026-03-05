"use client";

import { useState } from "react";
import { ChevronLeft, ChevronRight, Loader2, RefreshCw, Search, X } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { type AdminMiningLeaderboardEntry } from "@/lib/api-client";
import { useMiningLeaderboardQuery } from "@/lib/hooks/queries";
import { useDebounce } from "@/lib/hooks";

const PAGE_SIZE = 50;

export default function MiningLeaderboardPage() {
  const [offset, setOffset] = useState(0);
  const [searchInput, setSearchInput] = useState("");

  // Debounce search input
  const q = useDebounce(searchInput.trim(), 300);

  // TanStack Query hook
  const {
    data,
    isLoading: loading,
    error: queryError,
    refetch,
  } = useMiningLeaderboardQuery({
    q: q || undefined,
    limit: PAGE_SIZE,
    offset,
  });

  const rows = data?.data ?? [];
  const total = data?.total ?? 0;
  const asOf = data?.asOf ?? null;
  const error = queryError instanceof Error ? queryError.message : null;

  const startIndex = total === 0 ? 0 : offset + 1;
  const endIndex = offset + rows.length;
  const hasPrevious = offset > 0;
  const hasNext = endIndex < total;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Mining Leaderboard"
        description="Search and review miner rankings by total earned BNP."
      >
        <Button variant="outline" onClick={() => refetch()} disabled={loading}>
          {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
          Refresh
        </Button>
      </PageHeader>

      <Card>
        <CardContent className="pt-6">
          <div className="grid gap-3 md:grid-cols-[1fr_auto]">
            <div className="relative">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={searchInput}
                onChange={(event) => setSearchInput(event.target.value)}
                placeholder="Search by name, username, email, or user ID"
                className="pl-9 pr-9"
              />
              {searchInput.trim().length > 0 && (
                <button
                  type="button"
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                  onClick={() => setSearchInput("")}
                  aria-label="Clear search"
                >
                  <X className="h-4 w-4" />
                </button>
              )}
            </div>
            <div className="flex items-center justify-end gap-2">
              <Badge variant="outline">
                {startIndex}-{endIndex} of {total}
              </Badge>
            </div>
          </div>
        </CardContent>
      </Card>

      {error && (
        <Card>
          <CardContent className="pt-6 text-sm text-destructive">{error}</CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Rankings</CardTitle>
          {asOf ? (
            <p className="text-xs text-muted-foreground">Snapshot: {formatDateTime(asOf)}</p>
          ) : null}
        </CardHeader>
        <CardContent>
          {loading ? (
            <LoadingSpinner className="py-10" />
          ) : rows.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              {q
                ? `No miners matched "${q}".`
                : "No mining leaderboard entries yet."}
            </p>
          ) : (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-16">Rank</TableHead>
                    <TableHead>Miner</TableHead>
                    <TableHead className="text-right">Lifetime</TableHead>
                    <TableHead className="text-right">Claimed</TableHead>
                    <TableHead className="text-right">Unclaimed</TableHead>
                    <TableHead className="text-right">Referrals</TableHead>
                    <TableHead className="text-right">Boost</TableHead>
                    <TableHead className="text-right">Session</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {rows.map((entry) => (
                    <TableRow key={entry.userId}>
                      <TableCell className="font-semibold">#{entry.rank}</TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Avatar className="h-8 w-8">
                            <AvatarImage src={entry.avatarUrl ?? undefined} alt={formatMinerName(entry)} />
                            <AvatarFallback>{getMinerInitials(entry)}</AvatarFallback>
                          </Avatar>
                          <div className="min-w-0">
                            <p className="truncate text-sm font-medium">{formatMinerName(entry)}</p>
                            <p className="truncate text-xs text-muted-foreground">
                              {entry.email ?? entry.userId}
                            </p>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell className="text-right font-medium">
                        {formatNumber(entry.lifetimeEarnedPoints)}
                      </TableCell>
                      <TableCell className="text-right text-muted-foreground">
                        {formatNumber(entry.claimedTotalPoints)}
                      </TableCell>
                      <TableCell className="text-right text-muted-foreground">
                        {formatNumber(entry.maturedUnclaimedPoints)}
                      </TableCell>
                      <TableCell className="text-right text-muted-foreground">
                        {entry.activeReferralsSnapshot}
                      </TableCell>
                      <TableCell className="text-right text-muted-foreground">
                        {(entry.boostBpsSnapshot / 100).toFixed(2)}%
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="inline-flex flex-col items-end gap-1">
                          <Badge variant="outline" className={sessionStatusClassName(entry.sessionStatus)}>
                            {entry.sessionStatus}
                          </Badge>
                          {entry.sessionEndsAt ? (
                            <span className="text-[11px] text-muted-foreground">
                              Ends {formatDateTime(entry.sessionEndsAt)}
                            </span>
                          ) : null}
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      <div className="flex items-center justify-end gap-2">
        <Button
          variant="outline"
          onClick={() => setOffset((value) => Math.max(0, value - PAGE_SIZE))}
          disabled={!hasPrevious || loading}
        >
          <ChevronLeft className="h-4 w-4" />
          Previous
        </Button>
        <Button
          variant="outline"
          onClick={() => setOffset((value) => value + PAGE_SIZE)}
          disabled={!hasNext || loading}
        >
          Next
          <ChevronRight className="h-4 w-4" />
        </Button>
      </div>
    </div>
  );
}

function formatNumber(value: number) {
  return new Intl.NumberFormat("en-US").format(value);
}

function formatDateTime(value: string) {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return value;
  return parsed.toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatMinerName(entry: AdminMiningLeaderboardEntry) {
  if (entry.displayName && entry.displayName.trim().length > 0) {
    return entry.displayName.trim();
  }
  if (entry.username && entry.username.trim().length > 0) {
    return `@${entry.username.trim()}`;
  }
  return entry.userId;
}

function getMinerInitials(entry: AdminMiningLeaderboardEntry) {
  const source = formatMinerName(entry);
  return source
    .replace("@", "")
    .split(/\s+/)
    .filter(Boolean)
    .map((word) => word[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();
}

function sessionStatusClassName(status: AdminMiningLeaderboardEntry["sessionStatus"]) {
  if (status === "claimable") {
    return "border-emerald-500/40 bg-emerald-500/10 text-emerald-300";
  }
  if (status === "running") {
    return "border-cyan-500/40 bg-cyan-500/10 text-cyan-300";
  }
  return "border-muted text-muted-foreground";
}
