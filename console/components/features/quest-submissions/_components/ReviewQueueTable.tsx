'use client';

import { Button } from '@/components/ui/button';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Award, CheckCircle2, Clock, Eye, XCircle } from 'lucide-react';

export interface QuestSubmission {
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

export type StatusFilter = 'all' | 'pending' | 'approved' | 'rejected';

function formatRelativeTime(dateString: string) {
  try {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMins / 60);
    const diffDays = Math.floor(diffHours / 24);

    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    if (diffDays < 7) return `${diffDays}d ago`;
    return new Date(dateString).toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch {
    return 'Invalid Date';
  }
}

export function ReviewQueueTable({
  submissions,
  statusFilter,
  onOpenReview,
}: {
  submissions: QuestSubmission[];
  statusFilter: StatusFilter;
  onOpenReview: (submission: QuestSubmission) => void;
}) {
  return (
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
                {statusFilter === 'pending'
                  ? 'No pending submissions to review.'
                  : 'No submissions found.'}
              </TableCell>
            </TableRow>
          ) : (
            submissions.map((submission) => (
              <TableRow key={submission.id}>
                <TableCell>
                  <div className="flex items-center gap-3">
                    {submission.user.avatarUrl ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={submission.user.avatarUrl}
                        alt={submission.user.displayName ?? 'User'}
                        className="h-8 w-8 rounded-full object-cover"
                      />
                    ) : (
                      <div className="h-8 w-8 rounded-full bg-gradient-to-br from-primary to-teal-400 flex items-center justify-center text-white text-xs font-bold">
                        {(submission.user.displayName ?? submission.user.email)[0].toUpperCase()}
                      </div>
                    )}
                    <div className="space-y-0.5">
                      <p className="text-sm font-medium">
                        {submission.user.displayName ?? 'User'}
                      </p>
                      <p className="text-xs text-muted-foreground">{submission.user.email}</p>
                    </div>
                  </div>
                </TableCell>
                <TableCell>
                  <div className="space-y-1">
                    <p className="text-sm font-medium">{submission.quest.title}</p>
                    <span className="inline-flex items-center rounded-md bg-purple-50 px-2 py-0.5 text-xs font-medium text-purple-700 ring-1 ring-inset ring-purple-700/10">
                      {submission.quest.type.replace('_', ' ')}
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
                  {submission.status === 'pending' && (
                    <span className="inline-flex items-center gap-1 rounded-md bg-orange-50 px-2 py-1 text-xs font-medium text-orange-700 ring-1 ring-inset ring-orange-700/10">
                      <Clock className="h-3 w-3" />
                      Pending
                    </span>
                  )}
                  {submission.status === 'approved' && (
                    <span className="inline-flex items-center gap-1 rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-700/10">
                      <CheckCircle2 className="h-3 w-3" />
                      Approved
                    </span>
                  )}
                  {submission.status === 'rejected' && (
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
                    onClick={() => onOpenReview(submission)}
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
  );
}

