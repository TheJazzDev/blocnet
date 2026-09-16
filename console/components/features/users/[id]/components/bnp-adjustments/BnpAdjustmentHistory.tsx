"use client";

import { useState } from "react";
import { Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import type { AdminBnpAdjustment } from "@/lib/api-client";
import { useBnpAdjustmentsQuery } from "@/lib/hooks/queries";
import { cn } from "@/lib/utils";

const PAGE_SIZE = 10;

function actorName(entry: AdminBnpAdjustment): string {
  const actor = entry.actor;
  if (!actor) return "Unknown admin";
  return actor.displayName || (actor.username ? `@${actor.username}` : "Unknown admin");
}

function AdjustmentRow({ entry }: { entry: AdminBnpAdjustment }) {
  const isCredit = entry.amount > 0;
  return (
    <li className="space-y-1 rounded-md border bg-muted/30 p-3 text-xs sm:text-sm">
      <div className="flex items-start justify-between gap-2">
        <span
          className={cn(
            "font-semibold tabular-nums",
            isCredit ? "text-emerald-400" : "text-rose-400",
          )}
        >
          {isCredit ? "+" : "−"}
          {Math.abs(entry.amount).toLocaleString("en-US")} BNP
        </span>
        <span className="shrink-0 text-[11px] text-muted-foreground">
          {new Date(entry.createdAt).toLocaleString()}
        </span>
      </div>
      <p className="break-words">{entry.reason || "—"}</p>
      <p className="text-[11px] text-muted-foreground">
        By {actorName(entry)}
        {entry.balanceBefore && entry.balanceAfter && (
          <>
            {" "}· Wallet {entry.balanceBefore.walletBalance} → {entry.balanceAfter.walletBalance}
          </>
        )}
      </p>
    </li>
  );
}

export function BnpAdjustmentHistory({ userId }: { userId: string }) {
  const [offset, setOffset] = useState(0);
  const query = useBnpAdjustmentsQuery(userId, { limit: PAGE_SIZE, offset });
  const page = query.data;

  if (query.isLoading) {
    return (
      <div className="flex justify-center py-4">
        <Loader2 className="h-4 w-4 animate-spin" />
      </div>
    );
  }

  if (query.error) {
    return (
      <p className="text-xs text-destructive sm:text-sm">
        {query.error instanceof Error ? query.error.message : "Failed to load adjustments"}
      </p>
    );
  }

  if (!page || page.total === 0) {
    return (
      <p className="py-4 text-center text-xs text-muted-foreground sm:text-sm">
        No manual adjustments yet
      </p>
    );
  }

  const hasPrev = offset > 0;
  const hasNext = offset + page.data.length < page.total;

  return (
    <div className="space-y-2">
      <ul className="space-y-2">
        {page.data.map((entry) => (
          <AdjustmentRow key={entry.id} entry={entry} />
        ))}
      </ul>
      {(hasPrev || hasNext) && (
        <div className="flex items-center justify-between gap-2">
          <Button
            size="sm"
            variant="outline"
            disabled={!hasPrev}
            onClick={() => setOffset(Math.max(0, offset - PAGE_SIZE))}
          >
            Newer
          </Button>
          <span className="text-[11px] text-muted-foreground">
            {offset + 1}–{offset + page.data.length} of {page.total}
          </span>
          <Button
            size="sm"
            variant="outline"
            disabled={!hasNext}
            onClick={() => setOffset(offset + PAGE_SIZE)}
          >
            Older
          </Button>
        </div>
      )}
    </div>
  );
}
