"use client";

import { Clock } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import type { AuditLog } from "@/lib/api-client";

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

export function AuditLogTable({ logs }: { logs: AuditLog[] }) {
  return (
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
  );
}
