"use client";

import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { LEVEL_REQUIREMENT_FIELDS } from "@/components/shared/levels";
import type { UserLevel } from "@/lib/api/levels";
import { useLevelsStore } from "@/lib/stores";
import { LevelEditIconFields } from "./LevelEditIconFields";
import { LevelEditMetaFields } from "./LevelEditMetaFields";

export interface LevelEditFormProps {
  level: UserLevel;
  isUploading: boolean;
  onUploadIcon: (file: File) => void;
}

const labelClass = "text-xs text-muted-foreground sm:text-sm";

function toInt(value: string) {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) ? parsed : 0;
}

export function LevelEditForm({ level, isUploading, onUploadIcon }: LevelEditFormProps) {
  const { editForm, patchEditForm } = useLevelsStore();
  if (!editForm) return null;

  return (
    <div className="grid gap-3 sm:gap-4 md:grid-cols-2 lg:grid-cols-3">
      <div className="md:col-span-2 lg:col-span-3">
        <Label htmlFor={`level-name-${level.id}`} className={labelClass}>
          Name
        </Label>
        <Input
          id={`level-name-${level.id}`}
          value={editForm.name}
          onChange={(e) => patchEditForm({ name: e.target.value })}
          className="mt-1 text-sm font-semibold sm:text-base"
        />
      </div>

      <div className="md:col-span-2 lg:col-span-3">
        <Label htmlFor={`level-description-${level.id}`} className={labelClass}>
          Description
        </Label>
        <Textarea
          id={`level-description-${level.id}`}
          value={editForm.description}
          onChange={(e) => patchEditForm({ description: e.target.value })}
          rows={3}
          className="mt-1 min-h-[88px] w-full resize-y text-xs sm:text-sm"
        />
      </div>

      {LEVEL_REQUIREMENT_FIELDS.map((field) => {
        const isBnp = field.key === "requiredBnp";
        const inputId = `level-${field.key}-${level.id}`;
        return (
          <div key={field.key}>
            <Label htmlFor={inputId} className={labelClass}>
              {field.label}
            </Label>
            <Input
              id={inputId}
              type={isBnp ? "text" : "number"}
              inputMode="numeric"
              min={isBnp ? undefined : 0}
              value={editForm[field.key]}
              onChange={(e) =>
                patchEditForm(
                  isBnp
                    ? { requiredBnp: e.target.value }
                    : { [field.key]: toInt(e.target.value) },
                )
              }
              className="mt-1"
            />
          </div>
        );
      })}

      <LevelEditMetaFields level={level} />
      <LevelEditIconFields level={level} isUploading={isUploading} onUploadIcon={onUploadIcon} />
    </div>
  );
}
