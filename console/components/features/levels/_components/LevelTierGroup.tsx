"use client";

import {
  LevelColorSwatch,
  formatTierRange,
  type LevelTier,
} from "@/components/shared/levels";
import type { UserLevel } from "@/lib/api/levels";
import { LevelCard } from "./LevelCard";

export interface LevelTierGroupProps {
  tier: LevelTier;
  levels: UserLevel[];
  canMutate: boolean;
  editingId: string | null;
  isSaving: boolean;
  uploadingLevelId: string | null;
  onSave: (levelId: string) => void;
  onUploadIcon: (levelId: string, file: File) => void;
}

export function LevelTierGroup({
  tier,
  levels,
  canMutate,
  editingId,
  isSaving,
  uploadingLevelId,
  onSave,
  onUploadIcon,
}: LevelTierGroupProps) {
  return (
    <section className="space-y-3 md:space-y-4" aria-labelledby={`tier-${tier.name}`}>
      <header className="flex flex-wrap items-center gap-2 sm:gap-3">
        <span
          className="h-3 w-3 shrink-0 rounded-full sm:h-3.5 sm:w-3.5"
          style={{ backgroundColor: tier.color }}
          aria-hidden
        />
        <h2
          id={`tier-${tier.name}`}
          className="text-base font-semibold sm:text-lg"
          style={{ color: tier.color }}
        >
          {tier.name}
        </h2>
        <span className="text-xs text-muted-foreground sm:text-sm">{formatTierRange(tier)}</span>
        <span className="text-xs text-muted-foreground sm:text-sm">
          &middot; {levels.length} level{levels.length === 1 ? "" : "s"}
        </span>
        <LevelColorSwatch color={tier.color} className="ml-auto" />
      </header>

      <div className="grid gap-4 md:gap-6">
        {levels.map((level) => (
          <LevelCard
            key={level.id}
            level={level}
            canMutate={canMutate}
            isEditing={editingId === level.id}
            isSaving={isSaving}
            isUploading={uploadingLevelId === level.id}
            onSave={() => onSave(level.id)}
            onUploadIcon={(file) => onUploadIcon(level.id, file)}
          />
        ))}
      </div>
    </section>
  );
}
