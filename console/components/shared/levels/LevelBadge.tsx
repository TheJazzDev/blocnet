"use client";

import { useState } from "react";
import { cn } from "@/lib/utils";
import { getLevelColor, tintColor } from "./levelTier";

export type LevelBadgeSize = "sm" | "md" | "lg";

export interface LevelBadgeLevel {
  level: number;
  name?: string;
  iconUrl?: string | null;
  color?: string | null;
}

export interface LevelBadgeProps {
  /** Level to render. `null`/`undefined` renders the "no level" placeholder. */
  level: LevelBadgeLevel | null | undefined;
  size?: LevelBadgeSize;
  /** `true` renders "Level N · Name"; a string renders that text. */
  label?: boolean | string;
  className?: string;
}

const BOX_SIZE: Record<LevelBadgeSize, string> = {
  sm: "h-7 w-7 sm:h-8 sm:w-8",
  md: "h-10 w-10 sm:h-12 sm:w-12",
  lg: "h-16 w-16 sm:h-20 sm:w-20",
};

const FALLBACK_TEXT: Record<LevelBadgeSize, string> = {
  sm: "text-[11px]",
  md: "text-sm sm:text-base",
  lg: "text-lg sm:text-xl",
};

const LABEL_TEXT: Record<LevelBadgeSize, string> = {
  sm: "text-xs",
  md: "text-xs sm:text-sm",
  lg: "text-sm sm:text-base",
};

/** Image source to use, or `null` when the icon is empty or previously failed. */
export function resolveBadgeImage(
  iconUrl: string | null | undefined,
  failedSrc: string | null,
): string | null {
  const src = iconUrl?.trim() ?? "";
  if (!src || src === failedSrc) return null;
  return src;
}

export function formatLevelLabel(level: LevelBadgeLevel | null | undefined): string {
  if (!level) return "No level";
  return level.name ? `Level ${level.level} · ${level.name}` : `Level ${level.level}`;
}

export function LevelBadge({ level, size = "md", label, className }: LevelBadgeProps) {
  const [failedSrc, setFailedSrc] = useState<string | null>(null);
  const src = level ? resolveBadgeImage(level.iconUrl, failedSrc) : null;
  const labelText = typeof label === "string" ? label : label ? formatLevelLabel(level) : null;
  const title = formatLevelLabel(level);

  let visual: React.ReactNode;
  if (!level) {
    visual = (
      <span
        className="flex h-full w-full items-center justify-center rounded-full border border-dashed border-border/70 text-muted-foreground"
        aria-label="No level"
      >
        &mdash;
      </span>
    );
  } else if (src) {
    visual = (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={src}
        alt={title}
        className="h-full w-full object-contain"
        draggable={false}
        onError={() => setFailedSrc(src)}
      />
    );
  } else {
    const color = getLevelColor(level);
    visual = (
      <span
        className={cn(
          "flex h-full w-full items-center justify-center rounded-full border font-semibold tabular-nums",
          FALLBACK_TEXT[size],
        )}
        style={{ backgroundColor: tintColor(color, 18), borderColor: color, color }}
        aria-label={title}
        data-level-fallback=""
      >
        {level.level}
      </span>
    );
  }

  return (
    <span className={cn("inline-flex items-center gap-2", className)} title={title}>
      <span
        className={cn("relative flex shrink-0 items-center justify-center", BOX_SIZE[size])}
        data-level-badge-size={size}
      >
        {visual}
      </span>
      {labelText ? (
        <span className={cn("truncate font-medium", LABEL_TEXT[size])}>{labelText}</span>
      ) : null}
    </span>
  );
}
