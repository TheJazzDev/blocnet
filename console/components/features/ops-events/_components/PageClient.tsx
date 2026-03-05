"use client";

import { Loader2, RefreshCw } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { useAdminSession } from "@/components/admin-shell";
import { canViewOpsEvents } from "@/lib/rbac";
import { OpsFiltersCard } from "./OpsFiltersCard";
import { OpsEventsTableCard } from "./OpsEventsTableCard";
import { OpsEventDetailsDialog } from "./OpsEventDetailsDialog";
import { useOpsEvents } from "../_hooks/use-ops-events";

export default function OpsEventsPageClient() {
  const session = useAdminSession();
  const canView = canViewOpsEvents(session.effectiveRoles);
  const state = useOpsEvents(canView);

  if (!canView) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Ops Events"
          description="Owner-only operational event stream."
        />
        <Card>
          <CardContent className="py-10 text-sm text-muted-foreground">
            Access denied. Owner role is required to view operational events.
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Ops Events"
        description="Cross-system operational stream for email, wallet, tips, social, and auth flows."
      >
        <div className="flex items-center gap-2">
          <Button
            variant={state.autoRefresh ? "default" : "outline"}
            onClick={() => state.setAutoRefresh(!state.autoRefresh)}
          >
            Auto-refresh {state.autoRefresh ? "On" : "Off"}
          </Button>
          <Button
            variant="outline"
            onClick={() => void state.loadEvents(false)}
            disabled={state.refreshing}
          >
            {state.refreshing ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <RefreshCw className="h-4 w-4" />
            )}
            Refresh
          </Button>
        </div>
      </PageHeader>

      <OpsFiltersCard
        q={state.q}
        setQ={state.setQ}
        source={state.source}
        setSource={state.setSource}
        provider={state.provider}
        setProvider={state.setProvider}
        status={state.status}
        setStatus={state.setStatus}
        from={state.from}
        setFrom={state.setFrom}
        to={state.to}
        setTo={state.setTo}
        refreshing={state.refreshing}
        providerLinks={state.providerLinks}
        onApply={state.applyFilters}
        onReset={state.resetFilters}
      />

      <OpsEventsTableCard
        loading={state.loading}
        error={state.error}
        events={state.events}
        page={state.page}
        hasNext={state.hasNext}
        onSelectEvent={state.setSelectedEvent}
        onPreviousPage={() => state.setPage((prev) => Math.max(prev - 1, 0))}
        onNextPage={() => state.setPage((prev) => prev + 1)}
      />

      <OpsEventDetailsDialog
        event={state.selectedEvent}
        onOpenChange={(open) => {
          if (!open) {
            state.setSelectedEvent(null);
          }
        }}
      />
    </div>
  );
}
