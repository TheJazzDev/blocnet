import { Badge } from "@/components/ui/badge";
import type { WalletKycStatus } from "@/lib/api-client";

export type StatusFilter = "all" | WalletKycStatus;
export type ReviewStatus = "approved" | "rejected";

export function kycBadge(status: WalletKycStatus) {
  switch (status) {
    case "approved":
      return <Badge className="bg-emerald-500/15 text-emerald-300">Approved</Badge>;
    case "pending":
      return <Badge className="bg-amber-500/15 text-amber-300">Pending</Badge>;
    case "rejected":
      return <Badge className="bg-red-500/15 text-red-300">Rejected</Badge>;
    case "not_submitted":
      return <Badge variant="secondary">Not Submitted</Badge>;
  }
}

export function formatDate(value: string | null) {
  if (!value) return "—";
  return new Date(value).toLocaleString();
}
