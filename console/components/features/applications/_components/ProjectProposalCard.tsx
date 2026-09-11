"use client";

import { FileText } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Separator } from "@/components/ui/separator";
import type { ProjectProposal } from "@/lib/api-client";
import { ClampedRichContent } from "./ClampedRichContent";
import { ReviewButtons } from "./ReviewButtons";
import { formatDate, getInitials, statusBadge } from "./applications-utils";

type ProjectProposalCardProps = {
  proposal: ProjectProposal;
  canReview: boolean;
  onReview: (status: "approved" | "rejected") => Promise<void>;
};

export function ProjectProposalCard({ proposal, canReview, onReview }: ProjectProposalCardProps) {
  return (
    <Card>
      <CardContent className="pt-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-secondary text-xs font-bold">
                {proposal.symbol?.slice(0, 3) ?? proposal.name.slice(0, 2).toUpperCase()}
              </div>
              <h3 className="font-semibold">{proposal.name}</h3>
              {statusBadge(proposal.status)}
              {proposal.primaryTag && <Badge variant="secondary">{proposal.primaryTag.name}</Badge>}
            </div>

            {/* Descriptions can be long markdown with embedded diagrams: clamp them. */}
            <ClampedRichContent content={proposal.description} className="mt-3" />

            {proposal.reason && (
              <>
                <Separator className="my-3" />
                <div className="flex items-start gap-2">
                  <FileText className="mt-0.5 h-3.5 w-3.5 shrink-0 text-muted-foreground" />
                  <ClampedRichContent content={proposal.reason} className="min-w-0 flex-1" />
                </div>
              </>
            )}

            <div className="mt-3 flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
              <Avatar className="h-5 w-5">
                <AvatarFallback className="text-[9px]">
                  {getInitials(proposal.applicant.displayName, proposal.applicant.email)}
                </AvatarFallback>
              </Avatar>
              <span>Proposed by {proposal.applicant.displayName ?? proposal.applicant.email}</span>
              <span>&middot;</span>
              <span>{formatDate(proposal.createdAt)}</span>
            </div>
          </div>
          {canReview && proposal.status === "pending" && (
            <ReviewButtons
              onApprove={() => onReview("approved")}
              onReject={() => onReview("rejected")}
            />
          )}
        </div>
      </CardContent>
    </Card>
  );
}
