"use client";

import { ChevronLeft, ChevronRight, MoreHorizontal, Search } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
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
import { clientApi } from "@/lib/api-client";
import { useAdminSession } from "@/components/admin-shell";
import { canMutateWallet } from "@/lib/rbac";
import { useWalletWithdrawals } from "@/lib/hooks";
import {
  formatWithdrawalDate,
  shortWalletAddress,
  withdrawalStatusBadge,
} from "./withdrawal-view-utils";

export default function WalletWithdrawalsPage() {
  const session = useAdminSession();
  const canMutate = canMutateWallet(session.effectiveRoles);

  const {
    rows,
    total,
    isLoading,
    error,
    searchInput,
    status,
    limit,
    offset,
    dialogOpen,
    selected,
    targetStatus,
    setSearchInput,
    setStatus,
    setLimit,
    setOffset,
    openReviewDialog,
    closeDialog,
    loadWithdrawals,
  } = useWalletWithdrawals();

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
            <Select value={status} onValueChange={setStatus}>
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
            <Select value={String(limit)} onValueChange={(v) => setLimit(Number(v))}>
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
          {isLoading ? (
            <LoadingSpinner className="py-10" />
          ) : error ? (
            <p className="py-8 text-center text-sm text-destructive">{error}</p>
          ) : rows.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">
              No withdrawal requests found.
            </p>
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
                          <p className="font-medium">
                            {row.requester.displayName ?? row.requester.email}
                          </p>
                          <p className="text-xs text-muted-foreground">
                            {row.requester.email}
                          </p>
                        </div>
                      </TableCell>
                      <TableCell>{withdrawalStatusBadge(row.status)}</TableCell>
                      <TableCell>
                        <p className="font-medium">{row.amount}</p>
                        <p className="text-xs text-muted-foreground">Fee {row.feeAmount}</p>
                      </TableCell>
                      <TableCell className="text-sm text-muted-foreground">
                        {shortWalletAddress(row.toAddress)}
                      </TableCell>
                      <TableCell className="text-right text-sm text-muted-foreground">
                        {formatWithdrawalDate(row.requestedAt)}
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
                              <DropdownMenuItem
                                onClick={() => openReviewDialog(row, "approved")}
                              >
                                Approve
                              </DropdownMenuItem>
                              <DropdownMenuItem
                                className="text-destructive"
                                onClick={() => openReviewDialog(row, "rejected")}
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
              Showing {rows.length === 0 ? 0 : offset + 1}-
              {Math.min(offset + rows.length, total)} of {total}
            </p>
            <div className="flex gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={offset === 0 || isLoading}
                onClick={() => setOffset(Math.max(offset - limit, 0))}
              >
                <ChevronLeft className="h-4 w-4" />
                Prev
              </Button>
              <Button
                variant="outline"
                size="sm"
                disabled={offset + limit >= total || isLoading}
                onClick={() => setOffset(offset + limit)}
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
        onOpenChange={closeDialog}
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
          await loadWithdrawals();
        }}
      />
    </div>
  );
}
