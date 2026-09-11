"use client";

import { TrendingUp } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import {
  LevelBadge,
  LevelColorSwatch,
  LevelRequirements,
  LevelTierChip,
  formatTierRange,
  getLevelColor,
  getLevelTier,
} from "@/components/shared/levels";
import type { UserLevel } from "@/lib/api-client";

type LevelSectionProps = {
  level: UserLevel | null;
};

export function LevelSection({ level }: LevelSectionProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-sm sm:text-base">
          <TrendingUp className="h-4 w-4 sm:h-5 sm:w-5" />
          Level & Progression
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {level ? <LevelDetails level={level} /> : <NoLevel />}
      </CardContent>
    </Card>
  );
}

function NoLevel() {
  return (
    <div className="flex items-center gap-3 rounded-md border border-dashed p-3 sm:p-4">
      <LevelBadge level={null} size="md" />
      <div>
        <p className="text-xs font-medium sm:text-sm">No level</p>
        <p className="text-xs text-muted-foreground">
          This user has not been assigned a level yet.
        </p>
      </div>
    </div>
  );
}

function LevelDetails({ level }: { level: UserLevel }) {
  const tier = getLevelTier(level.level);
  const color = getLevelColor(level);

  return (
    <>
      <div className="flex flex-col gap-3 rounded-md border p-3 sm:flex-row sm:items-center sm:gap-4 sm:p-4">
        <LevelBadge level={level} size="lg" />
        <div className="min-w-0 flex-1 space-y-1">
          <p className="text-sm font-semibold sm:text-base">
            Level {level.level} &middot; {level.name}
          </p>
          <div className="flex flex-wrap items-center gap-1.5">
            <LevelTierChip level={level} />
            <span className="text-[11px] text-muted-foreground sm:text-xs">
              {formatTierRange(tier)}
            </span>
            {!level.isActive ? <Badge variant="outline">Inactive</Badge> : null}
          </div>
          {level.description ? (
            <p className="text-xs text-muted-foreground sm:text-sm">{level.description}</p>
          ) : null}
        </div>
      </div>

      <div className="grid gap-3 sm:grid-cols-3 sm:gap-4">
        <div>
          <Label className="text-xs text-muted-foreground">Tier</Label>
          <p className="mt-1 text-xs font-medium sm:text-sm" style={{ color }}>
            {tier.name}
          </p>
        </div>
        <div>
          <Label className="text-xs text-muted-foreground">Color</Label>
          <div className="mt-1">
            <LevelColorSwatch color={color} />
          </div>
        </div>
        <div>
          <Label className="text-xs text-muted-foreground">Slug</Label>
          <p className="mt-1 break-all font-mono text-xs sm:text-sm">{level.slug}</p>
        </div>
      </div>

      <div className="border-t pt-4">
        <h4 className="mb-2 text-xs font-semibold sm:text-sm">Requirement thresholds</h4>
        <LevelRequirements level={level} />
      </div>
    </>
  );
}
