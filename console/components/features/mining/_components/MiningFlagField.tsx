"use client";

import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Label } from "@/components/ui/label";
import type { EffectiveMiningFlag } from "@/lib/api/mining-config";
import { cn } from "@/lib/utils";

type MiningFlagFieldProps = {
  id: string;
  label: string;
  flag: EffectiveMiningFlag | null;
  changed: boolean;
  disabled: boolean;
  onChange: (value: boolean) => void;
};

/**
 * Stored on/off value, plus what members actually get once the Settings
 * runtime flag is applied (effective = stored AND runtime).
 */
export function MiningFlagField({
  id,
  label,
  flag,
  changed,
  disabled,
  onChange,
}: MiningFlagFieldProps) {
  return (
    <div className="space-y-1.5 sm:space-y-2">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <Label htmlFor={id} className="text-xs sm:text-sm">
          {label} <span className="text-muted-foreground">(stored)</span>
        </Label>
        {flag && (
          <Badge
            variant="outline"
            className={cn(
              "text-[10px] sm:text-xs",
              flag.effective ? "text-emerald-300" : "text-rose-300",
            )}
          >
            Live: {flag.effective ? "On" : "Off"}
          </Badge>
        )}
      </div>
      <select
        id={id}
        className={cn(
          "h-9 w-full rounded-md border bg-background px-3 text-sm sm:h-10",
          changed && "border-primary/60",
        )}
        value={flag?.stored ? "true" : "false"}
        onChange={(e) => onChange(e.target.value === "true")}
        disabled={disabled}
      >
        <option value="true">Enabled</option>
        <option value="false">Disabled</option>
      </select>
      {flag?.overriddenByRuntime && (
        <p className="text-xs text-amber-300">
          Stored as enabled, but the runtime flag in{" "}
          <Link href="/settings" className="underline underline-offset-2">
            Settings
          </Link>{" "}
          switches it off, so it is off for members.
        </p>
      )}
    </div>
  );
}
