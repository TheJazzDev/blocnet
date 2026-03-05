"use client";

import { Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import type { OpsEvent } from "@/lib/api-client";
import { compactMetadata, formatDateTime, statusBadge } from "../_lib/ops-events";

type OpsEventsTableCardProps = {
  loading: boolean;
  error: string | null;
  events: OpsEvent[];
  page: number;
  hasNext: boolean;
  onSelectEvent: (event: OpsEvent) => void;
  onPreviousPage: () => void;
  onNextPage: () => void;
};

export function OpsEventsTableCard({
  loading,
  error,
  events,
  page,
  hasNext,
  onSelectEvent,
  onPreviousPage,
  onNextPage,
}: OpsEventsTableCardProps) {
  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-base">Event Stream</CardTitle>
      </CardHeader>
      <CardContent>
        {loading ? (
          <div className="py-10 text-center text-sm text-muted-foreground">
            <Loader2 className="mx-auto mb-2 h-4 w-4 animate-spin" />
            Loading events...
          </div>
        ) : error ? (
          <p className="py-10 text-center text-sm text-red-400">{error}</p>
        ) : events.length === 0 ? (
          <p className="py-10 text-center text-sm text-muted-foreground">
            No events found for the selected filters.
          </p>
        ) : (
          <>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Time</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Source</TableHead>
                  <TableHead>Provider</TableHead>
                  <TableHead>Action</TableHead>
                  <TableHead>Summary</TableHead>
                  <TableHead>Actor</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {events.map((event) => {
                  const compact = compactMetadata(event.metadata);
                  return (
                    <TableRow
                      key={event.id}
                      className="cursor-pointer"
                      onClick={() => onSelectEvent(event)}
                    >
                      <TableCell className="whitespace-nowrap text-xs text-muted-foreground">
                        {formatDateTime(event.createdAt)}
                      </TableCell>
                      <TableCell>{statusBadge(event.status)}</TableCell>
                      <TableCell>
                        <Badge variant="secondary">{event.source}</Badge>
                      </TableCell>
                      <TableCell>
                        <Badge variant="outline">{event.provider}</Badge>
                      </TableCell>
                      <TableCell className="font-mono text-xs">{event.action}</TableCell>
                      <TableCell className="max-w-[380px]">
                        <p className="truncate text-sm">{event.summary}</p>
                        {compact ? (
                          <p className="truncate text-xs text-muted-foreground">{compact}</p>
                        ) : null}
                      </TableCell>
                      <TableCell className="text-xs text-muted-foreground">
                        {event.actor?.email ?? event.actor?.displayName ?? "System"}
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
            <div className="mt-3 flex items-center justify-between">
              <p className="text-xs text-muted-foreground">
                Showing page {page + 1} ({events.length} rows)
              </p>
              <div className="flex items-center gap-2">
                <Button variant="outline" onClick={onPreviousPage} disabled={page === 0}>
                  Previous
                </Button>
                <Button variant="outline" onClick={onNextPage} disabled={!hasNext}>
                  Next
                </Button>
              </div>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}
