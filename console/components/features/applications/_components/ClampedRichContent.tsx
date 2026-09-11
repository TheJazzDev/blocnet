"use client";

import { useEffect, useRef, useState } from "react";
import { ChevronDown, ChevronUp } from "lucide-react";
import { Button } from "@/components/ui/button";
import { RichContentRenderer } from "@/components/rich-content-renderer";
import { cn } from "@/lib/utils";

/** About four lines of prose-sm. */
const DEFAULT_COLLAPSED_PX = 96;

type ClampedRichContentProps = {
  content: string;
  className?: string;
  collapsedHeightPx?: number;
};

/**
 * Sanitized rich content clamped to a few lines with a "Show more" toggle,
 * so a proposal with a huge embedded diagram cannot take over the review
 * list (F-18). The toggle only renders when the content really overflows.
 */
export function ClampedRichContent({
  content,
  className,
  collapsedHeightPx = DEFAULT_COLLAPSED_PX,
}: ClampedRichContentProps) {
  const [expanded, setExpanded] = useState(false);
  const [overflows, setOverflows] = useState(false);
  const innerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const inner = innerRef.current;
    if (!inner) return;
    const measure = () => setOverflows(inner.offsetHeight > collapsedHeightPx + 1);
    measure();
    // Images and diagrams inside the sanitized HTML load after mount.
    const observer = new ResizeObserver(measure);
    observer.observe(inner);
    return () => observer.disconnect();
  }, [content, collapsedHeightPx]);

  return (
    <div className={className}>
      <div
        className={cn("relative", !expanded && "overflow-hidden")}
        style={expanded ? undefined : { maxHeight: collapsedHeightPx }}
      >
        <div ref={innerRef}>
          <RichContentRenderer content={content} />
        </div>
        {!expanded && overflows && (
          <div
            aria-hidden
            className="pointer-events-none absolute inset-x-0 bottom-0 h-10 bg-linear-to-t from-card to-transparent"
          />
        )}
      </div>
      {overflows && (
        <Button
          type="button"
          variant="ghost"
          size="sm"
          className="mt-1 h-7 px-2 text-xs text-primary"
          aria-expanded={expanded}
          onClick={() => setExpanded((prev) => !prev)}
        >
          {expanded ? <ChevronUp className="h-3.5 w-3.5" /> : <ChevronDown className="h-3.5 w-3.5" />}
          {expanded ? "Show less" : "Show more"}
        </Button>
      )}
    </div>
  );
}
