"use client";

import { useEffect, useState } from "react";
import { CheckCircle2, XCircle, Clock, FileText, Loader2 } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { PageHeader } from "@/components/page-header";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Separator } from "@/components/ui/separator";
import { useAdminSession } from "@/components/admin-shell";
import { clientApi, type AdminApplication, type ProjectProposal } from "@/lib/api-client";
import { canReviewAdminApplications, canReviewProjectProposals } from "@/lib/rbac";

function statusBadge(status: "pending" | "approved" | "rejected") {
  switch (status) {
    case "pending":
      return (
        <Badge variant="outline" className="border-yellow-500/20 bg-yellow-500/10 text-yellow-500">
          <Clock className="mr-1 h-3 w-3" />
          Pending
        </Badge>
      );
    case "approved":
      return (
        <Badge variant="outline" className="border-emerald-500/20 bg-emerald-500/10 text-emerald-500">
          <CheckCircle2 className="mr-1 h-3 w-3" />
          Approved
        </Badge>
      );
    case "rejected":
      return (
        <Badge variant="outline" className="border-red-500/20 bg-red-500/10 text-red-400">
          <XCircle className="mr-1 h-3 w-3" />
          Rejected
        </Badge>
      );
  }
}

function getInitials(name: string | null, fallback: string) {
  return (name ?? fallback)
    .split(/[\s@]/)
    .filter(Boolean)
    .map((w) => w[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}

function formatDate(date: string) {
  return new Date(date).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

function ReviewButtons({
  onApprove,
  onReject,
}: {
  onApprove: () => Promise<void>;
  onReject: () => Promise<void>;
}) {
  const [loading, setLoading] = useState<"approve" | "reject" | null>(null);

  async function handle(action: "approve" | "reject") {
    setLoading(action);
    try {
      if (action === "approve") {
        await onApprove();
      } else {
        await onReject();
      }
    } finally {
      setLoading(null);
    }
  }

  return (
    <div className="flex shrink-0 gap-2">
      <Button
        size="sm"
        className="bg-emerald-600 hover:bg-emerald-700"
        disabled={loading !== null}
        onClick={() => handle("approve")}
      >
        {loading === "approve" ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <CheckCircle2 className="h-3.5 w-3.5" />}
        Approve
      </Button>
      <Button
        size="sm"
        variant="destructive"
        disabled={loading !== null}
        onClick={() => handle("reject")}
      >
        {loading === "reject" ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <XCircle className="h-3.5 w-3.5" />}
        Reject
      </Button>
    </div>
  );
}

export default function ApplicationsPage() {
  const session = useAdminSession();
  const canReviewAdmin = canReviewAdminApplications(session.roles);
  const canReviewProposals = canReviewProjectProposals(session.roles);

  const [adminApps, setAdminApps] = useState<AdminApplication[]>([]);
  const [proposals, setProposals] = useState<ProjectProposal[]>([]);
  const [loading, setLoading] = useState(true);

  function load() {
    setLoading(true);
    Promise.all([
      clientApi.listAdminApplications().catch((): AdminApplication[] => []),
      clientApi.listProjectProposals().catch((): ProjectProposal[] => []),
    ])
      .then(([apps, props]) => {
        setAdminApps(apps);
        setProposals(props);
      })
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
  }, []);

  const pendingAdminApps = adminApps.filter((a) => a.status === "pending");
  const pendingProposals = proposals.filter((p) => p.status === "pending");

  return (
    <div className="space-y-6">
      <PageHeader title="Applications" description="Review role applications and project proposals.">
        {!loading && (
          <Badge variant="outline" className="border-yellow-500/20 bg-yellow-500/10 text-yellow-500">
            {pendingAdminApps.length + pendingProposals.length} pending
          </Badge>
        )}
      </PageHeader>

      <Tabs defaultValue="admin-apps">
        <TabsList>
          <TabsTrigger value="admin-apps">
            Role Applications
            {!loading && pendingAdminApps.length > 0 && (
              <Badge variant="secondary" className="ml-2 h-5 w-5 justify-center rounded-full p-0 text-[10px]">
                {pendingAdminApps.length}
              </Badge>
            )}
          </TabsTrigger>
          <TabsTrigger value="project-proposals">
            Project Proposals
            {!loading && pendingProposals.length > 0 && (
              <Badge variant="secondary" className="ml-2 h-5 w-5 justify-center rounded-full p-0 text-[10px]">
                {pendingProposals.length}
              </Badge>
            )}
          </TabsTrigger>
        </TabsList>

        <TabsContent value="admin-apps" className="space-y-4">
          {loading
            ? <LoadingSpinner className="py-10" />
            : adminApps.length === 0
              ? <p className="py-8 text-center text-sm text-muted-foreground">No role applications found.</p>
              : adminApps.map((app) => (
                  <Card key={app.id}>
                    <CardContent className="pt-6">
                      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                        <div className="flex items-start gap-3">
                          <Avatar className="h-10 w-10">
                            <AvatarFallback>{getInitials(app.user.displayName, app.user.email)}</AvatarFallback>
                          </Avatar>
                          <div className="flex-1">
                            <div className="flex flex-wrap items-center gap-2">
                              <h3 className="font-semibold">{app.user.displayName ?? app.user.email}</h3>
                              {statusBadge(app.status)}
                              <Badge variant="secondary">{app.targetRole === "admin" ? "Admin Role" : "Hunter Role"}</Badge>
                            </div>
                            <p className="mt-0.5 text-sm text-muted-foreground">{app.user.email}</p>
                            <p className="mt-3 text-sm leading-relaxed">{app.reason}</p>
                            <p className="mt-2 text-xs text-muted-foreground">
                              Applied {formatDate(app.createdAt)}
                              {app.reviewedAt && ` · Reviewed ${formatDate(app.reviewedAt)}`}
                            </p>
                          </div>
                        </div>
                        {canReviewAdmin && app.status === "pending" && (
                          <ReviewButtons
                            onApprove={async () => {
                              await clientApi.reviewAdminApplication(app.id, { status: "approved" });
                              load();
                            }}
                            onReject={async () => {
                              await clientApi.reviewAdminApplication(app.id, { status: "rejected" });
                              load();
                            }}
                          />
                        )}
                      </div>
                    </CardContent>
                  </Card>
                ))}
        </TabsContent>

        <TabsContent value="project-proposals" className="space-y-4">
          {loading
            ? <LoadingSpinner className="py-10" />
            : proposals.length === 0
              ? <p className="py-8 text-center text-sm text-muted-foreground">No project proposals found.</p>
              : proposals.map((proposal) => (
                  <Card key={proposal.id}>
                    <CardContent className="pt-6">
                      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                        <div className="flex-1">
                          <div className="flex flex-wrap items-center gap-2">
                            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-secondary text-xs font-bold">
                              {proposal.symbol?.slice(0, 3) ?? proposal.name.slice(0, 2).toUpperCase()}
                            </div>
                            <h3 className="font-semibold">{proposal.name}</h3>
                            {statusBadge(proposal.status)}
                            {proposal.primaryTag && <Badge variant="secondary">{proposal.primaryTag.name}</Badge>}
                          </div>
                          <p className="mt-3 text-sm leading-relaxed">{proposal.description}</p>
                          {proposal.reason && (
                            <>
                              <Separator className="my-3" />
                              <div className="flex items-start gap-2">
                                <FileText className="mt-0.5 h-3.5 w-3.5 shrink-0 text-muted-foreground" />
                                <p className="text-sm text-muted-foreground">{proposal.reason}</p>
                              </div>
                            </>
                          )}
                          <div className="mt-3 flex items-center gap-2 text-xs text-muted-foreground">
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
                        {canReviewProposals && proposal.status === "pending" && (
                          <ReviewButtons
                            onApprove={async () => {
                              await clientApi.reviewProjectProposal(proposal.id, { status: "approved" });
                              load();
                            }}
                            onReject={async () => {
                              await clientApi.reviewProjectProposal(proposal.id, { status: "rejected" });
                              load();
                            }}
                          />
                        )}
                      </div>
                    </CardContent>
                  </Card>
                ))}
        </TabsContent>
      </Tabs>
    </div>
  );
}
