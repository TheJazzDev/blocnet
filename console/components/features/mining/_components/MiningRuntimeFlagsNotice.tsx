"use client";

import Link from "next/link";
import { ExternalLink } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import type { AdminMiningRuntimeFlags } from "@/lib/api-client";

type MiningRuntimeFlagsNoticeProps = {
  runtimeFlags: AdminMiningRuntimeFlags | undefined;
};

function FlagBadge({ label, on }: { label: string; on: boolean }) {
  return (
    <Badge variant="outline" className={on ? "text-emerald-300" : "text-rose-300"}>
      {label}: {on ? "On" : "Off"}
    </Badge>
  );
}

/** Read-only view of the Settings runtime flags that gate mining. */
export function MiningRuntimeFlagsNotice({ runtimeFlags }: MiningRuntimeFlagsNoticeProps) {
  return (
    <div className="flex flex-col gap-2 rounded-lg border border-dashed p-3 text-xs sm:flex-row sm:items-center sm:justify-between sm:p-4 sm:text-sm">
      <div className="space-y-1.5">
        <p className="font-medium">Runtime flags (read-only)</p>
        {runtimeFlags ? (
          <div className="flex flex-wrap gap-1.5">
            <FlagBadge label="Mining" on={runtimeFlags.miningEnabled} />
            <FlagBadge label="Referrals" on={runtimeFlags.referralsEnabled} />
          </div>
        ) : (
          <p className="text-muted-foreground">
            This API version does not report runtime flags; live state shows the stored value.
          </p>
        )}
      </div>
      <Link
        href="/settings"
        className="inline-flex min-h-[44px] items-center gap-1.5 text-primary underline-offset-2 hover:underline sm:min-h-0"
      >
        Change in Settings
        <ExternalLink className="h-3.5 w-3.5" />
      </Link>
    </div>
  );
}
