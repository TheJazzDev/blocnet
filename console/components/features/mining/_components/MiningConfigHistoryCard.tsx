"use client";

import { useMemo, type ReactNode } from "react";
import { History } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { toMiningConfigHistoryEntry } from "@/lib/api/mining-config-history";
import { useMiningConfigHistoryQuery } from "@/lib/hooks/queries";
import { MiningConfigHistoryItem } from "./MiningConfigHistoryItem";

const HISTORY_LIMIT = 20;

export function MiningConfigHistoryCard({ enabled = true }: { enabled?: boolean }) {
  const query = useMiningConfigHistoryQuery({ enabled, limit: HISTORY_LIMIT });
  const entries = useMemo(
    () => (query.data ?? []).map(toMiningConfigHistoryEntry),
    [query.data],
  );

  return (
    <Card>
      <CardHeader className="p-4 sm:p-6">
        <CardTitle className="flex items-center gap-2 text-sm sm:text-base">
          <History className="h-4 w-4 shrink-0 sm:h-5 sm:w-5" />
          Change history
        </CardTitle>
        <p className="text-xs text-muted-foreground sm:text-sm">
          The last {HISTORY_LIMIT} saves to mining settings, newest first.
        </p>
      </CardHeader>
      <CardContent className="p-4 pt-0 sm:p-6 sm:pt-0">
        <HistoryBody
          loading={query.isLoading}
          error={query.error}
          retrying={query.isFetching}
          onRetry={() => void query.refetch()}
        >
          {entries.length === 0 ? (
            <p className="text-xs text-muted-foreground sm:text-sm">
              No changes recorded yet.
            </p>
          ) : (
            <ul className="space-y-2 sm:space-y-3">
              {entries.map((entry) => (
                <MiningConfigHistoryItem key={entry.id} entry={entry} />
              ))}
            </ul>
          )}
        </HistoryBody>
      </CardContent>
    </Card>
  );
}

type HistoryBodyProps = {
  loading: boolean;
  error: unknown;
  retrying: boolean;
  onRetry: () => void;
  children: ReactNode;
};

function HistoryBody({ loading, error, retrying, onRetry, children }: HistoryBodyProps) {
  if (loading) return <LoadingSpinner className="py-6 sm:py-8" />;

  if (error) {
    const message = error instanceof Error ? error.message : "Failed to load change history";
    return (
      <div className="flex flex-col gap-2 rounded-lg border border-destructive/35 bg-destructive/10 p-3 sm:flex-row sm:items-center sm:justify-between">
        <p className="text-xs text-destructive sm:text-sm">{message}</p>
        <Button variant="outline" size="sm" onClick={onRetry} disabled={retrying}>
          Retry
        </Button>
      </div>
    );
  }

  return <>{children}</>;
}
