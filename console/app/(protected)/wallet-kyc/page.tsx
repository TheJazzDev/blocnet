"use client";

import { useEffect, useState } from "react";
import { ChevronLeft, ChevronRight, Search } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
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
import {
  clientApi,
  type AdminWalletKycRecord,
  type WalletKycStatus,
} from "@/lib/api-client";
import { useAdminSession } from "@/components/admin-shell";
import { canMutateWallet } from "@/lib/rbac";

type StatusFilter = "all" | WalletKycStatus;
type ReviewStatus = "approved" | "rejected";

function kycBadge(status: WalletKycStatus) {
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

function formatDate(dateStr: string | null) {
  if (!dateStr) return "—";
  return new Date(dateStr).toLocaleString();
}

export default function WalletKycPage() {
  const session = useAdminSession();
  const canMutate = canMutateWallet(session.effectiveRoles);

  const [rows, setRows] = useState<AdminWalletKycRecord[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [searchInput, setSearchInput] = useState("");
  const [q, setQ] = useState("");
  const [status, setStatus] = useState<StatusFilter>("all");
  const [limit, setLimit] = useState(25);
  const [offset, setOffset] = useState(0);

  const [dialogOpen, setDialogOpen] = useState(false);
  const [selected, setSelected] = useState<AdminWalletKycRecord | null>(null);
  const [reviewStatus, setReviewStatus] = useState<ReviewStatus>("approved");
  const [tier, setTier] = useState("verified");
  const [note, setNote] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [dialogError, setDialogError] = useState<string | null>(null);

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
      .listWalletKyc({
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
        setError(e instanceof Error ? e.message : "Failed to load KYC records");
      })
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q, status, limit, offset]);

  function openReview(row: AdminWalletKycRecord, nextStatus: ReviewStatus) {
    setSelected(row);
    setReviewStatus(nextStatus);
    setTier(row.tier || "verified");
    setNote("");
    setDialogError(null);
    setDialogOpen(true);
  }

  async function submitReview() {
    if (!selected) return;
    const trimmed = note.trim();
    if (trimmed.length < 3) {
      setDialogError("Review note must be at least 3 characters.");
      return;
    }

    setSubmitting(true);
    setDialogError(null);
    try {
      await clientApi.reviewWalletKyc(selected.userId, {
        status: reviewStatus,
        note: trimmed,
        ...(reviewStatus === "approved" ? { tier } : {}),
      });
      setDialogOpen(false);
      await load();
    } catch (e: unknown) {
      setDialogError(e instanceof Error ? e.message : "Failed to review KYC");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="KYC Reviews"
        description="Review manual KYC submissions and assign risk tiers."
      />

      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Submissions</CardTitle>
          <div className="mt-3 flex flex-col gap-3 md:flex-row">
            <div className="relative flex-1">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
                className="pl-9"
                placeholder="Search by user email, name, or id"
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
                <SelectItem value="pending">Pending</SelectItem>
                <SelectItem value="approved">Approved</SelectItem>
                <SelectItem value="rejected">Rejected</SelectItem>
                <SelectItem value="not_submitted">Not submitted</SelectItem>
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
                {rows.map((row) => {
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
                            <Button size="sm" variant="outline" onClick={() => openReview(row, "approved")}>
                              Approve
                            </Button>
                            <Button
                              size="sm"
                              variant="destructive"
                              onClick={() => openReview(row, "rejected")}
                            >
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

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
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
              <Select value={reviewStatus} onValueChange={(next) => setReviewStatus(next as ReviewStatus)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="approved">Approved</SelectItem>
                  <SelectItem value="rejected">Rejected</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {reviewStatus === "approved" && (
              <div className="space-y-2">
                <Label>Risk Tier</Label>
                <Select value={tier} onValueChange={setTier}>
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
                value={note}
                onChange={(e) => setNote(e.target.value)}
                rows={4}
                placeholder="Provide context for this review decision."
              />
            </div>

            {dialogError && <p className="text-sm text-destructive">{dialogError}</p>}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)} disabled={submitting}>
              Cancel
            </Button>
            <Button onClick={submitReview} disabled={submitting}>
              {submitting ? "Saving..." : "Submit Review"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
