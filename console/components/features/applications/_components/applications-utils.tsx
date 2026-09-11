import { CheckCircle2, Clock, XCircle } from "lucide-react";
import { Badge } from "@/components/ui/badge";

export type ApplicationStatus = "pending" | "approved" | "rejected";

export function statusBadge(status: ApplicationStatus) {
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

export function getInitials(name: string | null, fallback: string) {
  return (name ?? fallback)
    .split(/[\s@]/)
    .filter(Boolean)
    .map((w) => w[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}

export function formatDate(date: string) {
  return new Date(date).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}
