"use client";

import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import {
  LevelColorSwatch,
  LevelRequirements,
  getLevelColor,
  type LevelBadgeLevel,
} from "@/components/shared/levels";
import type { UserLevel } from "@/lib/api/levels";
import { useLevelsStore, type LevelEditForm as LevelEditFormState } from "@/lib/stores/levels-store";
import { LevelCardHeader } from "./LevelCardHeader";
import { LevelEditForm } from "./LevelEditForm";

export interface LevelCardProps {
  level: UserLevel;
  canMutate: boolean;
  isEditing: boolean;
  isSaving: boolean;
  isUploading: boolean;
  onSave: () => void;
  onUploadIcon: (file: File) => void;
}

/** Badge preview: while editing, reflect the form so uploads/colour edits show immediately. */
function toPreview(level: UserLevel, form: LevelEditFormState | null): LevelBadgeLevel {
  if (!form) return level;
  return {
    level: level.level,
    name: form.name,
    iconUrl: form.iconUrl || level.iconUrl,
    color: form.color || level.color,
  };
}

function LevelReadDetails({ level }: { level: UserLevel }) {
  return (
    <div className="space-y-3 sm:space-y-4">
      <LevelRequirements level={level} />
      <div>
        <Label className="text-xs text-muted-foreground sm:text-sm">Color</Label>
        <div className="mt-1 flex items-center">
          <LevelColorSwatch color={getLevelColor(level)} />
          {!level.color ? (
            <span className="ml-2 text-[11px] text-muted-foreground">(tier default)</span>
          ) : null}
        </div>
      </div>
    </div>
  );
}

export function LevelCard({
  level,
  canMutate,
  isEditing,
  isSaving,
  isUploading,
  onSave,
  onUploadIcon,
}: LevelCardProps) {
  const { editForm, startEdit, cancelEdit } = useLevelsStore();
  const form = isEditing ? editForm : null;

  return (
    <Card className={level.isActive ? undefined : "opacity-75"}>
      <CardHeader>
        <LevelCardHeader
          level={level}
          preview={toPreview(level, form)}
          isEditing={isEditing}
          canMutate={canMutate}
          isSaving={isSaving}
          onEdit={() => startEdit(level)}
          onSave={onSave}
          onCancel={cancelEdit}
        />
      </CardHeader>
      <CardContent>
        {form ? (
          <LevelEditForm level={level} isUploading={isUploading} onUploadIcon={onUploadIcon} />
        ) : (
          <LevelReadDetails level={level} />
        )}
      </CardContent>
    </Card>
  );
}
