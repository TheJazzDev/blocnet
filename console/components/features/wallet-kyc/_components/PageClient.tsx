"use client";

import { ChevronLeft, ChevronRight, Search } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
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
import { useAdminSession } from "@/components/admin-shell";
import { canMutateWallet } from "@/lib/rbac";
import { formatDate, kycBadge, type ReviewStatus, type StatusFilter } from "../_lib/wallet-kyc";
import { useWalletKycAdmin } from "../_hooks/use-wallet-kyc-admin";

export default function WalletKycPageClient() {
  const session = useAdminSession();
  const canMutate = canMutateWallet(session.effectiveRoles);
  const state = useWalletKycAdmin();

  return (
    <div className="space-y-6">
      <PageHeader title="KYC Reviews" description="Review manual KYC submissions and assign risk tiers." />

      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Submissions</CardTitle>
          <div className="mt-3 flex flex-col gap-3 md:flex-row">
            <div className="relative flex-1">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={state.searchInput}
                onChange={(e) => state.setSearchInput(e.target.value)}
                className="pl-9"
                placeholder="Search by user email, name, or id"
              />
            </div>
            <Select
              value={state.status}
              onValueChange={(next) => {
                state.setStatus(next as StatusFilter);
                state.setOffset(0);
              }}
            >
              <SelectTrigger className="w-full md:w-[180px]">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All statuses</SelectItem>
                <SelectItem value="pending">Pending</SelectItem>
                <SelectItem value="approved">Approved</SelectItem>
                <SelectItem value="rejected">Rejected</SelectItem>
                <SelectItem value="not_submitted">Not submitted</SelectItem>
              </SelectContent>
            </Select>
            <Select
              value={String(state.limit)}
              onValueChange={(next) => {
                state.setLimit(Number(next));
                state.setOffset(0);
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
          {state.loading ? (
            <LoadingSpinner className="py-10" />
          ) : state.error ? (
            <p className="py-8 text-center text-sm text-destructive">{state.error}</p>
          ) : state.rows.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">No KYC records found.</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>User</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Tier</TableHead>
                  <TableHead>Submitted</TableHead>
                  <TableHead className="text-right">Review</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {state.rows.map((row) => {
                  const actionable = canMutate && (row.status === "pending" || row.status === "not_submitted");
                  return (
                    <TableRow key={row.id}>
                      <TableCell>
                        <div className="space-y-0.5">
                          <p className="font-medium">{row.user.displayName ?? row.user.email}</p>
                          <p className="text-xs text-muted-foreground">{row.user.email}</p>
                        </div>
                      </TableCell>
                      <TableCell>{kycBadge(row.status)}</TableCell>
                      <TableCell>{row.tier}</TableCell>
                      <TableCell className="text-sm text-muted-foreground">
                        {formatDate(row.submittedAt)}
                      </TableCell>
                      <TableCell className="text-right">
                        {actionable ? (
                          <div className="flex justify-end gap-2">
                            <Button size="sm" variant="outline" onClick={() => state.openReview(row, "approved")}>
                              Approve
                            </Button>
                            <Button size="sm" variant="destructive" onClick={() => state.openReview(row, "rejected")}>
                              Reject
                            </Button>
                          </div>
                        ) : (
                          <span className="text-xs text-muted-foreground">{formatDate(row.reviewedAt)}</span>
                        )}
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          )}

          <div className="mt-4 flex items-center justify-between">
            <p className="text-xs text-muted-foreground">
              Showing {state.rows.length === 0 ? 0 : state.offset + 1}-{Math.min(state.offset + state.rows.length, state.total)} of {state.total}
            </p>
            <div className="flex gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={state.offset === 0 || state.loading}
                onClick={() => state.setOffset((prev) => Math.max(prev - state.limit, 0))}
              >
                <ChevronLeft className="h-4 w-4" />
                Prev
              </Button>
              <Button
                variant="outline"
                size="sm"
                disabled={state.offset + state.limit >= state.total || state.loading}
                onClick={() => state.setOffset((prev) => prev + state.limit)}
              >
                Next
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      <Dialog open={state.dialogOpen} onOpenChange={state.setDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>KYC Review</DialogTitle>
            <DialogDescription>
              Submit a review decision and audit note for this KYC profile.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Status</Label>
              <Select value={state.reviewStatus} onValueChange={(next) => state.setReviewStatus(next as ReviewStatus)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="approved">Approved</SelectItem>
                  <SelectItem value="rejected">Rejected</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {state.reviewStatus === "approved" && (
              <div className="space-y-2">
                <Label>Risk Tier</Label>
                <Select value={state.tier} onValueChange={state.setTier}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="basic">basic</SelectItem>
                    <SelectItem value="verified">verified</SelectItem>
                    <SelectItem value="high_trust">high_trust</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            )}

            <div className="space-y-2">
              <Label>Review note</Label>
              <Textarea
                value={state.note}
                onChange={(e) => state.setNote(e.target.value)}
                rows={4}
                placeholder="Provide context for this review decision."
              />
            </div>

            {state.dialogError && <p className="text-sm text-destructive">{state.dialogError}</p>}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => state.setDialogOpen(false)} disabled={state.submitting}>
              Cancel
            </Button>
            <Button onClick={() => void state.submitReview()} disabled={state.submitting}>
              {state.submitting ? "Saving..." : "Submit Review"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
