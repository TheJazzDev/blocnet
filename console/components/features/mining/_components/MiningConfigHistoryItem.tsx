"use client";

import { ArrowRight } from "lucide-react";
import type {
  MiningConfigFieldChange,
  MiningConfigHistoryEntry,
} from "@/lib/api/mining-config-history";

function formatWhen(iso: string) {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return iso;
  return date.toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function MiningConfigHistoryItem({ entry }: { entry: MiningConfigHistoryEntry }) {
  return (
    <li className="rounded-lg border p-3 sm:p-4">
      <div className="flex flex-col gap-0.5 sm:flex-row sm:items-baseline sm:justify-between sm:gap-3">
        <p className="truncate text-xs font-medium sm:text-sm">{entry.actor}</p>
        <time dateTime={entry.createdAt} className="shrink-0 text-[11px] text-muted-foreground sm:text-xs">
          {formatWhen(entry.createdAt)}
        </time>
      </div>

      {entry.changes.length === 0 ? (
        <p className="mt-2 text-xs text-muted-foreground">No field details recorded.</p>
      ) : (
        <ul className="mt-2 space-y-1.5">
          {entry.changes.map((change) => (
            <ChangeRow key={change.field} change={change} />
          ))}
        </ul>
      )}

      {!entry.hasDiff && entry.changes.length > 0 && (
        <p className="mt-2 text-[11px] text-muted-foreground">
          Older entry: only the new values were recorded.
        </p>
      )}
    </li>
  );
}

function ChangeRow({ change }: { change: MiningConfigFieldChange }) {
  return (
    <li className="flex flex-col gap-0.5 text-xs sm:flex-row sm:items-center sm:justify-between sm:gap-3 sm:text-sm">
      <span className="text-muted-foreground">{change.label}</span>
      <span className="flex min-w-0 items-center gap-1.5 font-mono">
        {change.before !== null && (
          <>
            <span className="truncate text-muted-foreground line-through">{change.before}</span>
            <ArrowRight className="h-3 w-3 shrink-0 text-muted-foreground" aria-label="changed to" />
          </>
        )}
        <span className="truncate font-semibold">{change.after}</span>
      </span>
    </li>
  );
}
