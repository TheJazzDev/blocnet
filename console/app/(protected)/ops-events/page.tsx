"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { ExternalLink, Loader2, RefreshCw } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  clientApi,
  type OpsEvent,
  type OpsEventProvider,
  type OpsEventSource,
  type OpsEventStatus,
} from "@/lib/api-client";
import { useAdminSession } from "@/components/admin-shell";
import { canViewOpsEvents } from "@/lib/rbac";

const PAGE_SIZE = 50;

const SOURCE_OPTIONS: Array<{ value: "all" | OpsEventSource; label: string }> = [
  { value: "all", label: "All sources" },
  { value: "email", label: "Email" },
  { value: "wallet", label: "Wallet" },
  { value: "tips", label: "Tips" },
  { value: "social", label: "Social" },
  { value: "auth", label: "Auth" },
  { value: "notifications", label: "Notifications" },
  { value: "system", label: "System" },
];

const PROVIDER_OPTIONS: Array<{ value: "all" | OpsEventProvider; label: string }> = [
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

const STATUS_OPTIONS: Array<{ value: "all" | OpsEventStatus; label: string }> = [
  { value: "all", label: "All statuses" },
  { value: "success", label: "Success" },
  { value: "warning", label: "Warning" },
  { value: "error", label: "Error" },
  { value: "info", label: "Info" },
];

function statusBadge(status: OpsEventStatus) {
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

function formatDateTime(value: string) {
  return new Date(value).toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
}

function providerDashboardLink(provider: OpsEventProvider): { label: string; href: string } | null {
  if (provider === "resend") {
    return {
      label: "Resend Dashboard",
      href: "https://resend.com/emails",
    };
  }
  if (provider === "supabase") {
    return {
      label: "Supabase Dashboard",
      href: "https://supabase.com/dashboard",
    };
  }
  if (provider === "x") {
    return {
      label: "X Analytics",
      href: "https://analytics.twitter.com",
    };
  }
  if (provider === "instagram") {
    return {
      label: "Instagram Insights",
      href: "https://business.instagram.com",
    };
  }
  if (provider === "tiktok") {
    return {
      label: "TikTok Analytics",
      href: "https://www.tiktok.com/analytics",
    };
  }
  if (provider === "youtube") {
    return {
      label: "YouTube Studio",
      href: "https://studio.youtube.com",
    };
  }
  if (provider === "linkedin") {
    return {
      label: "LinkedIn Analytics",
      href: "https://www.linkedin.com/analytics/",
    };
  }
  return null;
}

function compactMetadata(metadata: Record<string, unknown>) {
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
  if (statusCode) {
    return statusCode;
  }
  return null;
}

export default function OpsEventsPage() {
  const session = useAdminSession();
  const canView = canViewOpsEvents(session.effectiveRoles);

  const [events, setEvents] = useState<OpsEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [q, setQ] = useState("");
  const [source, setSource] = useState<"all" | OpsEventSource>("all");
  const [provider, setProvider] = useState<"all" | OpsEventProvider>("all");
  const [status, setStatus] = useState<"all" | OpsEventStatus>("all");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [page, setPage] = useState(0);
  const [hasNext, setHasNext] = useState(false);
  const [autoRefresh, setAutoRefresh] = useState(true);

  const offset = page * PAGE_SIZE;

  async function loadEvents(withSpinner: boolean) {
    if (!canView) {
      setLoading(false);
      return;
    }

    if (withSpinner) {
      setLoading(true);
    } else {
      setRefreshing(true);
    }
    setError(null);

    try {
      const rows = await clientApi.listOpsEvents({
        q: q.trim() || undefined,
        source,
        provider,
        status,
        from: from.trim() || undefined,
        to: to.trim() || undefined,
        limit: PAGE_SIZE,
        offset,
      });
      setEvents(rows);
      setHasNext(rows.length === PAGE_SIZE);
    } catch (e: unknown) {
      setEvents([]);
      setHasNext(false);
      setError(e instanceof Error ? e.message : "Failed to load ops events");
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }

  useEffect(() => {
    void loadEvents(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page]);

  useEffect(() => {
    setPage(0);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [source, provider, status, from, to]);

  useEffect(() => {
    if (!autoRefresh || !canView) return;
    const id = window.setInterval(() => {
      void loadEvents(false);
    }, 15000);
    return () => window.clearInterval(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [autoRefresh, canView, offset, source, provider, status, from, to, q]);

  const providerLinks = useMemo(() => {
    const unique = new Map<OpsEventProvider, { label: string; href: string }>();
    for (const event of events) {
      if (unique.has(event.provider)) continue;
      const link = providerDashboardLink(event.provider);
      if (link) unique.set(event.provider, link);
    }
    return [...unique.values()];
  }, [events]);

  if (!canView) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Ops Events"
          description="Owner-only operational event stream."
        />
        <Card>
          <CardContent className="py-10 text-sm text-muted-foreground">
            Access denied. Owner role is required to view operational events.
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Ops Events"
        description="Cross-system operational stream for email, wallet, tips, social, and auth flows."
      >
        <div className="flex items-center gap-2">
          <Button
            variant={autoRefresh ? "default" : "outline"}
            onClick={() => setAutoRefresh((prev) => !prev)}
          >
            Auto-refresh {autoRefresh ? "On" : "Off"}
          </Button>
          <Button variant="outline" onClick={() => void loadEvents(false)} disabled={refreshing}>
            {refreshing ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <RefreshCw className="h-4 w-4" />
            )}
            Refresh
          </Button>
        </div>
      </PageHeader>

      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Filters</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="grid gap-2 md:grid-cols-2 xl:grid-cols-6">
            <Input
              placeholder="Search action, actor, resource"
              value={q}
              onChange={(event) => setQ(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === "Enter") {
                  setPage(0);
                  void loadEvents(false);
                }
              }}
            />
            <Select
              value={source}
              onValueChange={(value: "all" | OpsEventSource) => setSource(value)}
            >
              <SelectTrigger>
                <SelectValue placeholder="Source" />
              </SelectTrigger>
              <SelectContent>
                {SOURCE_OPTIONS.map((option) => (
                  <SelectItem key={option.value} value={option.value}>
                    {option.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Select
              value={provider}
              onValueChange={(value: "all" | OpsEventProvider) => setProvider(value)}
            >
              <SelectTrigger>
                <SelectValue placeholder="Provider" />
              </SelectTrigger>
              <SelectContent>
                {PROVIDER_OPTIONS.map((option) => (
                  <SelectItem key={option.value} value={option.value}>
                    {option.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Select
              value={status}
              onValueChange={(value: "all" | OpsEventStatus) => setStatus(value)}
            >
              <SelectTrigger>
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                {STATUS_OPTIONS.map((option) => (
                  <SelectItem key={option.value} value={option.value}>
                    {option.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Input
              type="datetime-local"
              value={from}
              onChange={(event) => setFrom(event.target.value)}
            />
            <Input
              type="datetime-local"
              value={to}
              onChange={(event) => setTo(event.target.value)}
            />
          </div>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              onClick={() => {
                setPage(0);
                void loadEvents(false);
              }}
              disabled={refreshing}
            >
              Apply
            </Button>
            <Button
              variant="ghost"
              onClick={() => {
                setQ("");
                setSource("all");
                setProvider("all");
                setStatus("all");
                setFrom("");
                setTo("");
                setPage(0);
              }}
            >
              Reset
            </Button>
            {providerLinks.map((link) => (
              <Button key={link.href} variant="ghost" asChild>
                <Link href={link.href} target="_blank" rel="noreferrer">
                  {link.label}
                  <ExternalLink className="h-4 w-4" />
                </Link>
              </Button>
            ))}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Event Stream</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="py-10 text-center text-sm text-muted-foreground">
              <Loader2 className="mx-auto mb-2 h-4 w-4 animate-spin" />
              Loading events...
            </div>
          ) : error ? (
            <p className="py-10 text-center text-sm text-red-400">{error}</p>
          ) : events.length === 0 ? (
            <p className="py-10 text-center text-sm text-muted-foreground">
              No events found for the selected filters.
            </p>
          ) : (
            <>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Time</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Source</TableHead>
                    <TableHead>Provider</TableHead>
                    <TableHead>Action</TableHead>
                    <TableHead>Summary</TableHead>
                    <TableHead>Actor</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {events.map((event) => {
                    const compact = compactMetadata(event.metadata);
                    return (
                      <TableRow key={event.id}>
                        <TableCell className="whitespace-nowrap text-xs text-muted-foreground">
                          {formatDateTime(event.createdAt)}
                        </TableCell>
                        <TableCell>{statusBadge(event.status)}</TableCell>
                        <TableCell>
                          <Badge variant="secondary">{event.source}</Badge>
                        </TableCell>
                        <TableCell>
                          <Badge variant="outline">{event.provider}</Badge>
                        </TableCell>
                        <TableCell className="font-mono text-xs">{event.action}</TableCell>
                        <TableCell className="max-w-[380px]">
                          <p className="truncate text-sm">{event.summary}</p>
                          {compact ? (
                            <p className="truncate text-xs text-muted-foreground">{compact}</p>
                          ) : null}
                        </TableCell>
                        <TableCell className="text-xs text-muted-foreground">
                          {event.actor?.email ?? event.actor?.displayName ?? "System"}
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
              <div className="mt-3 flex items-center justify-between">
                <p className="text-xs text-muted-foreground">
                  Showing page {page + 1} ({events.length} rows)
                </p>
                <div className="flex items-center gap-2">
                  <Button
                    variant="outline"
                    onClick={() => setPage((prev) => Math.max(prev - 1, 0))}
                    disabled={page === 0}
                  >
                    Previous
                  </Button>
                  <Button
                    variant="outline"
                    onClick={() => setPage((prev) => prev + 1)}
                    disabled={!hasNext}
                  >
                    Next
                  </Button>
                </div>
              </div>
            </>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
