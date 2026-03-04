"use client";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import type { OpsEvent } from "@/lib/api-client";
import { formatDateTime, statusBadge } from "../_lib/ops-events";

type OpsEventDetailsDialogProps = {
  event: OpsEvent | null;
  onOpenChange: (open: boolean) => void;
};

export function OpsEventDetailsDialog({ event, onOpenChange }: OpsEventDetailsDialogProps) {
  return (
    <Dialog open={event != null} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90vh] max-w-3xl overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Ops Event Details</DialogTitle>
          <DialogDescription>
            Full event details for incident investigation.
          </DialogDescription>
        </DialogHeader>

        {event ? (
          <div className="space-y-4">
            <div className="grid gap-3 md:grid-cols-2">
              <div className="rounded-md border border-border/70 bg-muted/20 p-3">
                <p className="text-xs font-semibold uppercase tracking-[0.08em] text-muted-foreground">
                  Time
                </p>
                <p className="mt-1 text-sm">{formatDateTime(event.createdAt)}</p>
              </div>
              <div className="rounded-md border border-border/70 bg-muted/20 p-3">
                <p className="text-xs font-semibold uppercase tracking-[0.08em] text-muted-foreground">
                  Status
                </p>
                <div className="mt-1">{statusBadge(event.status)}</div>
              </div>
              <div className="rounded-md border border-border/70 bg-muted/20 p-3">
                <p className="text-xs font-semibold uppercase tracking-[0.08em] text-muted-foreground">
                  Source / Provider
                </p>
                <p className="mt-1 text-sm">
                  {event.source} / {event.provider}
                </p>
              </div>
              <div className="rounded-md border border-border/70 bg-muted/20 p-3">
                <p className="text-xs font-semibold uppercase tracking-[0.08em] text-muted-foreground">
                  Actor
                </p>
                <p className="mt-1 text-sm">
                  {event.actor?.email ?? event.actor?.displayName ?? "System"}
                </p>
              </div>
            </div>

            <div className="rounded-md border border-border/70 bg-muted/20 p-3">
              <p className="text-xs font-semibold uppercase tracking-[0.08em] text-muted-foreground">
                Action
              </p>
              <p className="mt-1 break-all font-mono text-xs">{event.action}</p>
            </div>

            <div className="rounded-md border border-border/70 bg-muted/20 p-3">
              <p className="text-xs font-semibold uppercase tracking-[0.08em] text-muted-foreground">
                Summary
              </p>
              <p className="mt-1 text-sm">{event.summary}</p>
            </div>

            <div className="grid gap-3 md:grid-cols-2">
              <div className="rounded-md border border-border/70 bg-muted/20 p-3">
                <p className="text-xs font-semibold uppercase tracking-[0.08em] text-muted-foreground">
                  Resource Type
                </p>
                <p className="mt-1 text-sm">{event.resourceType}</p>
              </div>
              <div className="rounded-md border border-border/70 bg-muted/20 p-3">
                <p className="text-xs font-semibold uppercase tracking-[0.08em] text-muted-foreground">
                  Resource ID
                </p>
                <p className="mt-1 break-all font-mono text-xs">
                  {event.resourceId ?? "N/A"}
                </p>
              </div>
            </div>

            <div className="rounded-md border border-border/70 bg-slate-950/40 p-3">
              <p className="text-xs font-semibold uppercase tracking-[0.08em] text-muted-foreground">
                Metadata (JSON)
              </p>
              <pre className="mt-2 overflow-x-auto whitespace-pre-wrap break-words text-xs text-slate-200">
                {JSON.stringify(event.metadata ?? {}, null, 2)}
              </pre>
            </div>
          </div>
        ) : null}
      </DialogContent>
    </Dialog>
  );
}
