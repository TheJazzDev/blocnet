"use client";

import { useEffect, useState } from "react";
import {
  ChevronLeft,
  ChevronRight,
  MoreHorizontal,
  Search,
} from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { ModerationDialog } from "@/components/moderation-dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
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
  type AdminWalletWithdrawal,
  type WalletWithdrawalStatus,
} from "@/lib/api-client";
import { useAdminSession } from "@/components/admin-shell";
import { canMutateWallet } from "@/lib/rbac";

type StatusFilter = "all" | WalletWithdrawalStatus;

function statusBadge(status: WalletWithdrawalStatus) {
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

function shortAddress(address: string) {
  if (address.length < 14) return address;
  return `${address.slice(0, 8)}...${address.slice(-6)}`;
}

function formatDate(dateStr: string | null) {
  if (!dateStr) return "—";
  return new Date(dateStr).toLocaleString();
}

export default function WalletWithdrawalsPage() {
  const session = useAdminSession();
  const canMutate = canMutateWallet(session.effectiveRoles);

  const [rows, setRows] = useState<AdminWalletWithdrawal[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [searchInput, setSearchInput] = useState("");
  const [q, setQ] = useState("");
  const [status, setStatus] = useState<StatusFilter>("all");
  const [limit, setLimit] = useState(25);
  const [offset, setOffset] = useState(0);

  const [dialogOpen, setDialogOpen] = useState(false);
  const [selected, setSelected] = useState<AdminWalletWithdrawal | null>(null);
  const [targetStatus, setTargetStatus] = useState<"approved" | "rejected">("approved");

  useEffect(() => {
    const timer = setTimeout(() => {
      setQ(searchInput.trim());
      setOffset(0);
    }, 300);
    return () => clearTimeout(timer);
  }, [searchInput]);

  function load() {
    setLoading(true);
    setError(null);
    clientApi
      .listWalletWithdrawals({
        q,
        status: status === "all" ? undefined : status,
        limit,
        offset,
      })
      .then((result) => {
        setRows(result.data);
        setTotal(result.total);
      })
      .catch((e: unknown) => {
        setRows([]);
        setTotal(0);
        setError(e instanceof Error ? e.message : "Failed to load withdrawals");
      })
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q, status, limit, offset]);

  function openReview(row: AdminWalletWithdrawal, nextStatus: "approved" | "rejected") {
    setSelected(row);
    setTargetStatus(nextStatus);
    setDialogOpen(true);
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Withdrawal Queue"
        description="Review and manage queued external withdrawals."
      />

      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Requests</CardTitle>
          <div className="mt-3 flex flex-col gap-3 md:flex-row">
            <div className="relative flex-1">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
                className="pl-9"
                placeholder="Search by user, request id, tx hash, or destination address"
              />
            </div>
            <Select
              value={status}
              onValueChange={(next) => {
                setStatus(next as StatusFilter);
                setOffset(0);
              }}
            >
              <SelectTrigger className="w-full md:w-[180px]">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All statuses</SelectItem>
                <SelectItem value="pending_review">Pending review</SelectItem>
                <SelectItem value="approved">Approved</SelectItem>
                <SelectItem value="rejected">Rejected</SelectItem>
                <SelectItem value="broadcasting">Broadcasting</SelectItem>
                <SelectItem value="confirmed">Confirmed</SelectItem>
                <SelectItem value="failed">Failed</SelectItem>
              </SelectContent>
            </Select>
            <Select
              value={String(limit)}
              onValueChange={(next) => {
                setLimit(Number(next));
                setOffset(0);
              }}
            >
              <SelectTrigger className="w-full md:w-[120px]">
                <SelectValue placeholder="Size" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="25">25</SelectItem>
                <SelectItem value="50">50</SelectItem>
                <SelectItem value="100">100</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent>
          {loading ? (
            <LoadingSpinner className="py-10" />
          ) : error ? (
            <p className="py-8 text-center text-sm text-destructive">{error}</p>
          ) : rows.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">No withdrawal requests found.</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Requester</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Amount</TableHead>
                  <TableHead>Destination</TableHead>
                  <TableHead className="text-right">Requested</TableHead>
                  <TableHead className="w-[40px]" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {rows.map((row) => {
                  const canReview =
                    canMutate &&
                    (row.status === "pending_review" || row.status === "requested");
                  return (
                    <TableRow key={row.id}>
                      <TableCell>
                        <div className="space-y-0.5">
                          <p className="font-medium">{row.requester.displayName ?? row.requester.email}</p>
                          <p className="text-xs text-muted-foreground">{row.requester.email}</p>
                        </div>
                      </TableCell>
                      <TableCell>{statusBadge(row.status)}</TableCell>
                      <TableCell>
                        <p className="font-medium">{row.amount}</p>
                        <p className="text-xs text-muted-foreground">Fee {row.feeAmount}</p>
                      </TableCell>
                      <TableCell className="text-sm text-muted-foreground">{shortAddress(row.toAddress)}</TableCell>
                      <TableCell className="text-right text-sm text-muted-foreground">
                        {formatDate(row.requestedAt)}
                      </TableCell>
                      <TableCell>
                        {canReview ? (
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" size="icon" className="h-8 w-8">
                                <MoreHorizontal className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuItem onClick={() => openReview(row, "approved")}>
                                Approve
                              </DropdownMenuItem>
                              <DropdownMenuItem
                                className="text-destructive"
                                onClick={() => openReview(row, "rejected")}
                              >
                                Reject
                              </DropdownMenuItem>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        ) : null}
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          )}

          <div className="mt-4 flex items-center justify-between">
            <p className="text-xs text-muted-foreground">
              Showing {rows.length === 0 ? 0 : offset + 1}-{Math.min(offset + rows.length, total)} of {total}
            </p>
            <div className="flex gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={offset === 0 || loading}
                onClick={() => setOffset((prev) => Math.max(prev - limit, 0))}
              >
                <ChevronLeft className="h-4 w-4" />
                Prev
              </Button>
              <Button
                variant="outline"
                size="sm"
                disabled={offset + limit >= total || loading}
                onClick={() => setOffset((prev) => prev + limit)}
              >
                Next
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      <ModerationDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        title={`Review Withdrawal${selected ? `: ${selected.id}` : ""}`}
        description="All withdrawal approvals and rejections require an audit reason."
        statusOptions={[
          { value: "approved", label: "Approve" },
          { value: "rejected", label: "Reject" },
        ]}
        initialStatus={targetStatus}
        onSubmit={async ({ status: nextStatus, reason }) => {
          if (!selected) return;
          await clientApi.reviewWalletWithdrawal(selected.id, {
            status: nextStatus as "approved" | "rejected",
            reason,
          });
          await load();
        }}
      />
    </div>
  );
}
