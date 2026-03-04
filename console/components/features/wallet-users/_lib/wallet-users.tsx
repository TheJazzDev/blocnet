import { Badge } from "@/components/ui/badge";
import type { WalletKycStatus, WalletStatus } from "@/lib/api-client";

export type WalletStatusFilter = "all" | WalletStatus;
export type KycStatusFilter = "all" | WalletKycStatus;

export function walletStatusBadge(status: WalletStatus) {
  switch (status) {
    case "ready":
      return <Badge className="bg-emerald-500/15 text-emerald-300">Ready</Badge>;
    case "provisioning":
      return <Badge className="bg-blue-500/15 text-blue-300">Provisioning</Badge>;
    case "disabled":
      return <Badge variant="secondary">Disabled</Badge>;
    case "error":
      return <Badge className="bg-red-500/15 text-red-300">Error</Badge>;
  }
}

export function kycStatusBadge(status: WalletKycStatus | null) {
  if (!status) return <Badge variant="secondary">N/A</Badge>;
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

export function shortAddress(address: string | null | undefined) {
  if (!address) return "—";
  if (address.length < 14) return address;
  return `${address.slice(0, 8)}...${address.slice(-6)}`;
}
