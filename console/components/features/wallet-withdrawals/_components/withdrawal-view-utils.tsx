"use client";

import { Badge } from "@/components/ui/badge";
import type { WalletWithdrawalStatus } from "@/lib/api-client";

export function withdrawalStatusBadge(status: WalletWithdrawalStatus) {
  switch (status) {
    case "pending_review":
      return <Badge className="bg-amber-500/15 text-amber-300">Pending</Badge>;
    case "approved":
      return <Badge className="bg-blue-500/15 text-blue-300">Approved</Badge>;
    case "rejected":
      return <Badge className="bg-red-500/15 text-red-300">Rejected</Badge>;
    case "confirmed":
      return <Badge className="bg-emerald-500/15 text-emerald-300">Confirmed</Badge>;
    case "failed":
      return <Badge className="bg-red-500/15 text-red-300">Failed</Badge>;
    case "broadcasting":
      return <Badge className="bg-indigo-500/15 text-indigo-300">Broadcasting</Badge>;
    case "requested":
      return <Badge variant="secondary">Requested</Badge>;
    case "reverted":
      return <Badge variant="secondary">Reverted</Badge>;
  }
}

export function shortWalletAddress(address: string) {
  if (address.length < 14) return address;
  return `${address.slice(0, 8)}...${address.slice(-6)}`;
}

export function formatWithdrawalDate(dateStr: string | null) {
  if (!dateStr) return "—";
  return new Date(dateStr).toLocaleString();
}
