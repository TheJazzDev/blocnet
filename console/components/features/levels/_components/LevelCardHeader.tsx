"use client";

import { Edit, Save, X } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { CardDescription, CardTitle } from "@/components/ui/card";
import { LevelBadge, LevelTierChip, type LevelBadgeLevel } from "@/components/shared/levels";
import type { UserLevel } from "@/lib/api/levels";

export interface LevelCardHeaderProps {
  level: UserLevel;
  /** Badge/name preview (reflects the edit form while editing). */
  preview: LevelBadgeLevel;
  isEditing: boolean;
  canMutate: boolean;
  isSaving: boolean;
  onEdit: () => void;
  onSave: () => void;
  onCancel: () => void;
}

const ICON_CLASS = "h-3 w-3 sm:h-4 sm:w-4";
const BUTTON_CLASS = "h-7 px-2 sm:h-8 sm:px-3";

function LevelCardActions({
  isEditing,
  isSaving,
  onEdit,
  onSave,
  onCancel,
}: Pick<LevelCardHeaderProps, "isEditing" | "isSaving" | "onEdit" | "onSave" | "onCancel">) {
  if (!isEditing) {
    return (
      <Button size="sm" variant="outline" onClick={onEdit} className={BUTTON_CLASS} aria-label="Edit level">
        <Edit className={ICON_CLASS} />
      </Button>
    );
  }
  return (
    <>
      <Button size="sm" onClick={onSave} disabled={isSaving} className={BUTTON_CLASS} aria-label="Save level">
        <Save className={ICON_CLASS} />
      </Button>
      <Button
        size="sm"
        variant="outline"
        onClick={onCancel}
        disabled={isSaving}
        className={BUTTON_CLASS}
        aria-label="Cancel editing"
      >
        <X className={ICON_CLASS} />
      </Button>
    </>
  );
}

export function LevelCardHeader({
  level,
  preview,
  isEditing,
  canMutate,
  isSaving,
  onEdit,
  onSave,
  onCancel,
}: LevelCardHeaderProps) {
  return (
    <div className="flex items-start justify-between gap-3">
      <div className="flex min-w-0 flex-1 items-start gap-3 sm:gap-4">
        <LevelBadge level={preview} size="md" />
        <div className="min-w-0 flex-1 space-y-1">
          <CardTitle className="text-base sm:text-lg">
            Level {level.level} &bull; {preview.name}
          </CardTitle>
          <div className="flex flex-wrap items-center gap-1.5">
            <LevelTierChip level={level} />
            {!level.isActive ? <Badge variant="outline">Inactive</Badge> : null}
            <span className="text-[11px] text-muted-foreground sm:text-xs">
              Sort {level.sortOrder} &middot; {level.slug}
            </span>
          </div>
          {!isEditing ? (
            <CardDescription className="text-xs sm:text-sm">{level.description}</CardDescription>
          ) : null}
        </div>
      </div>
      {canMutate ? (
        <div className="flex shrink-0 gap-1 pt-1 sm:gap-2">
          <LevelCardActions
            isEditing={isEditing}
            isSaving={isSaving}
            onEdit={onEdit}
            onSave={onSave}
            onCancel={onCancel}
          />
        </div>
      ) : null}
    </div>
  );
}
