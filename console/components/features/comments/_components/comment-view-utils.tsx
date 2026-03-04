"use client";

import { Badge } from "@/components/ui/badge";
import type { ContentStatus } from "@/lib/api-client";

export function commentStatusBadge(status: ContentStatus) {
  switch (status) {
    case "active":
      return (
        <Badge
          variant="outline"
          className="border-emerald-500/20 bg-emerald-500/10 text-emerald-500"
        >
          Active
        </Badge>
      );
    case "hidden":
      return (
        <Badge
          variant="outline"
          className="border-amber-500/20 bg-amber-500/10 text-amber-400"
        >
          Hidden
        </Badge>
      );
    case "archived":
      return (
        <Badge
          variant="outline"
          className="border-red-500/20 bg-red-500/10 text-red-400"
        >
          Archived
        </Badge>
      );
  }
}

export function formatCommentDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}
