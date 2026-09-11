"use client";

import { Button } from "@/components/ui/button";
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
import type { ReviewStatus } from "../_lib/wallet-kyc";

type KycReviewDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  reviewStatus: ReviewStatus;
  setReviewStatus: (status: ReviewStatus) => void;
  tier: string;
  setTier: (tier: string) => void;
  note: string;
  setNote: (note: string) => void;
  error: string | null;
  submitting: boolean;
  onSubmit: () => void;
};

export function KycReviewDialog({
  open,
  onOpenChange,
  reviewStatus,
  setReviewStatus,
  tier,
  setTier,
  note,
  setNote,
  error,
  submitting,
  onSubmit,
}: KycReviewDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
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

          {error && <p className="text-sm text-destructive">{error}</p>}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button onClick={onSubmit} disabled={submitting}>
            {submitting ? "Saving..." : "Submit Review"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
