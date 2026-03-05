'use client';

import { useAdminSession } from '@/components/admin-shell';
import { apiFetch } from '@/lib/api-client';
import { Button } from '@/components/ui/button';
import {
  AlertCircle,
  CheckCircle2,
  Clock,
  Loader2,
  XCircle,
} from 'lucide-react';
import { useQuestSubmissions } from '@/lib/hooks';
import { ReviewQueueTable } from './ReviewQueueTable';
import { SubmissionReviewDialog } from './SubmissionReviewDialog';

/**/

export default function QuestSubmissionsPage() {
  const session = useAdminSession();
  const canReviewSubmissions =
    session.effectiveRoles.includes('owner') ||
    session.effectiveRoles.includes('admin');

  const {
    submissions,
    isLoading,
    error,
    statusFilter,
    reviewOpen,
    selectedSubmission,
    reviewNotes,
    isSubmitting,
    reviewError,
    setStatusFilter,
    openReview,
    closeReview,
    setReviewNotes,
    setIsSubmitting,
    setReviewError,
    refresh,
  } = useQuestSubmissions({ autoLoad: canReviewSubmissions });

  async function handleApprove() {
    if (!selectedSubmission) return;

    setIsSubmitting(true);
    setReviewError(null);
    try {
      await apiFetch(
        `/admin/quests/submissions/${selectedSubmission.id}/approve`,
        {
          method: 'POST',
          body: JSON.stringify({ reviewNotes }),
        },
      );
      closeReview();
      await refresh();
    } catch (err: unknown) {
      setReviewError(
        err instanceof Error ? err.message : 'Failed to approve submission',
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleReject() {
    if (!selectedSubmission) return;

    if (!reviewNotes.trim()) {
      setReviewError('Please provide a reason for rejection');
      return;
    }

    setIsSubmitting(true);
    setReviewError(null);
    try {
      await apiFetch(
        `/admin/quests/submissions/${selectedSubmission.id}/reject`,
        {
          method: 'POST',
          body: JSON.stringify({ reviewNotes }),
        },
      );
      closeReview();
      await refresh();
    } catch (err: unknown) {
      setReviewError(
        err instanceof Error ? err.message : 'Failed to reject submission',
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleRevoke() {
    if (!selectedSubmission) return;

    if (!reviewNotes.trim()) {
      setReviewError('Please provide a reason for revocation');
      return;
    }

    setIsSubmitting(true);
    setReviewError(null);
    try {
      await apiFetch(
        `/admin/quests/submissions/${selectedSubmission.id}/revoke`,
        {
          method: 'POST',
          body: JSON.stringify({
            reviewNotes,
            revocationReason: reviewNotes,
          }),
        },
      );
      closeReview();
      await refresh();
    } catch (err: unknown) {
      setReviewError(
        err instanceof Error
          ? err.message
          : 'Failed to revoke submission approval',
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  if (!canReviewSubmissions) {
    return (
      <div className='flex min-h-screen items-center justify-center'>
        <div className='rounded-lg border border-red-200 bg-red-50 p-6'>
          <p className='text-sm text-red-800'>
            You do not have permission to review quest submissions.
          </p>
        </div>
      </div>
    );
  }

  const pendingCount = submissions.filter((s) => s.status === 'pending').length;

  return (
    <div className='space-y-6'>
      <div className='flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4'>
        <div>
          <h1 className='text-2xl sm:text-3xl font-bold tracking-tight'>
            Quest Submissions
          </h1>
          <p className='text-sm sm:text-base text-muted-foreground mt-1'>
            Review and verify user quest completions
          </p>
        </div>
        {pendingCount > 0 && (
          <div className='inline-flex items-center gap-2 rounded-lg bg-orange-50 px-3 py-2 text-sm font-medium text-orange-700 ring-1 ring-inset ring-orange-700/10'>
            <Clock className='h-4 w-4' />
            {pendingCount} pending review
          </div>
        )}
      </div>

      {/* Status Filter */}
      <div className='flex gap-2 flex-wrap'>
        <Button
          variant={statusFilter === 'all' ? 'default' : 'outline'}
          size='sm'
          onClick={() => setStatusFilter('all')}>
          All
        </Button>
        <Button
          variant={statusFilter === 'pending' ? 'default' : 'outline'}
          size='sm'
          onClick={() => setStatusFilter('pending')}>
          <Clock className='h-4 w-4 mr-2' />
          Pending
        </Button>
        <Button
          variant={statusFilter === 'approved' ? 'default' : 'outline'}
          size='sm'
          onClick={() => setStatusFilter('approved')}>
          <CheckCircle2 className='h-4 w-4 mr-2' />
          Approved
        </Button>
        <Button
          variant={statusFilter === 'rejected' ? 'default' : 'outline'}
          size='sm'
          onClick={() => setStatusFilter('rejected')}>
          <XCircle className='h-4 w-4 mr-2' />
          Rejected
        </Button>
      </div>

      {error && (
        <div className='rounded-lg border border-red-200 bg-red-50 p-4'>
          <div className='flex items-start gap-3'>
            <AlertCircle className='h-5 w-5 shrink-0 text-red-600' />
            <p className='text-sm text-red-800'>{error}</p>
          </div>
        </div>
      )}

      {isLoading ? (
        <div className='flex items-center justify-center py-12'>
          <Loader2 className='h-6 w-6 animate-spin text-primary' />
        </div>
      ) : (
        <ReviewQueueTable
          submissions={submissions}
          statusFilter={statusFilter}
          onOpenReview={openReview}
        />
      )}

      <SubmissionReviewDialog
        open={reviewOpen}
        selectedSubmission={selectedSubmission}
        reviewNotes={reviewNotes}
        setReviewNotes={setReviewNotes}
        reviewError={reviewError}
        isSubmitting={isSubmitting}
        onOpenChange={(nextOpen) => {
          if (!nextOpen) {
            closeReview();
          }
        }}
        onClose={closeReview}
        onApprove={handleApprove}
        onReject={handleReject}
        onRevoke={handleRevoke}
      />
    </div>
  );
}
