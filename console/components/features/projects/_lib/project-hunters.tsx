import { Badge } from "@/components/ui/badge";
import type { ProjectHunterInvite, ProjectInviteStatus } from "@/lib/api-client";

export type GroupedInvites = {
  /** Accepted invites: the closest thing the API exposes to "current hunters". */
  accepted: ProjectHunterInvite[];
  pending: ProjectHunterInvite[];
  /** Rejected or cancelled; kept so a re-invite is understandable. */
  closed: ProjectHunterInvite[];
};

export function groupInvites(invites: ProjectHunterInvite[]): GroupedInvites {
  const grouped: GroupedInvites = { accepted: [], pending: [], closed: [] };
  for (const invite of invites) {
    if (invite.status === "accepted") grouped.accepted.push(invite);
    else if (invite.status === "pending") grouped.pending.push(invite);
    else grouped.closed.push(invite);
  }
  return grouped;
}

/** Status of a hunter relative to this project, derived from the invite list. */
export type HunterProjectState = "hunter" | "invited" | "none";

export function hunterProjectState(
  hunterId: string,
  grouped: GroupedInvites,
): HunterProjectState {
  if (grouped.accepted.some((invite) => invite.hunterId === hunterId)) return "hunter";
  if (grouped.pending.some((invite) => invite.hunterId === hunterId)) return "invited";
  return "none";
}

export function hunterLabel(hunter: { displayName: string | null; email: string }) {
  return hunter.displayName?.trim() || hunter.email;
}

export function hunterInitials(hunter: { displayName: string | null; email: string }) {
  const source = hunter.displayName?.trim() || hunter.email;
  const parts = source.split(/[\s@._-]+/).filter(Boolean);
  const initials = parts.slice(0, 2).map((part) => part[0]?.toUpperCase() ?? "");
  return initials.join("") || "?";
}

export function inviteStatusBadge(status: ProjectInviteStatus) {
  switch (status) {
    case "accepted":
      return (
        <Badge variant="outline" className="border-emerald-500/20 bg-emerald-500/10 text-emerald-400">
          Accepted
        </Badge>
      );
    case "pending":
      return (
        <Badge variant="outline" className="border-yellow-500/20 bg-yellow-500/10 text-yellow-400">
          Pending
        </Badge>
      );
    case "rejected":
      return (
        <Badge variant="outline" className="border-red-500/20 bg-red-500/10 text-red-400">
          Declined
        </Badge>
      );
    case "cancelled":
      return <Badge variant="secondary">Cancelled</Badge>;
  }
}

export function formatInviteDate(value: string) {
  return new Date(value).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}
