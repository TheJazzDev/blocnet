import { Badge } from "@/components/ui/badge";
import type { AdminUpdate, UpdateStatus } from "@/lib/api-client";

export type StatusFilter = "all" | UpdateStatus;

export const UPDATE_STATUS_OPTIONS = [
  { value: "published", label: "Published" },
  { value: "hidden", label: "Hidden" },
  { value: "archived", label: "Archived" },
];

export function statusBadge(status: UpdateStatus) {
  switch (status) {
    case "published":
      return (
        <Badge
          variant="outline"
          className="border-emerald-500/20 bg-emerald-500/10 text-emerald-500"
        >
          Published
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

export function urgencyBadge(urgency: AdminUpdate["urgency"]) {
  switch (urgency) {
    case "high":
      return <Badge className="bg-red-500/15 text-red-300">High</Badge>;
    case "medium":
      return <Badge className="bg-amber-500/15 text-amber-300">Medium</Badge>;
    case "low":
      return <Badge className="bg-slate-500/15 text-slate-300">Low</Badge>;
  }
}

export function formatDate(value: string) {
  return new Date(value).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}
