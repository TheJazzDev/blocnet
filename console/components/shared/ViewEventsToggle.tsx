"use client";

import { useId } from "react";
import { cn } from "@/lib/utils";

type ViewEventsToggleProps = {
  checked: boolean;
  onCheckedChange: (checked: boolean) => void;
  /** How many `*.view` events are currently hidden on this page/feed. */
  hiddenCount?: number;
  className?: string;
};

/** "Show view events" checkbox shared by the dashboard feed and audit log. */
export function ViewEventsToggle({
  checked,
  onCheckedChange,
  hiddenCount = 0,
  className,
}: ViewEventsToggleProps) {
  const id = useId();
  return (
    <label
      htmlFor={id}
      className={cn(
        "inline-flex cursor-pointer select-none items-center gap-2 text-xs text-muted-foreground",
        className,
      )}
    >
      <input
        id={id}
        type="checkbox"
        className="h-3.5 w-3.5 cursor-pointer accent-primary"
        checked={checked}
        onChange={(event) => onCheckedChange(event.target.checked)}
      />
      <span>
        Show view events
        {!checked && hiddenCount > 0 && (
          <span className="text-muted-foreground/70"> ({hiddenCount} hidden)</span>
        )}
      </span>
    </label>
  );
}
