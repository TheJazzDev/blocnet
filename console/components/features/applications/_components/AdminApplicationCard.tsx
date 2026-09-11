"use client";

import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { RichContentRenderer } from "@/components/rich-content-renderer";
import type { AdminApplication } from "@/lib/api-client";
import { getRoleCapabilities } from "@/lib/rbac";
import { ReviewButtons } from "./ReviewButtons";
import { formatDate, getInitials, statusBadge } from "./applications-utils";

const ADMIN_ROLE_PREVIEW = getRoleCapabilities("admin")
  .map((entry) => entry.label)
  .slice(0, 4);

type AdminApplicationCardProps = {
  app: AdminApplication;
  canReview: boolean;
  onReview: (status: "approved" | "rejected") => Promise<void>;
};

export function AdminApplicationCard({ app, canReview, onReview }: AdminApplicationCardProps) {
  return (
    <Card>
      <CardContent className="pt-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div className="flex min-w-0 items-start gap-3">
            <Avatar className="h-10 w-10 shrink-0">
              <AvatarFallback>{getInitials(app.user.displayName, app.user.email)}</AvatarFallback>
            </Avatar>
            <div className="min-w-0 flex-1">
              <div className="flex flex-wrap items-center gap-2">
                <h3 className="font-semibold">{app.user.displayName ?? app.user.email}</h3>
                {statusBadge(app.status)}
                <Badge variant="secondary">
                  {app.targetRole === "admin" ? "Admin Role" : "Hunter Role"}
                </Badge>
              </div>
              <p className="mt-0.5 text-sm text-muted-foreground">{app.user.email}</p>
              <RichContentRenderer content={app.reason} className="mt-3" />
              <div className="mt-3 flex flex-wrap gap-1.5">
                {app.targetRole === "admin" ? (
                  ADMIN_ROLE_PREVIEW.map((label) => (
                    <Badge
                      key={`${app.id}-${label}`}
                      variant="outline"
                      className="border-primary/30 bg-primary/10 text-primary"
                    >
                      {label}
                    </Badge>
                  ))
                ) : (
                  <Badge variant="outline" className="border-teal-500/30 bg-teal-500/10 text-teal-300">
                    Hunter space access only
                  </Badge>
                )}
              </div>
              <p className="mt-2 text-xs text-muted-foreground">
                Applied {formatDate(app.createdAt)}
                {app.reviewedAt && ` · Reviewed ${formatDate(app.reviewedAt)}`}
              </p>
            </div>
          </div>
          {app.status === "pending" &&
            (canReview ? (
              <ReviewButtons
                onApprove={() => onReview("approved")}
                onReject={() => onReview("rejected")}
              />
            ) : (
              <p
                className="shrink-0 rounded-md border border-amber-500/30 bg-amber-500/10 px-3 py-2 text-xs text-amber-200"
                title="The backend only lets the owner approve or reject role applications; admins can review the details here.">
                Owner review required
              </p>
            ))}
        </div>
      </CardContent>
    </Card>
  );
}
