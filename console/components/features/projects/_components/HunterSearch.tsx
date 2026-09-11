"use client";

import { useState } from "react";
import { Loader2, Search, UserPlus, Send } from "lucide-react";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { LevelBadge } from "@/components/shared/levels";
import type { AdminUser, AdminUsersResponse } from "@/lib/api-client";
import { useDebounce } from "@/lib/hooks";
import { useUsersQuery } from "@/lib/hooks/queries";
import {
  hunterInitials,
  hunterLabel,
  hunterProjectState,
  type GroupedInvites,
} from "../_lib/project-hunters";

type HunterActions = {
  grouped: GroupedInvites;
  /** Hunter id with an in-flight assign/invite, to disable its buttons. */
  busyHunterId: string | null;
  disabled: boolean;
  onAssign: (hunter: AdminUser) => void;
  onInvite: (hunter: AdminUser) => void;
};

function HunterRow({ hunter, grouped, busyHunterId, disabled, onAssign, onInvite }: HunterActions & { hunter: AdminUser }) {
  const state = hunterProjectState(hunter.id, grouped);
  const onProject = state === "hunter";
  const busy = busyHunterId === hunter.id;
  const locked = disabled || busy || onProject;

  return (
    <li className="flex flex-col gap-2 rounded-lg border border-border/60 bg-card/60 px-3 py-2 sm:flex-row sm:items-center">
      <div className="flex min-w-0 flex-1 items-center gap-3">
        <Avatar className="h-8 w-8 shrink-0">
          <AvatarFallback className="text-xs">{hunterInitials(hunter)}</AvatarFallback>
        </Avatar>
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-1.5">
            <p className="truncate text-sm font-medium">{hunterLabel(hunter)}</p>
            {onProject && (
              <Badge variant="outline" className="border-emerald-500/20 bg-emerald-500/10 text-emerald-400">
                On project
              </Badge>
            )}
            {state === "invited" && (
              <Badge variant="outline" className="border-yellow-500/20 bg-yellow-500/10 text-yellow-400">
                Invited
              </Badge>
            )}
          </div>
          <p className="truncate text-xs text-muted-foreground">{hunter.email}</p>
        </div>
        <LevelBadge level={hunter.currentLevel} size="sm" />
      </div>
      <div className="flex shrink-0 gap-2">
        <Button
          size="sm"
          variant="outline"
          disabled={locked}
          onClick={() => onAssign(hunter)}
          title="Assign now, without waiting for the hunter to accept">
          {busy ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <UserPlus className="h-3.5 w-3.5" />}
          Assign
        </Button>
        <Button
          size="sm"
          disabled={locked}
          onClick={() => onInvite(hunter)}
          title="Send an invite the hunter accepts or declines in the app">
          <Send className="h-3.5 w-3.5" />
          {state === "invited" ? "Re-invite" : "Invite"}
        </Button>
      </div>
    </li>
  );
}

function HunterResults({
  query,
  data,
  loading,
  error,
  actions,
}: {
  query: string;
  data: AdminUsersResponse | undefined;
  loading: boolean;
  error: unknown;
  actions: HunterActions;
}) {
  if (loading) return <LoadingSpinner className="py-4" />;
  if (error) {
    return (
      <p className="text-sm text-destructive">
        {error instanceof Error ? error.message : "Failed to load hunters"}
      </p>
    );
  }

  const hunters = data?.data ?? [];
  if (hunters.length === 0) {
    return (
      <p className="rounded-lg border border-dashed border-border/60 px-3 py-3 text-center text-xs text-muted-foreground">
        {query ? `No hunters match “${query}”.` : "No members hold the hunter role yet."}
      </p>
    );
  }

  return (
    <>
      <ul className="space-y-2">
        {hunters.map((hunter) => (
          <HunterRow key={hunter.id} hunter={hunter} {...actions} />
        ))}
      </ul>
      {data && data.total > hunters.length && (
        <p className="text-[11px] text-muted-foreground">
          Showing {hunters.length} of {data.total} hunters. Refine the search to find others.
        </p>
      )}
    </>
  );
}

/**
 * Searches members who hold the hunter role and offers Assign / Invite per row.
 * Backed by GET /admin/users?role=hunter&q=.
 */
export function HunterSearch(actions: HunterActions) {
  const [query, setQuery] = useState("");
  const q = useDebounce(query.trim(), 300);
  const { data, isLoading, error } = useUsersQuery({
    role: "hunter",
    q: q || undefined,
    limit: 8,
    offset: 0,
  });

  return (
    <section className="space-y-2">
      <h3 className="text-xs font-semibold uppercase tracking-[0.08em] text-muted-foreground">
        Find a hunter
      </h3>
      <div className="relative">
        <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          className="pl-9"
          placeholder="Search hunters by name, username, or email"
          aria-label="Search hunters"
        />
      </div>
      <HunterResults query={q} data={data} loading={isLoading} error={error} actions={actions} />
    </section>
  );
}
