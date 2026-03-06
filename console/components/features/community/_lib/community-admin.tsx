import { Badge } from "@/components/ui/badge";
import type {
  CommunityReportStatus,
  CommunityReportTargetType,
  CommunityTopic,
  ContentStatus,
} from "@/lib/api-client";

export type StatusFilter = "all" | ContentStatus;
export type TopicFilter = "all" | CommunityTopic;
export type ReportStatusFilter = "all" | CommunityReportStatus;
export type ReportTargetTypeFilter = "all" | CommunityReportTargetType;

export const MODERATION_STATUS_OPTIONS = [
  { value: "active", label: "Active" },
  { value: "hidden", label: "Hidden" },
  { value: "archived", label: "Archived" },
];

export const FRONTLINE_MODERATION_STATUS_OPTIONS = [
  { value: "active", label: "Active" },
  { value: "hidden", label: "Hidden" },
];

export const REPORT_REVIEW_STATUS_OPTIONS = [
  { value: "resolved", label: "Resolve" },
  { value: "dismissed", label: "Dismiss" },
];

export function canArchiveCommunityContent(roles: string[]) {
  return (
    roles.includes("owner") ||
    roles.includes("dev") ||
    roles.includes("admin") ||
    roles.includes("community_admin")
  );
}

export function canApplyEscalatedCommunitySanctions(roles: string[]) {
  return (
    roles.includes("owner") ||
    roles.includes("dev") ||
    roles.includes("admin") ||
    roles.includes("community_admin")
  );
}

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

export function reportStatusBadge(status: CommunityReportStatus) {
  switch (status) {
    case "open":
      return (
        <Badge
          variant="outline"
          className="border-blue-500/20 bg-blue-500/10 text-blue-400"
        >
          Open
        </Badge>
      );
    case "resolved":
      return (
        <Badge
          variant="outline"
          className="border-emerald-500/20 bg-emerald-500/10 text-emerald-400"
        >
          Resolved
        </Badge>
      );
    case "dismissed":
      return (
        <Badge
          variant="outline"
          className="border-zinc-500/20 bg-zinc-500/10 text-zinc-300"
        >
          Dismissed
        </Badge>
      );
  }
}

export function reportTargetTypeBadge(targetType: CommunityReportTargetType) {
  switch (targetType) {
    case "community_post":
      return <Badge variant="secondary">Post</Badge>;
    case "community_comment":
      return <Badge variant="secondary">Comment</Badge>;
    case "user_profile":
      return <Badge variant="secondary">Profile</Badge>;
  }
}

export function formatDate(value: string) {
  return new Date(value).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}
