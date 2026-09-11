import { cn } from "@/lib/utils";

export interface LevelColorSwatchProps {
  color: string;
  /** Show the hex next to the swatch. */
  showHex?: boolean;
  className?: string;
}

/** Colour swatch with optional hex label, used in read mode and tier headers. */
export function LevelColorSwatch({ color, showHex = true, className }: LevelColorSwatchProps) {
  return (
    <span className={cn("inline-flex items-center gap-2", className)}>
      <span
        className="h-4 w-4 shrink-0 rounded-md border border-border/70 shadow-sm"
        style={{ backgroundColor: color }}
        aria-hidden
      />
      {showHex ? (
        <span className="font-mono text-xs uppercase text-muted-foreground">{color}</span>
      ) : null}
    </span>
  );
}
