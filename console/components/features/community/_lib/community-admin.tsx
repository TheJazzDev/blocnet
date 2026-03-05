import { Badge } from "@/components/ui/badge";
import type { CommunityTopic, ContentStatus } from "@/lib/api-client";

export type StatusFilter = "all" | ContentStatus;
export type TopicFilter = "all" | CommunityTopic;

export const MODERATION_STATUS_OPTIONS = [
  { value: "active", label: "Active" },
  { value: "hidden", label: "Hidden" },
  { value: "archived", label: "Archived" },
];

export function statusBadge(status: ContentStatus) {
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

export function topicBadge(topic: CommunityTopic) {
  const label =
    topic === "market_talk"
      ? "Market Talk"
      : topic === "introductions"
        ? "Introductions"
        : "General";
  return <Badge variant="secondary">{label}</Badge>;
}

export function formatDate(value: string) {
  return new Date(value).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}
