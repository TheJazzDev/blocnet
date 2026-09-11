"use client";

import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import type { ProjectHunterInvite } from "@/lib/api-client";
import {
  formatInviteDate,
  hunterInitials,
  hunterLabel,
  inviteStatusBadge,
  type GroupedInvites,
} from "../_lib/project-hunters";

type ProjectInviteListProps = {
  grouped: GroupedInvites;
  loading: boolean;
  error: string | null;
};

function InviteRow({ invite }: { invite: ProjectHunterInvite }) {
  return (
    <li className="flex items-start gap-3 rounded-lg border border-border/60 bg-card/60 px-3 py-2">
      <Avatar className="h-8 w-8 shrink-0">
        <AvatarFallback className="text-xs">{hunterInitials(invite.hunter)}</AvatarFallback>
      </Avatar>
      <div className="min-w-0 flex-1">
        <div className="flex flex-wrap items-center gap-2">
          <p className="truncate text-sm font-medium">{hunterLabel(invite.hunter)}</p>
          {inviteStatusBadge(invite.status)}
        </div>
        <p className="truncate text-xs text-muted-foreground">{invite.hunter.email}</p>
        {invite.note && (
          <p className="mt-1 line-clamp-2 text-xs text-muted-foreground">“{invite.note}”</p>
        )}
        <p className="mt-1 text-[11px] text-muted-foreground">
          {invite.status === "pending" ? "Invited" : "Updated"} {formatInviteDate(invite.updatedAt)}
        </p>
      </div>
    </li>
  );
}

function InviteSection({
  title,
  hint,
  invites,
  emptyText,
}: {
  title: string;
  hint?: string;
  invites: ProjectHunterInvite[];
  emptyText: string;
}) {
  return (
    <section className="space-y-2">
      <div>
        <h3 className="text-xs font-semibold uppercase tracking-[0.08em] text-muted-foreground">
          {title}
          <span className="ml-1.5 font-normal normal-case tracking-normal">({invites.length})</span>
        </h3>
        {hint && <p className="mt-0.5 text-xs text-muted-foreground">{hint}</p>}
      </div>
      {invites.length === 0 ? (
        <p className="rounded-lg border border-dashed border-border/60 px-3 py-3 text-center text-xs text-muted-foreground">
          {emptyText}
        </p>
      ) : (
        <ul className="space-y-2">
          {invites.map((invite) => (
            <InviteRow key={invite.id} invite={invite} />
          ))}
        </ul>
      )}
    </section>
  );
}

export function ProjectInviteList({ grouped, loading, error }: ProjectInviteListProps) {
  if (loading) return <LoadingSpinner className="py-6" />;
  if (error) return <p className="text-sm text-destructive">{error}</p>;

  return (
    <div className="space-y-5">
      <InviteSection
        title="Hunters on this project"
        hint="Hunters who accepted an invite. Direct assignments are recorded in the audit log but the API does not list them yet."
        invites={grouped.accepted}
        emptyText="No hunter has accepted an invite yet."
      />
      <InviteSection
        title="Pending invites"
        invites={grouped.pending}
        emptyText="No pending invites."
      />
      {grouped.closed.length > 0 && (
        <InviteSection
          title="Declined or cancelled"
          invites={grouped.closed}
          emptyText=""
        />
      )}
    </div>
  );
}
