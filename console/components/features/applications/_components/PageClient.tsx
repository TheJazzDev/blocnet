"use client";

import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { PageHeader } from "@/components/page-header";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useAdminSession } from "@/components/admin-shell";
import { canReviewAdminApplications, canReviewProjectProposals } from "@/lib/rbac";
import {
  useAdminApplicationsQuery,
  useProjectProposalsQuery,
  useReviewAdminApplicationMutation,
  useReviewProjectProposalMutation,
} from "@/lib/hooks/queries";
import { AdminApplicationCard } from "./AdminApplicationCard";
import { ProjectProposalCard } from "./ProjectProposalCard";

function PendingCount({ count }: { count: number }) {
  if (count === 0) return null;
  return (
    <Badge variant="secondary" className="ml-2 h-5 w-5 justify-center rounded-full p-0 text-[10px]">
      {count}
    </Badge>
  );
}

export default function ApplicationsPage() {
  const session = useAdminSession();
  const canReviewAdmin = canReviewAdminApplications(session.effectiveRoles);
  const canReviewProposals = canReviewProjectProposals(session.effectiveRoles);

  const { data: adminApps = [], isLoading: adminAppsLoading } = useAdminApplicationsQuery();
  const { data: proposals = [], isLoading: proposalsLoading } = useProjectProposalsQuery();
  const reviewAdminAppMutation = useReviewAdminApplicationMutation();
  const reviewProposalMutation = useReviewProjectProposalMutation();

  const loading = adminAppsLoading || proposalsLoading;
  const pendingAdminApps = adminApps.filter((a) => a.status === "pending");
  const pendingProposals = proposals.filter((p) => p.status === "pending");

  return (
    <div className="space-y-6">
      <PageHeader title="Applications" description="Review role applications and project proposals.">
        <Button variant="outline" size="sm" asChild>
          <Link href="/console-access">Manage Console Access</Link>
        </Button>
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
            {!loading && <PendingCount count={pendingAdminApps.length} />}
          </TabsTrigger>
          <TabsTrigger value="project-proposals">
            Project Proposals
            {!loading && <PendingCount count={pendingProposals.length} />}
          </TabsTrigger>
        </TabsList>

        <TabsContent value="admin-apps" className="space-y-4">
          {loading ? (
            <LoadingSpinner className="py-10" />
          ) : adminApps.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">No role applications found.</p>
          ) : (
            adminApps.map((app) => (
              <AdminApplicationCard
                key={app.id}
                app={app}
                canReview={canReviewAdmin}
                onReview={async (status) => {
                  await reviewAdminAppMutation.mutateAsync({ id: app.id, status });
                }}
              />
            ))
          )}
        </TabsContent>

        <TabsContent value="project-proposals" className="space-y-4">
          {loading ? (
            <LoadingSpinner className="py-10" />
          ) : proposals.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">No project proposals found.</p>
          ) : (
            proposals.map((proposal) => (
              <ProjectProposalCard
                key={proposal.id}
                proposal={proposal}
                canReview={canReviewProposals}
                onReview={async (status) => {
                  await reviewProposalMutation.mutateAsync({ id: proposal.id, status });
                }}
              />
            ))
          )}
        </TabsContent>
      </Tabs>
    </div>
  );
}
