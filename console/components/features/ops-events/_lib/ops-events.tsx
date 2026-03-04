import Link from "next/link";
import { ExternalLink } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import type {
  OpsEventProvider,
  OpsEventSource,
  OpsEventStatus,
} from "@/lib/api-client";

export const PAGE_SIZE = 50;

export const SOURCE_OPTIONS: Array<{
  value: "all" | OpsEventSource;
  label: string;
}> = [
  { value: "all", label: "All sources" },
  { value: "email", label: "Email" },
  { value: "wallet", label: "Wallet" },
  { value: "tips", label: "Tips" },
  { value: "social", label: "Social" },
  { value: "auth", label: "Auth" },
  { value: "notifications", label: "Notifications" },
  { value: "system", label: "System" },
];

export const PROVIDER_OPTIONS: Array<{
  value: "all" | OpsEventProvider;
  label: string;
}> = [
  { value: "all", label: "All providers" },
  { value: "resend", label: "Resend" },
  { value: "supabase", label: "Supabase" },
  { value: "turnkey", label: "Turnkey" },
  { value: "bsc", label: "BSC" },
  { value: "x", label: "X" },
  { value: "instagram", label: "Instagram" },
  { value: "tiktok", label: "TikTok" },
  { value: "youtube", label: "YouTube" },
  { value: "linkedin", label: "LinkedIn" },
  { value: "discord", label: "Discord" },
  { value: "telegram", label: "Telegram" },
  { value: "internal", label: "Internal" },
  { value: "unknown", label: "Unknown" },
];

export const STATUS_OPTIONS: Array<{
  value: "all" | OpsEventStatus;
  label: string;
}> = [
  { value: "all", label: "All statuses" },
  { value: "success", label: "Success" },
  { value: "warning", label: "Warning" },
  { value: "error", label: "Error" },
  { value: "info", label: "Info" },
];

export function statusBadge(status: OpsEventStatus) {
  switch (status) {
    case "success":
      return <Badge className="bg-emerald-500/15 text-emerald-300">Success</Badge>;
    case "warning":
      return <Badge className="bg-amber-500/15 text-amber-300">Warning</Badge>;
    case "error":
      return <Badge variant="destructive">Error</Badge>;
    default:
      return <Badge variant="secondary">Info</Badge>;
  }
}

export function formatDateTime(value: string) {
  return new Date(value).toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
}

export function providerDashboardLink(provider: OpsEventProvider) {
  if (provider === "resend") {
    return { label: "Resend Dashboard", href: "https://resend.com/emails" };
  }
  if (provider === "supabase") {
    return { label: "Supabase Dashboard", href: "https://supabase.com/dashboard" };
  }
  if (provider === "x") {
    return { label: "X Analytics", href: "https://analytics.twitter.com" };
  }
  if (provider === "instagram") {
    return { label: "Instagram Insights", href: "https://business.instagram.com" };
  }
  if (provider === "tiktok") {
    return { label: "TikTok Analytics", href: "https://www.tiktok.com/analytics" };
  }
  if (provider === "youtube") {
    return { label: "YouTube Studio", href: "https://studio.youtube.com" };
  }
  if (provider === "linkedin") {
    return { label: "LinkedIn Analytics", href: "https://www.linkedin.com/analytics/" };
  }
  return null;
}

export function compactMetadata(metadata: Record<string, unknown>) {
  const txHash = typeof metadata.txHash === "string" ? metadata.txHash : null;
  if (txHash && txHash.trim().length > 0) {
    return `txHash: ${txHash}`;
  }
  const to = typeof metadata.to === "string" ? metadata.to : null;
  if (to && to.trim().length > 0) {
    return `to: ${to}`;
  }
  const statusCode =
    typeof metadata.statusCode === "number" || typeof metadata.statusCode === "string"
      ? `statusCode: ${String(metadata.statusCode)}`
      : null;
  if (statusCode) return statusCode;
  return null;
}

export function ProviderLinkButton({ label, href }: { label: string; href: string }) {
  return (
    <Link href={href} target="_blank" rel="noreferrer" className="inline-flex items-center gap-2 rounded-md px-3 py-2 text-sm hover:bg-muted">
      {label}
      <ExternalLink className="h-4 w-4" />
    </Link>
  );
}
