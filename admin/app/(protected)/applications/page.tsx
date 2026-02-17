import { CheckCircle2, XCircle, Clock, Eye, FileText } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { PageHeader } from "@/components/page-header";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Separator } from "@/components/ui/separator";

const mockAdminApplications = [
  {
    id: "1",
    userId: "u1",
    displayName: "Emily Davis",
    email: "emily@example.com",
    targetRole: "admin",
    reason: "I have 5 years of experience in blockchain community management and would love to help moderate content on Blocnet. I currently run a crypto newsletter with 10k subscribers.",
    status: "pending" as const,
    createdAt: "2026-02-15",
  },
  {
    id: "2",
    userId: "u2",
    displayName: "Mike Johnson",
    email: "mike@example.com",
    targetRole: "poster",
    reason: "I'm a blockchain developer working on Ethereum ecosystem projects. I'd like to contribute regular technical updates on DeFi protocols and L2 developments.",
    status: "pending" as const,
    createdAt: "2026-02-14",
  },
  {
    id: "3",
    userId: "u3",
    displayName: "Lisa Wang",
    email: "lisa@example.com",
    targetRole: "poster",
    reason: "I want to post updates about Solana ecosystem developments. I've been active in the community for 2 years.",
    status: "pending" as const,
    createdAt: "2026-02-13",
  },
  {
    id: "4",
    userId: "u4",
    displayName: "James Brown",
    email: "james@example.com",
    targetRole: "admin",
    reason: "Experienced community moderator looking to help manage the platform.",
    status: "approved" as const,
    createdAt: "2026-02-10",
    reviewedAt: "2026-02-11",
  },
  {
    id: "5",
    userId: "u5",
    displayName: "Anna Smith",
    email: "anna@example.com",
    targetRole: "poster",
    reason: "Want to contribute NFT market analysis.",
    status: "rejected" as const,
    createdAt: "2026-02-08",
    reviewedAt: "2026-02-09",
  },
];

const mockProjectProposals = [
  {
    id: "p1",
    applicantName: "Jake Williams",
    applicantEmail: "jake@example.com",
    name: "Chainlink CCIP",
    symbol: "LINK",
    primaryTag: "Oracle",
    description: "Cross-Chain Interoperability Protocol by Chainlink. Enables secure cross-chain messaging and token transfers across blockchain networks.",
    reason: "Chainlink CCIP is becoming a critical piece of infrastructure for cross-chain DeFi.",
    status: "pending" as const,
    createdAt: "2026-02-16",
  },
  {
    id: "p2",
    applicantName: "Maria Garcia",
    applicantEmail: "maria@example.com",
    name: "Eigenlayer",
    symbol: "EIGEN",
    primaryTag: "Infrastructure",
    description: "Restaking protocol built on Ethereum that allows ETH stakers to opt-in to securing additional services.",
    reason: "Eigenlayer is one of the most significant new DeFi primitives in the Ethereum ecosystem.",
    status: "pending" as const,
    createdAt: "2026-02-15",
  },
  {
    id: "p3",
    applicantName: "David Kim",
    applicantEmail: "david@example.com",
    name: "Jupiter",
    symbol: "JUP",
    primaryTag: "DeFi",
    description: "Leading DEX aggregator on Solana ecosystem.",
    status: "approved" as const,
    createdAt: "2026-02-10",
    reviewedAt: "2026-02-11",
  },
];

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

function getInitials(name: string) {
  return name
    .split(" ")
    .map((w) => w[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}

export default function ApplicationsPage() {
  const pendingAdminApps = mockAdminApplications.filter((a) => a.status === "pending");
  const pendingProposals = mockProjectProposals.filter((p) => p.status === "pending");

  return (
    <div className="space-y-6">
      <PageHeader
        title="Applications"
        description="Review admin applications and project proposals."
      >
        <Badge variant="outline" className="border-yellow-500/20 bg-yellow-500/10 text-yellow-500">
          {pendingAdminApps.length + pendingProposals.length} pending
        </Badge>
      </PageHeader>

      <Tabs defaultValue="admin-apps">
        <TabsList>
          <TabsTrigger value="admin-apps">
            Role Applications
            {pendingAdminApps.length > 0 && (
              <Badge variant="secondary" className="ml-2 h-5 w-5 justify-center rounded-full p-0 text-[10px]">
                {pendingAdminApps.length}
              </Badge>
            )}
          </TabsTrigger>
          <TabsTrigger value="project-proposals">
            Project Proposals
            {pendingProposals.length > 0 && (
              <Badge variant="secondary" className="ml-2 h-5 w-5 justify-center rounded-full p-0 text-[10px]">
                {pendingProposals.length}
              </Badge>
            )}
          </TabsTrigger>
        </TabsList>

        {/* Admin Applications Tab */}
        <TabsContent value="admin-apps" className="space-y-4">
          {mockAdminApplications.map((app) => (
            <Card key={app.id}>
              <CardContent className="pt-6">
                <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                  <div className="flex items-start gap-3">
                    <Avatar className="h-10 w-10">
                      <AvatarFallback>{getInitials(app.displayName)}</AvatarFallback>
                    </Avatar>
                    <div className="flex-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <h3 className="font-semibold">{app.displayName}</h3>
                        {statusBadge(app.status)}
                        <Badge variant="secondary">
                          {app.targetRole === "admin" ? "Admin Role" : "Poster Role"}
                        </Badge>
                      </div>
                      <p className="mt-0.5 text-sm text-muted-foreground">{app.email}</p>
                      <p className="mt-3 text-sm leading-relaxed">{app.reason}</p>
                      <p className="mt-2 text-xs text-muted-foreground">Applied {app.createdAt}</p>
                    </div>
                  </div>
                  {app.status === "pending" && (
                    <div className="flex shrink-0 gap-2">
                      <Button size="sm" variant="outline">
                        <Eye className="h-3.5 w-3.5" />
                        Review
                      </Button>
                      <Button size="sm" className="bg-emerald-600 hover:bg-emerald-700">
                        <CheckCircle2 className="h-3.5 w-3.5" />
                        Approve
                      </Button>
                      <Button size="sm" variant="destructive">
                        <XCircle className="h-3.5 w-3.5" />
                        Reject
                      </Button>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </TabsContent>

        {/* Project Proposals Tab */}
        <TabsContent value="project-proposals" className="space-y-4">
          {mockProjectProposals.map((proposal) => (
            <Card key={proposal.id}>
              <CardContent className="pt-6">
                <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                  <div className="flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-secondary text-xs font-bold">
                        {proposal.symbol?.slice(0, 3)}
                      </div>
                      <h3 className="font-semibold">{proposal.name}</h3>
                      {statusBadge(proposal.status)}
                      <Badge variant="secondary">{proposal.primaryTag}</Badge>
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
                          {getInitials(proposal.applicantName)}
                        </AvatarFallback>
                      </Avatar>
                      <span>Proposed by {proposal.applicantName}</span>
                      <span>&middot;</span>
                      <span>{proposal.createdAt}</span>
                    </div>
                  </div>
                  {proposal.status === "pending" && (
                    <div className="flex shrink-0 gap-2">
                      <Button size="sm" className="bg-emerald-600 hover:bg-emerald-700">
                        <CheckCircle2 className="h-3.5 w-3.5" />
                        Approve
                      </Button>
                      <Button size="sm" variant="destructive">
                        <XCircle className="h-3.5 w-3.5" />
                        Reject
                      </Button>
                    </div>
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
