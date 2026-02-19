"use client";

import { useEffect, useState } from "react";
import { Download, Filter, Clock, Loader2 } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { PageHeader } from "@/components/page-header";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { clientApi, type AuditLog } from "@/lib/api-client";

function actionBadge(action: string) {
  const parts = action.split(".");
  const verb = parts[parts.length - 1] ?? "";
  let variant: "default" | "secondary" | "destructive" | "outline" = "outline";
  if (verb === "create" || verb === "promote" || verb === "assign")
    variant = "default";
  if (verb === "update" || verb === "review") variant = "secondary";
  if (verb === "delete" || verb === "archive") variant = "destructive";

  return (
    <Badge variant={variant} className="font-mono text-[10px]">
      {action}
    </Badge>
  );
}

function resourceTypeBadge(type: string) {
  return (
    <Badge variant="secondary" className="text-[10px]">
      {type.replace(/_/g, " ")}
    </Badge>
  );
}

function formatTimestamp(dateStr: string) {
  const d = new Date(dateStr);
  return d.toLocaleString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export default function AuditLogPage() {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    clientApi
      .listAuditLog(100)
      .then(setLogs)
      .catch(() => setLogs([]))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Audit Log"
        description="Complete history of all admin actions on the platform."
      >
        <Button variant="outline" disabled>
          <Download className="h-4 w-4" />
          Export
        </Button>
      </PageHeader>

      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-base">
            <Filter className="h-4 w-4" />
            Event Log
            <span className="text-sm font-normal text-muted-foreground">
              {loading ? (
                <Loader2 className="inline h-3 w-3 animate-spin" />
              ) : (
                `(showing latest ${logs.length} events)`
              )}
            </span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <LoadingSpinner className="py-10" />
          ) : logs.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">
              No audit events found. Make sure the backend is running.
            </p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Timestamp</TableHead>
                  <TableHead>Action</TableHead>
                  <TableHead>Resource</TableHead>
                  <TableHead>Resource ID</TableHead>
                  <TableHead>Actor</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {logs.map((log) => (
                  <TableRow key={log.id}>
                    <TableCell className="whitespace-nowrap">
                      <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                        <Clock className="h-3 w-3" />
                        {formatTimestamp(log.createdAt)}
                      </div>
                    </TableCell>
                    <TableCell>{actionBadge(log.action)}</TableCell>
                    <TableCell>{resourceTypeBadge(log.resourceType)}</TableCell>
                    <TableCell>
                      <p className="max-w-[180px] truncate font-mono text-xs text-muted-foreground">
                        {log.resourceId ?? "—"}
                      </p>
                    </TableCell>
                    <TableCell>
                      <span className="text-sm text-muted-foreground">
                        {log.actor?.email ?? log.actor?.displayName ?? "System"}
                      </span>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
