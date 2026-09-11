"use client";

import { LevelBadge, LevelTierChip } from "@/components/shared/levels";
import type { UserLevel } from "@/lib/api-client";

export function UserLevelCell({ level }: { level: UserLevel | null }) {
  if (!level) {
    return (
      <div className="flex items-center gap-2">
        <LevelBadge level={null} size="sm" />
        <span className="text-xs text-muted-foreground">No level</span>
      </div>
    );
  }

  return (
    <div className="flex items-center gap-2">
      <LevelBadge level={level} size="sm" />
      <div className="flex min-w-0 flex-col gap-0.5">
        <span className="truncate text-sm font-medium">
          Lv {level.level} &middot; {level.name}
        </span>
        <LevelTierChip level={level} className="w-fit" />
      </div>
    </div>
  );
}
