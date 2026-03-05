'use client';

import { Award, CheckCircle2, ExternalLink, Loader2, XCircle } from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { QuestSubmission, formatDateTime } from './types';

type SubmissionReviewDialogProps = {
  open: boolean;
  selectedSubmission: QuestSubmission | null;
  reviewNotes: string;
  setReviewNotes: (value: string) => void;
  reviewError: string | null;
  isSubmitting: boolean;
  onOpenChange: (open: boolean) => void;
  onClose: () => void;
  onApprove: () => Promise<void>;
  onReject: () => Promise<void>;
  onRevoke: () => Promise<void>;
};

export function SubmissionReviewDialog({
  open,
  selectedSubmission,
  reviewNotes,
  setReviewNotes,
  reviewError,
  isSubmitting,
  onOpenChange,
  onClose,
  onApprove,
  onReject,
  onRevoke,
}: SubmissionReviewDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className='max-w-3xl max-h-[90vh] overflow-y-auto'>
        <DialogHeader>
          <DialogTitle>Review Quest Submission</DialogTitle>
          <DialogDescription>
            Verify the user&apos;s proof and approve or reject their submission.
          </DialogDescription>
        </DialogHeader>

        {selectedSubmission && (
          <div className='space-y-6 py-4'>
            <div className='rounded-lg border bg-muted/50 p-4'>
              <h3 className='text-sm font-semibold mb-3'>User Information</h3>
              <div className='flex items-center gap-3'>
                {selectedSubmission.user.avatarUrl ? (
                  <img
                    src={selectedSubmission.user.avatarUrl}
                    alt={selectedSubmission.user.displayName ?? 'User'}
                    className='h-12 w-12 rounded-full object-cover'
                  />
                ) : (
                  <div className='h-12 w-12 rounded-full bg-gradient-to-br from-primary to-teal-400 flex items-center justify-center text-white font-bold'>
                    {(selectedSubmission.user.displayName ?? selectedSubmission.user.email)[0].toUpperCase()}
                  </div>
                )}
                <div>
                  <p className='font-medium'>{selectedSubmission.user.displayName ?? 'User'}</p>
                  <p className='text-sm text-muted-foreground'>{selectedSubmission.user.email}</p>
                </div>
              </div>
            </div>

            <div className='rounded-lg border bg-muted/50 p-4'>
              <h3 className='text-sm font-semibold mb-3'>Quest Details</h3>
              <div className='space-y-2'>
                <p className='font-medium'>{selectedSubmission.quest.title}</p>
                <p className='text-sm text-muted-foreground'>{selectedSubmission.quest.description}</p>
                <div className='flex flex-wrap gap-2 mt-3'>
                  <span className='inline-flex items-center rounded-md bg-purple-50 px-2 py-1 text-xs font-medium text-purple-700 ring-1 ring-inset ring-purple-700/10'>
                    {selectedSubmission.quest.type.replace('_', ' ')}
                  </span>
                  <span className='inline-flex items-center rounded-md bg-blue-50 px-2 py-1 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-700/10'>
                    {selectedSubmission.quest.category}
                  </span>
                  {selectedSubmission.quest.rewardPoints > 0 && (
                    <span className='inline-flex items-center rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-700/10'>
                      {selectedSubmission.quest.rewardPoints} points
                    </span>
                  )}
                  {selectedSubmission.quest.rewardBadge && (
                    <span className='inline-flex items-center gap-1 rounded-md bg-yellow-50 px-2 py-1 text-xs font-medium text-yellow-700 ring-1 ring-inset ring-yellow-700/10'>
                      <Award className='h-3 w-3' />
                      {selectedSubmission.quest.rewardBadge.name}
                    </span>
                  )}
                </div>
                {selectedSubmission.quest.requiredProof && (
                  <div className='mt-3 text-sm'>
                    <span className='font-medium'>Required Proof: </span>
                    <span className='text-muted-foreground'>{selectedSubmission.quest.requiredProof}</span>
                  </div>
                )}
              </div>
            </div>

            <div className='rounded-lg border bg-muted/50 p-4'>
              <h3 className='text-sm font-semibold mb-3'>Submitted Proof</h3>
              <div className='space-y-3'>
                {selectedSubmission.proofUrl && (
                  <div>
                    <p className='text-xs font-medium text-muted-foreground mb-1'>Proof URL</p>
                    <a
                      href={selectedSubmission.proofUrl}
                      target='_blank'
                      rel='noopener noreferrer'
                      className='text-sm text-primary hover:underline flex items-center gap-1'
                    >
                      {selectedSubmission.proofUrl}
                      <ExternalLink className='h-3 w-3' />
                    </a>
                  </div>
                )}
                {selectedSubmission.proofText && (
                  <div>
                    <p className='text-xs font-medium text-muted-foreground mb-1'>Proof Text</p>
                    <p className='text-sm'>{selectedSubmission.proofText}</p>
                  </div>
                )}
                {selectedSubmission.screenshotUrl && (
                  <div>
                    <p className='text-xs font-medium text-muted-foreground mb-1'>Screenshot</p>
                    <a href={selectedSubmission.screenshotUrl} target='_blank' rel='noopener noreferrer' className='block'>
                      <img
                        src={selectedSubmission.screenshotUrl}
                        alt='Proof screenshot'
                        className='rounded-lg border max-w-full max-h-96 object-contain'
                      />
                    </a>
                  </div>
                )}
                {!selectedSubmission.proofUrl &&
                  !selectedSubmission.proofText &&
                  !selectedSubmission.screenshotUrl && (
                    <p className='text-sm text-muted-foreground'>No proof provided</p>
                )}
              </div>
            </div>

            <div className='rounded-lg border bg-muted/50 p-4'>
              <h3 className='text-sm font-semibold mb-3'>Timeline</h3>
              <div className='space-y-2 text-sm'>
                <div className='flex justify-between'>
                  <span className='text-muted-foreground'>Submitted:</span>
                  <span className='font-medium'>{formatDateTime(selectedSubmission.submittedAt)}</span>
                </div>
                {selectedSubmission.reviewedAt && (
                  <div className='flex justify-between'>
                    <span className='text-muted-foreground'>Reviewed:</span>
                    <span className='font-medium'>{formatDateTime(selectedSubmission.reviewedAt)}</span>
                  </div>
                )}
                {selectedSubmission.reviewNotes && (
                  <div className='mt-2 pt-2 border-t'>
                    <p className='text-xs font-medium text-muted-foreground mb-1'>Previous Review Notes</p>
                    <p className='text-sm'>{selectedSubmission.reviewNotes}</p>
                  </div>
                )}
              </div>
            </div>

            {(selectedSubmission.status === 'pending' || selectedSubmission.status === 'approved') && (
              <div className='grid gap-2'>
                <Label htmlFor='review-notes'>
                  {selectedSubmission.status === 'pending'
                    ? 'Review Notes (Optional for approval, required for rejection)'
                    : 'Revocation Reason (Required)'}
                </Label>
                <Textarea
                  id='review-notes'
                  value={reviewNotes}
                  onChange={(e) => setReviewNotes(e.target.value)}
                  placeholder={
                    selectedSubmission.status === 'pending'
                      ? 'Add notes about this review...'
                      : 'Explain why this approved submission is being revoked...'
                  }
                  rows={3}
                />
              </div>
            )}

            {reviewError && (
              <div className='rounded-lg border border-red-200 bg-red-50 p-3'>
                <p className='text-sm text-red-700'>{reviewError}</p>
              </div>
            )}

            {selectedSubmission.status === 'pending' && (
              <DialogFooter className='gap-2'>
                <Button type='button' variant='outline' onClick={onClose} disabled={isSubmitting}>
                  Cancel
                </Button>
                <Button type='button' variant='destructive' onClick={() => void onReject()} disabled={isSubmitting} className='gap-2'>
                  {isSubmitting ? <Loader2 className='h-4 w-4 animate-spin' /> : <XCircle className='h-4 w-4' />}
                  Reject
                </Button>
                <Button type='button' onClick={() => void onApprove()} disabled={isSubmitting} className='gap-2'>
                  {isSubmitting ? <Loader2 className='h-4 w-4 animate-spin' /> : <CheckCircle2 className='h-4 w-4' />}
                  Approve
                </Button>
              </DialogFooter>
            )}

            {selectedSubmission.status === 'approved' && (
              <DialogFooter className='gap-2'>
                <Button type='button' variant='outline' onClick={onClose} disabled={isSubmitting}>
                  Cancel
                </Button>
                <Button type='button' variant='destructive' onClick={() => void onRevoke()} disabled={isSubmitting} className='gap-2'>
                  {isSubmitting ? <Loader2 className='h-4 w-4 animate-spin' /> : <XCircle className='h-4 w-4' />}
                  Revoke Approval
                </Button>
              </DialogFooter>
            )}

            {selectedSubmission.status === 'rejected' && (
              <DialogFooter>
                <Button type='button' variant='outline' onClick={onClose}>
                  Close
                </Button>
              </DialogFooter>
            )}
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
