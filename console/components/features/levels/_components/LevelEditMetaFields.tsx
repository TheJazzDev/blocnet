"use client";

import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { getLevelColor, isHexColor } from "@/components/shared/levels";
import type { UserLevel } from "@/lib/api/levels";
import { useLevelsStore } from "@/lib/stores";

export interface LevelEditMetaFieldsProps {
  level: UserLevel;
}

const labelClass = "text-xs text-muted-foreground sm:text-sm";

/** Colour (swatch + hex), active switch and sort order controls. */
export function LevelEditMetaFields({ level }: LevelEditMetaFieldsProps) {
  const { editForm, patchEditForm } = useLevelsStore();
  if (!editForm) return null;

  // <input type="color"> only accepts #rrggbb; fall back to the tier colour otherwise.
  const trimmedColor = editForm.color.trim();
  const pickerValue =
    isHexColor(trimmedColor) && trimmedColor.length === 7
      ? trimmedColor
      : getLevelColor({ level: level.level, color: null });

  return (
    <>
      <div>
        <Label htmlFor={`level-color-${level.id}`} className={labelClass}>
          Color (Hex)
        </Label>
        <div className="mt-1 flex items-center gap-2">
          <input
            type="color"
            aria-label="Pick level colour"
            value={pickerValue}
            onChange={(e) => patchEditForm({ color: e.target.value.toUpperCase() })}
            className="h-9 w-10 shrink-0 cursor-pointer rounded-md border border-input bg-transparent p-0.5"
          />
          <Input
            id={`level-color-${level.id}`}
            type="text"
            value={editForm.color}
            onChange={(e) => patchEditForm({ color: e.target.value })}
            placeholder="#8A96A8"
            className="font-mono uppercase"
            aria-invalid={trimmedColor !== "" && !isHexColor(trimmedColor)}
          />
        </div>
        <p className="mt-1 text-[11px] text-muted-foreground">Leave empty to use the tier colour.</p>
      </div>

      <div>
        <Label htmlFor={`level-sort-${level.id}`} className={labelClass}>
          Sort Order
        </Label>
        <Input
          id={`level-sort-${level.id}`}
          type="number"
          inputMode="numeric"
          value={editForm.sortOrder}
          onChange={(e) => patchEditForm({ sortOrder: Number.parseInt(e.target.value, 10) || 0 })}
          className="mt-1"
        />
      </div>

      <div>
        <Label htmlFor={`level-active-${level.id}`} className={labelClass}>
          Active
        </Label>
        <div className="mt-2 flex items-center gap-2">
          <Switch
            id={`level-active-${level.id}`}
            checked={editForm.isActive}
            onCheckedChange={(checked) => patchEditForm({ isActive: checked })}
          />
          <span className="text-xs sm:text-sm">{editForm.isActive ? "Active" : "Inactive"}</span>
        </div>
      </div>
    </>
  );
}
