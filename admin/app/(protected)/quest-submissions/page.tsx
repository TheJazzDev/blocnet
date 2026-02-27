"use client";

import { useAdminSession } from "@/components/admin-shell";
import { apiFetch } from "@/lib/api-client";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { FormEvent, useEffect, useState } from "react";
import {
  AlertCircle,
  CheckCircle2,
  Clock,
  ExternalLink,
  Loader2,
  XCircle,
  Award,
  Eye,
} from "lucide-react";

interface QuestSubmission {
  id: string;
  userId: string;
  questId: string;
  status: string;
  proofUrl: string | null;
  proofText: string | null;
  screenshotUrl: string | null;
  reviewedBy: string | null;
  reviewNotes: string | null;
  submittedAt: string;
  reviewedAt: string | null;
  user: {
    id: string;
    email: string;
    displayName: string | null;
    avatarUrl: string | null;
  };
  quest: {
    id: string;
    slug: string;
    title: string;
    description: string;
    type: string;
    category: string;
    rewardPoints: number;
    rewardBadge: {
      id: string;
      name: string;
      imageUrl: string;
    } | null;
    requiredProof: string | null;
  };
}

type StatusFilter = "all" | "pending" | "approved" | "rejected";

function formatDateTime(dateString: string | null): string {
  if (!dateString) return "—";
  try {
    return new Date(dateString).toLocaleString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return "Invalid Date";
  }
}

function formatRelativeTime(dateString: string): string {
  try {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMins / 60);
    const diffDays = Math.floor(diffHours / 24);

    if (diffMins < 1) return "Just now";
    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    if (diffDays < 7) return `${diffDays}d ago`;
    return formatDateTime(dateString);
  } catch {
    return "Invalid Date";
  }
}

export default function QuestSubmissionsPage() {
  const session = useAdminSession();
  const [submissions, setSubmissions] = useState<QuestSubmission[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("pending");

  const [reviewOpen, setReviewOpen] = useState(false);
  const [selectedSubmission, setSelectedSubmission] = useState<QuestSubmission | null>(null);
  const [reviewNotes, setReviewNotes] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [reviewError, setReviewError] = useState<string | null>(null);

  const canReviewSubmissions =
    session.effectiveRoles.includes("owner") || session.effectiveRoles.includes("admin");

  useEffect(() => {
    if (canReviewSubmissions) {
      fetchSubmissions();
    }
  }, [statusFilter, canReviewSubmissions]);

  async function fetchSubmissions() {
    setIsLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams();
      if (statusFilter !== "all") {
        params.append("status", statusFilter);
      }
      const url = `/admin/quests/submissions${params.toString() ? `?${params.toString()}` : ""}`;
      const data = await apiFetch<QuestSubmission[]>(url);
      setSubmissions(data ?? []);
    } catch (err: unknown) {
      console.error("Error fetching submissions:", err);
      setError(err instanceof Error ? err.message : "Failed to load submissions");
    } finally {
      setIsLoading(false);
    }
  }

  function openReview(submission: QuestSubmission) {
    setSelectedSubmission(submission);
    setReviewNotes(submission.reviewNotes ?? "");
    setReviewError(null);
    setReviewOpen(true);
  }

  async function handleApprove(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!selectedSubmission) return;

    setIsSubmitting(true);
    setReviewError(null);
    try {
      await apiFetch(`/admin/quests/submissions/${selectedSubmission.id}/approve`, {
        method: "POST",
        body: JSON.stringify({ reviewNotes }),
      });
      setReviewOpen(false);
      setSelectedSubmission(null);
      setReviewNotes("");
      void fetchSubmissions();
    } catch (err: unknown) {
      setReviewError(
        err instanceof Error ? err.message : "Failed to approve submission",
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleReject(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!selectedSubmission) return;

    if (!reviewNotes.trim()) {
      setReviewError("Please provide a reason for rejection");
      return;
    }

    setIsSubmitting(true);
    setReviewError(null);
    try {
      await apiFetch(`/admin/quests/submissions/${selectedSubmission.id}/reject`, {
        method: "POST",
        body: JSON.stringify({ reviewNotes }),
      });
      setReviewOpen(false);
      setSelectedSubmission(null);
      setReviewNotes("");
      void fetchSubmissions();
    } catch (err: unknown) {
      setReviewError(
        err instanceof Error ? err.message : "Failed to reject submission",
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  if (!canReviewSubmissions) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="rounded-lg border border-red-200 bg-red-50 p-6">
          <p className="text-sm text-red-800">
            You do not have permission to review quest submissions.
          </p>
        </div>
      </div>
    );
  }

  const pendingCount = submissions.filter((s) => s.status === "pending").length;

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold tracking-tight">Quest Submissions</h1>
          <p className="text-sm sm:text-base text-muted-foreground mt-1">
            Review and verify user quest completions
          </p>
        </div>
        {pendingCount > 0 && (
          <div className="inline-flex items-center gap-2 rounded-lg bg-orange-50 px-3 py-2 text-sm font-medium text-orange-700 ring-1 ring-inset ring-orange-700/10">
            <Clock className="h-4 w-4" />
            {pendingCount} pending review
          </div>
        )}
      </div>

      {/* Status Filter */}
      <div className="flex gap-2 flex-wrap">
        <Button
          variant={statusFilter === "all" ? "default" : "outline"}
          size="sm"
          onClick={() => setStatusFilter("all")}
        >
          All
        </Button>
        <Button
          variant={statusFilter === "pending" ? "default" : "outline"}
          size="sm"
          onClick={() => setStatusFilter("pending")}
        >
          <Clock className="h-4 w-4 mr-2" />
          Pending
        </Button>
        <Button
          variant={statusFilter === "approved" ? "default" : "outline"}
          size="sm"
          onClick={() => setStatusFilter("approved")}
        >
          <CheckCircle2 className="h-4 w-4 mr-2" />
          Approved
        </Button>
        <Button
          variant={statusFilter === "rejected" ? "default" : "outline"}
          size="sm"
          onClick={() => setStatusFilter("rejected")}
        >
          <XCircle className="h-4 w-4 mr-2" />
          Rejected
        </Button>
      </div>

      {error && (
        <div className="rounded-lg border border-red-200 bg-red-50 p-4">
          <div className="flex items-start gap-3">
            <AlertCircle className="h-5 w-5 shrink-0 text-red-600" />
            <p className="text-sm text-red-800">{error}</p>
          </div>
        </div>
      )}

      {isLoading ? (
        <div className="flex items-center justify-center py-12">
          <Loader2 className="h-6 w-6 animate-spin text-primary" />
        </div>
      ) : (
        <div className="rounded-lg border bg-card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>User</TableHead>
                <TableHead>Quest</TableHead>
                <TableHead className="hidden lg:table-cell">Rewards</TableHead>
                <TableHead className="hidden md:table-cell">Submitted</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {submissions.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} className="text-center py-8 text-muted-foreground">
                    {statusFilter === "pending"
                      ? "No pending submissions to review."
                      : "No submissions found."}
                  </TableCell>
                </TableRow>
              ) : (
                submissions.map((submission) => (
                  <TableRow key={submission.id}>
                    <TableCell>
                      <div className="flex items-center gap-3">
                        {submission.user.avatarUrl ? (
                          <img
                            src={submission.user.avatarUrl}
                            alt={submission.user.displayName ?? "User"}
                            className="h-8 w-8 rounded-full object-cover"
                          />
                        ) : (
                          <div className="h-8 w-8 rounded-full bg-gradient-to-br from-primary to-teal-400 flex items-center justify-center text-white text-xs font-bold">
                            {(submission.user.displayName ?? submission.user.email)[0].toUpperCase()}
                          </div>
                        )}
                        <div className="space-y-0.5">
                          <p className="text-sm font-medium">
                            {submission.user.displayName ?? "User"}
                          </p>
                          <p className="text-xs text-muted-foreground">{submission.user.email}</p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="space-y-1">
                        <p className="text-sm font-medium">{submission.quest.title}</p>
                        <span className="inline-flex items-center rounded-md bg-purple-50 px-2 py-0.5 text-xs font-medium text-purple-700 ring-1 ring-inset ring-purple-700/10">
                          {submission.quest.type.replace("_", " ")}
                        </span>
                      </div>
                    </TableCell>
                    <TableCell className="hidden lg:table-cell">
                      <div className="flex flex-col gap-1">
                        {submission.quest.rewardPoints > 0 && (
                          <span className="text-xs text-muted-foreground">
                            {submission.quest.rewardPoints} pts
                          </span>
                        )}
                        {submission.quest.rewardBadge && (
                          <div className="flex items-center gap-1">
                            <Award className="h-3 w-3 text-yellow-600" />
                            <span className="text-xs text-muted-foreground">
                              {submission.quest.rewardBadge.name}
                            </span>
                          </div>
                        )}
                      </div>
                    </TableCell>
                    <TableCell className="hidden md:table-cell">
                      <span className="text-xs text-muted-foreground">
                        {formatRelativeTime(submission.submittedAt)}
                      </span>
                    </TableCell>
                    <TableCell>
                      {submission.status === "pending" && (
                        <span className="inline-flex items-center gap-1 rounded-md bg-orange-50 px-2 py-1 text-xs font-medium text-orange-700 ring-1 ring-inset ring-orange-700/10">
                          <Clock className="h-3 w-3" />
                          Pending
                        </span>
                      )}
                      {submission.status === "approved" && (
                        <span className="inline-flex items-center gap-1 rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-700/10">
                          <CheckCircle2 className="h-3 w-3" />
                          Approved
                        </span>
                      )}
                      {submission.status === "rejected" && (
                        <span className="inline-flex items-center gap-1 rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-700/10">
                          <XCircle className="h-3 w-3" />
                          Rejected
                        </span>
                      )}
                    </TableCell>
                    <TableCell className="text-right">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => openReview(submission)}
                        className="gap-2"
                      >
                        <Eye className="h-4 w-4" />
                        <span className="hidden sm:inline">Review</span>
                      </Button>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </div>
      )}

      {/* Review Dialog */}
      <Dialog
        open={reviewOpen}
        onOpenChange={(nextOpen) => {
          setReviewOpen(nextOpen);
          if (!nextOpen) {
            setSelectedSubmission(null);
            setReviewNotes("");
            setReviewError(null);
          }
        }}
      >
        <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Review Quest Submission</DialogTitle>
            <DialogDescription>
              Verify the user&apos;s proof and approve or reject their submission.
            </DialogDescription>
          </DialogHeader>
          {selectedSubmission && (
            <div className="space-y-6 py-4">
              {/* User Info */}
              <div className="rounded-lg border bg-muted/50 p-4">
                <h3 className="text-sm font-semibold mb-3">User Information</h3>
                <div className="flex items-center gap-3">
                  {selectedSubmission.user.avatarUrl ? (
                    <img
                      src={selectedSubmission.user.avatarUrl}
                      alt={selectedSubmission.user.displayName ?? "User"}
                      className="h-12 w-12 rounded-full object-cover"
                    />
                  ) : (
                    <div className="h-12 w-12 rounded-full bg-gradient-to-br from-primary to-teal-400 flex items-center justify-center text-white font-bold">
                      {(selectedSubmission.user.displayName ?? selectedSubmission.user.email)[0].toUpperCase()}
                    </div>
                  )}
                  <div>
                    <p className="font-medium">
                      {selectedSubmission.user.displayName ?? "User"}
                    </p>
                    <p className="text-sm text-muted-foreground">
                      {selectedSubmission.user.email}
                    </p>
                  </div>
                </div>
              </div>

              {/* Quest Info */}
              <div className="rounded-lg border bg-muted/50 p-4">
                <h3 className="text-sm font-semibold mb-3">Quest Details</h3>
                <div className="space-y-2">
                  <p className="font-medium">{selectedSubmission.quest.title}</p>
                  <p className="text-sm text-muted-foreground">
                    {selectedSubmission.quest.description}
                  </p>
                  <div className="flex flex-wrap gap-2 mt-3">
                    <span className="inline-flex items-center rounded-md bg-purple-50 px-2 py-1 text-xs font-medium text-purple-700 ring-1 ring-inset ring-purple-700/10">
                      {selectedSubmission.quest.type.replace("_", " ")}
                    </span>
                    <span className="inline-flex items-center rounded-md bg-blue-50 px-2 py-1 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-700/10">
                      {selectedSubmission.quest.category}
                    </span>
                    {selectedSubmission.quest.rewardPoints > 0 && (
                      <span className="inline-flex items-center rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-700/10">
                        {selectedSubmission.quest.rewardPoints} points
                      </span>
                    )}
                    {selectedSubmission.quest.rewardBadge && (
                      <span className="inline-flex items-center gap-1 rounded-md bg-yellow-50 px-2 py-1 text-xs font-medium text-yellow-700 ring-1 ring-inset ring-yellow-700/10">
                        <Award className="h-3 w-3" />
                        {selectedSubmission.quest.rewardBadge.name}
                      </span>
                    )}
                  </div>
                  {selectedSubmission.quest.requiredProof && (
                    <div className="mt-3 text-sm">
                      <span className="font-medium">Required Proof: </span>
                      <span className="text-muted-foreground">
                        {selectedSubmission.quest.requiredProof}
                      </span>
                    </div>
                  )}
                </div>
              </div>

              {/* Submitted Proof */}
              <div className="rounded-lg border bg-muted/50 p-4">
                <h3 className="text-sm font-semibold mb-3">Submitted Proof</h3>
                <div className="space-y-3">
                  {selectedSubmission.proofUrl && (
                    <div>
                      <p className="text-xs font-medium text-muted-foreground mb-1">Proof URL</p>
                      <a
                        href={selectedSubmission.proofUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-sm text-primary hover:underline flex items-center gap-1"
                      >
                        {selectedSubmission.proofUrl}
                        <ExternalLink className="h-3 w-3" />
                      </a>
                    </div>
                  )}
                  {selectedSubmission.proofText && (
                    <div>
                      <p className="text-xs font-medium text-muted-foreground mb-1">Proof Text</p>
                      <p className="text-sm">{selectedSubmission.proofText}</p>
                    </div>
                  )}
                  {selectedSubmission.screenshotUrl && (
                    <div>
                      <p className="text-xs font-medium text-muted-foreground mb-1">Screenshot</p>
                      <a
                        href={selectedSubmission.screenshotUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="block"
                      >
                        <img
                          src={selectedSubmission.screenshotUrl}
                          alt="Proof screenshot"
                          className="rounded-lg border max-w-full max-h-96 object-contain"
                        />
                      </a>
                    </div>
                  )}
                  {!selectedSubmission.proofUrl &&
                    !selectedSubmission.proofText &&
                    !selectedSubmission.screenshotUrl && (
                      <p className="text-sm text-muted-foreground">No proof provided</p>
                    )}
                </div>
              </div>

              {/* Submission Timeline */}
              <div className="rounded-lg border bg-muted/50 p-4">
                <h3 className="text-sm font-semibold mb-3">Timeline</h3>
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Submitted:</span>
                    <span className="font-medium">
                      {formatDateTime(selectedSubmission.submittedAt)}
                    </span>
                  </div>
                  {selectedSubmission.reviewedAt && (
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Reviewed:</span>
                      <span className="font-medium">
                        {formatDateTime(selectedSubmission.reviewedAt)}
                      </span>
                    </div>
                  )}
                  {selectedSubmission.reviewNotes && (
                    <div className="mt-2 pt-2 border-t">
                      <p className="text-xs font-medium text-muted-foreground mb-1">
                        Previous Review Notes
                      </p>
                      <p className="text-sm">{selectedSubmission.reviewNotes}</p>
                    </div>
                  )}
                </div>
              </div>

              {/* Review Notes */}
              {selectedSubmission.status === "pending" && (
                <form className="space-y-4">
                  <div className="grid gap-2">
                    <Label htmlFor="review-notes">Review Notes (Optional for approval, required for rejection)</Label>
                    <Textarea
                      id="review-notes"
                      value={reviewNotes}
                      onChange={(e) => setReviewNotes(e.target.value)}
                      placeholder="Add notes about this review..."
                      rows={3}
                    />
                  </div>
                  {reviewError && (
                    <div className="rounded-lg border border-red-200 bg-red-50 p-3">
                      <p className="text-sm text-red-700">{reviewError}</p>
                    </div>
                  )}
                  <DialogFooter className="gap-2">
                    <Button
                      type="button"
                      variant="outline"
                      onClick={() => {
                        setReviewOpen(false);
                        setSelectedSubmission(null);
                        setReviewNotes("");
                      }}
                      disabled={isSubmitting}
                    >
                      Cancel
                    </Button>
                    <Button
                      type="button"
                      variant="destructive"
                      onClick={(e) => handleReject(e as unknown as FormEvent<HTMLFormElement>)}
                      disabled={isSubmitting}
                      className="gap-2"
                    >
                      {isSubmitting ? (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      ) : (
                        <XCircle className="h-4 w-4" />
                      )}
                      Reject
                    </Button>
                    <Button
                      type="button"
                      onClick={(e) => handleApprove(e as unknown as FormEvent<HTMLFormElement>)}
                      disabled={isSubmitting}
                      className="gap-2"
                    >
                      {isSubmitting ? (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      ) : (
                        <CheckCircle2 className="h-4 w-4" />
                      )}
                      Approve
                    </Button>
                  </DialogFooter>
                </form>
              )}

              {selectedSubmission.status !== "pending" && (
                <DialogFooter>
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => {
                      setReviewOpen(false);
                      setSelectedSubmission(null);
                      setReviewNotes("");
                    }}
                  >
                    Close
                  </Button>
                </DialogFooter>
              )}
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
