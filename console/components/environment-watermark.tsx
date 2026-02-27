"use client";

import { useEffect, useMemo, useState } from "react";
import { cn } from "@/lib/utils";

interface EnvironmentWatermarkProps {
  text: string;
  className?: string;
  textClassName?: string;
}

interface ViewportSize {
  width: number;
  height: number;
}

function getViewportSize(): ViewportSize {
  if (typeof window === "undefined") {
    return { width: 1440, height: 900 };
  }

  return {
    width: Math.max(window.innerWidth, 320),
    height: Math.max(window.innerHeight, 320),
  };
}

function getWatermarkFontSize(text: string, diagonal: number): number {
  const characterCount = Math.max(text.replace(/\s+/g, "").length, 1);
  const approximateEmWidth = characterCount * 0.74;
  const targetWidth = diagonal * 0.86;
  const resolvedSize = targetWidth / approximateEmWidth;
  return Math.max(44, Math.min(resolvedSize, 320));
}

export function EnvironmentWatermark({
  text,
  className,
  textClassName,
}: EnvironmentWatermarkProps) {
  const [viewport, setViewport] = useState<ViewportSize>(() => getViewportSize());

  useEffect(() => {
    const handleResize = () => {
      setViewport(getViewportSize());
    };

    handleResize();
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  const diagonal = useMemo(
    () => Math.hypot(viewport.width, viewport.height),
    [viewport.height, viewport.width],
  );
  const angle = useMemo(
    () => (Math.atan2(viewport.height, viewport.width) * 180) / Math.PI,
    [viewport.height, viewport.width],
  );
  const fontSize = useMemo(() => getWatermarkFontSize(text, diagonal), [diagonal, text]);

  return (
    <div
      aria-hidden="true"
      className={cn("pointer-events-none fixed inset-0 z-0 overflow-hidden", className)}
    >
      <div
        className="absolute bottom-0 left-0 origin-bottom-left"
        style={{
          width: `${diagonal}px`,
          transform: `rotate(${-angle}deg)`,
        }}
      >
        <p
          className={cn(
            "w-full select-none text-center font-black uppercase leading-none tracking-[0.12em] text-primary/18",
            textClassName,
          )}
          style={{ fontSize: `${fontSize}px` }}
        >
          {text}
        </p>
      </div>
    </div>
  );
}
