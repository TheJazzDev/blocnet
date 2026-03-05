import { Badge } from "@/components/ui/badge";
import type { ProjectStatus } from "@/lib/api-client";

export type StatusFilter = "all" | ProjectStatus;

export function statusBadge(status: ProjectStatus) {
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
    case "paused":
      return (
        <Badge
          variant="outline"
          className="border-yellow-500/20 bg-yellow-500/10 text-yellow-500"
        >
          Paused
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

export function formatDate(value: string) {
  return new Date(value).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}
