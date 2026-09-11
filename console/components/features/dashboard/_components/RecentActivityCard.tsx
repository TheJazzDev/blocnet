'use client';

import { useMemo, useState } from 'react';
import { Activity, Clock } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { LoadingSpinner } from '@/components/ui/loading-spinner';
import { ViewEventsToggle } from '@/components/shared/ViewEventsToggle';
import type { AuditLog } from '@/lib/api-client';
import { filterViewAuditEvents } from '@/lib/audit-events';
import {
  ACTIVITY_PAGE_SIZE,
  formatDateTime,
  formatRelativeTime,
  getActionBadgeVariant,
} from './dashboard-utils';

type RecentActivityCardProps = {
  loading: boolean;
  activityLogs: AuditLog[];
  activityPage: number;
  activityHasNext: boolean;
  activityLoading: boolean;
  onPrevPage: () => Promise<void>;
  onNextPage: () => Promise<void>;
};

function ActivityRow({ event }: { event: AuditLog }) {
  return (
    <div className='flex items-start justify-between gap-4 border-b pb-4 last:border-0 last:pb-0'>
      <div className='min-w-0 flex-1'>
        <Badge
          variant={getActionBadgeVariant(event.action)}
          className='shrink-0 text-[10px]'>
          {event.action.replace('.', ' ')}
        </Badge>
        <p className='mt-1.5 text-sm font-medium'>{event.action}</p>
        <p className='text-xs text-muted-foreground'>
          {event.resourceType} · {event.resourceId ?? '—'}
        </p>
      </div>
      <div className='shrink-0 text-right'>
        <p className='text-xs text-muted-foreground'>
          {event.actor?.email ?? 'System'}
        </p>
        <p className='mt-0.5 flex items-center justify-end gap-1 text-[11px] text-muted-foreground'>
          <Clock className='h-3 w-3' />
          {formatRelativeTime(event.createdAt)}
        </p>
        <p className='text-[10px] text-muted-foreground'>
          {formatDateTime(event.createdAt)}
        </p>
      </div>
    </div>
  );
}

export function RecentActivityCard({
  loading,
  activityLogs,
  activityPage,
  activityHasNext,
  activityLoading,
  onPrevPage,
  onNextPage,
}: RecentActivityCardProps) {
  const [showViewEvents, setShowViewEvents] = useState(false);
  const { visible, hiddenViewCount } = useMemo(
    () => filterViewAuditEvents(activityLogs, showViewEvents),
    [activityLogs, showViewEvents],
  );

  return (
    <Card>
      <CardHeader>
        <div className='flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between'>
          <div>
            <CardTitle className='flex items-center gap-2 text-base'>
              <Activity className='h-4 w-4' />
              Recent Activity
            </CardTitle>
            <CardDescription>
              Latest operations across moderation, governance, and BEE events.
            </CardDescription>
          </div>
          <ViewEventsToggle
            checked={showViewEvents}
            onCheckedChange={setShowViewEvents}
            hiddenCount={hiddenViewCount}
          />
        </div>
      </CardHeader>
      <CardContent>
        {loading ? (
          <LoadingSpinner className='py-10' />
        ) : activityLogs.length === 0 ? (
          <p className='text-sm text-muted-foreground'>No audit events found.</p>
        ) : (
          <div className='space-y-4'>
            <div className='flex items-center justify-between'>
              <p className='text-xs text-muted-foreground'>
                Page {activityPage + 1} · {ACTIVITY_PAGE_SIZE} events
              </p>
              <div className='flex items-center gap-2'>
                <Button
                  size='sm'
                  variant='outline'
                  onClick={() => void onPrevPage()}
                  disabled={activityPage === 0 || activityLoading}>
                  Prev
                </Button>
                <Button
                  size='sm'
                  variant='outline'
                  onClick={() => void onNextPage()}
                  disabled={!activityHasNext || activityLoading}>
                  Next
                </Button>
              </div>
            </div>

            {activityLoading ? (
              <LoadingSpinner className='py-4' />
            ) : visible.length === 0 ? (
              <p className='py-4 text-center text-xs text-muted-foreground sm:text-sm'>
                Every event on this page is a view event. Turn on &ldquo;Show view
                events&rdquo; or move to the next page.
              </p>
            ) : (
              visible.map((event) => <ActivityRow key={event.id} event={event} />)
            )}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
