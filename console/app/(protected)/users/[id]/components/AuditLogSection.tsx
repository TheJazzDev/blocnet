"use client";

import { FileText, Filter } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

type AuditLogSectionProps = {
  userId: string;
};

/**
 * AuditLogSection - Displays audit log for user actions
 * TODO: Implement pagination and filtering
 */
export function AuditLogSection({ userId }: AuditLogSectionProps) {
  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="text-sm sm:text-base flex items-center gap-2">
            <FileText className="h-4 w-4 sm:h-5 sm:w-5" />
            Audit Log
          </CardTitle>
          <button className="flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground transition-colors">
            <Filter className="h-3 w-3" />
            Filter
          </button>
        </div>
      </CardHeader>
      <CardContent>
        <div className="text-center py-8 text-xs sm:text-sm text-muted-foreground">
          <FileText className="h-10 w-10 sm:h-12 sm:w-12 mx-auto mb-2 text-muted-foreground/50" />
          <p>Audit log entries will be displayed here</p>
          <p className="text-xs mt-1">Track all actions and changes for this user</p>
        </div>
      </CardContent>
    </Card>
  );
}
