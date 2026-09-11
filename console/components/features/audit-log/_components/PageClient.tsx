"use client";

import { useMemo, useState } from "react";
import { Download, Filter, Loader2 } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip";
import { PageHeader } from "@/components/page-header";
import { ViewEventsToggle } from "@/components/shared/ViewEventsToggle";
import { filterViewAuditEvents } from "@/lib/audit-events";
import { useAuditLogQuery } from "@/lib/hooks/queries";
import { AuditLogTable } from "./AuditLogTable";

const PAGE_LIMIT = 100;

export default function AuditLogPage() {
  const { data: logs = [], isLoading: loading } = useAuditLogQuery({ limit: PAGE_LIMIT });
  const [showViewEvents, setShowViewEvents] = useState(false);
  const { visible, hiddenViewCount } = useMemo(
    () => filterViewAuditEvents(logs, showViewEvents),
    [logs, showViewEvents],
  );

  return (
    <div className="space-y-6">
      <PageHeader
        title="Audit Log"
        description="Complete history of all admin actions on the platform."
      >
        <Tooltip>
          <TooltipTrigger asChild>
            {/* Disabled buttons swallow pointer events; the span carries the tooltip. */}
            <span tabIndex={0} className="inline-flex">
              <Button variant="outline" disabled aria-describedby="audit-export-hint">
                <Download className="h-4 w-4" />
                Export
              </Button>
            </span>
          </TooltipTrigger>
          <TooltipContent id="audit-export-hint">CSV export coming soon</TooltipContent>
        </Tooltip>
      </PageHeader>

      <Card>
        <CardHeader className="pb-3">
          <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
            <CardTitle className="flex flex-wrap items-center gap-2 text-base">
              <Filter className="h-4 w-4" />
              Event Log
              <span className="text-sm font-normal text-muted-foreground">
                {loading ? (
                  <Loader2 className="inline h-3 w-3 animate-spin" />
                ) : (
                  `(showing ${visible.length} of the latest ${logs.length} events)`
                )}
              </span>
            </CardTitle>
            <ViewEventsToggle
              checked={showViewEvents}
              onCheckedChange={setShowViewEvents}
              hiddenCount={hiddenViewCount}
            />
          </div>
        </CardHeader>
        <CardContent>
          {loading ? (
            <LoadingSpinner className="py-10" />
          ) : logs.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">
              No audit events found. Make sure the backend is running.
            </p>
          ) : visible.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">
              All {logs.length} recent events are view events. Turn on &ldquo;Show view
              events&rdquo; to see them.
            </p>
          ) : (
            <AuditLogTable logs={visible} />
          )}
        </CardContent>
      </Card>
    </div>
  );
}
