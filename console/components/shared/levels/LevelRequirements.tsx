import { Label } from "@/components/ui/label";
import type { UserLevel } from "@/lib/api/server-types-levels";
import { cn } from "@/lib/utils";
import { LEVEL_REQUIREMENT_FIELDS } from "./levelRequirementFields";

export interface LevelRequirementsProps {
  level: UserLevel;
  className?: string;
}

/** Read-only grid of a level's requirement thresholds. */
export function LevelRequirements({ level, className }: LevelRequirementsProps) {
  return (
    <div className={cn("grid grid-cols-2 gap-3 sm:gap-4 md:grid-cols-3", className)}>
      {LEVEL_REQUIREMENT_FIELDS.map((field) => (
        <div key={field.key}>
          <Label className="text-xs text-muted-foreground sm:text-sm">{field.label}</Label>
          <p className="text-sm font-semibold sm:text-base md:text-lg">{field.format(level)}</p>
        </div>
      ))}
    </div>
  );
}
