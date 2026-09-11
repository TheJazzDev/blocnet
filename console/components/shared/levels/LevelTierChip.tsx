import { cn } from "@/lib/utils";
import { getLevelColor, getLevelTier, tintColor } from "./levelTier";

export interface LevelTierChipProps {
  level: { level: number; color?: string | null } | null | undefined;
  className?: string;
}

/** Small tinted chip showing a level's tier name (Iron, Jade, ...). */
export function LevelTierChip({ level, className }: LevelTierChipProps) {
  if (!level) {
    return (
      <span className={cn("text-xs text-muted-foreground", className)}>
        &mdash;
      </span>
    );
  }

  const tier = getLevelTier(level.level);
  const color = getLevelColor(level);

  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 rounded-full border px-2 py-0.5 text-[11px] font-semibold leading-4",
        className,
      )}
      style={{
        color,
        borderColor: tintColor(color, 35),
        backgroundColor: tintColor(color, 12),
      }}
    >
      <span
        className="h-1.5 w-1.5 shrink-0 rounded-full"
        style={{ backgroundColor: color }}
        aria-hidden
      />
      {tier.name}
    </span>
  );
}
