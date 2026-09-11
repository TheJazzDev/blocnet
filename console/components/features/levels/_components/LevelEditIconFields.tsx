"use client";

import type { ChangeEvent } from "react";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { LevelBadge } from "@/components/shared/levels";
import type { UserLevel } from "@/lib/api/levels";
import { useLevelsStore } from "@/lib/stores";

export interface LevelEditIconFieldsProps {
  level: UserLevel;
  isUploading: boolean;
  onUploadIcon: (file: File) => void;
}

const labelClass = "text-xs text-muted-foreground sm:text-sm";

/** Icon URL text field plus file upload with a live badge preview. */
export function LevelEditIconFields({ level, isUploading, onUploadIcon }: LevelEditIconFieldsProps) {
  const { editForm, patchEditForm } = useLevelsStore();
  if (!editForm) return null;

  const handleFile = (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (file) onUploadIcon(file);
  };

  return (
    <>
      <div className="md:col-span-2 lg:col-span-3">
        <Label htmlFor={`level-icon-url-${level.id}`} className={labelClass}>
          Level Icon URL/Path
        </Label>
        <Input
          id={`level-icon-url-${level.id}`}
          type="text"
          value={editForm.iconUrl}
          onChange={(e) => patchEditForm({ iconUrl: e.target.value })}
          placeholder="/images/levels/level-3.svg or https://..."
          className="mt-1"
        />
        <p className="mt-1 text-[11px] text-muted-foreground">Recommended: SVG for crisp rendering.</p>
      </div>

      <div className="md:col-span-2 lg:col-span-3">
        <Label htmlFor={`level-icon-file-${level.id}`} className={labelClass}>
          Upload Badge Icon
        </Label>
        <div className="mt-1 flex flex-col gap-3 sm:flex-row sm:items-center">
          <LevelBadge
            level={{
              level: level.level,
              name: editForm.name,
              iconUrl: editForm.iconUrl,
              color: editForm.color,
            }}
            size="lg"
          />
          <div className="min-w-0 flex-1">
            <Input
              id={`level-icon-file-${level.id}`}
              type="file"
              accept="image/svg+xml,image/png,image/jpeg,image/webp"
              onChange={handleFile}
              disabled={isUploading}
              className="max-w-md"
            />
            {isUploading ? (
              <p className="mt-1 text-[11px] text-muted-foreground">Uploading icon...</p>
            ) : null}
          </div>
        </div>
      </div>
    </>
  );
}
