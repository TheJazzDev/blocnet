'use client';

import { Bell } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { LoadingSpinner } from '@/components/ui/loading-spinner';
import type { AdminStats } from '@/lib/api-client';

type QuickStatsCardProps = {
  loading: boolean;
  stats: AdminStats | null;
};

export function QuickStatsCard({ loading, stats }: QuickStatsCardProps) {
  if (!loading && !stats) {
    return null;
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className='text-base'>Quick Stats</CardTitle>
      </CardHeader>
      <CardContent className='space-y-3'>
        {loading ? (
          <LoadingSpinner className='py-6' />
        ) : stats ? (
          <>
            <div className='flex items-center justify-between'>
              <span className='text-sm text-muted-foreground'>Total Comments</span>
              <span className='text-sm font-medium'>
                {stats.totalComments.toLocaleString()}
              </span>
            </div>
            <div className='flex items-center justify-between'>
              <span className='text-sm text-muted-foreground'>Active Hunters</span>
              <span className='text-sm font-medium'>{stats.activeHunters}</span>
            </div>
            <div className='flex items-center justify-between'>
              <span className='text-sm text-muted-foreground'>Primary Tags</span>
              <span className='text-sm font-medium'>{stats.totalTags} total</span>
            </div>
            <div className='flex items-center justify-between border-t pt-3'>
              <span className='flex items-center gap-1.5 text-sm text-muted-foreground'>
                <Bell className='h-3.5 w-3.5' />
                Push Enabled
              </span>
              <span className='text-sm font-medium'>
                {stats.usersWithPushEnabled} users
              </span>
            </div>
          </>
        ) : null}
      </CardContent>
    </Card>
  );
}
