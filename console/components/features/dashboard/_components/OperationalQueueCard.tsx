'use client';

import { AlertTriangle } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { LoadingSpinner } from '@/components/ui/loading-spinner';
import type { AdminStats } from '@/lib/api-client';
import { DashboardHealthCard } from '../dashboard-health-card';
import { MetricCell } from './MetricCell';

type OperationalQueueCardProps = {
  loading: boolean;
  stats: AdminStats | null;
  activeRate: number;
};

export function OperationalQueueCard({
  loading,
  stats,
  activeRate,
}: OperationalQueueCardProps) {
  return (
    <div className='grid gap-4 lg:grid-cols-3'>
      <Card className='lg:col-span-2'>
        <CardHeader>
          <CardTitle className='flex items-center gap-2 text-base'>
            <AlertTriangle className='h-4 w-4' />
            Operational Queue
          </CardTitle>
          <CardDescription>
            Pending governance, user status pressure, and delivery posture.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {loading || !stats ? (
            <LoadingSpinner className='py-8' />
          ) : (
            <div className='grid gap-3 sm:grid-cols-2 lg:grid-cols-4'>
              <MetricCell
                label='Pending Role Apps'
                value={stats.pendingAdminApps.toLocaleString()}
                hint='Awaiting review'
              />
              <MetricCell
                label='Pending Proposals'
                value={stats.pendingProposals.toLocaleString()}
                hint='Project approvals'
              />
              <MetricCell
                label='Deactivated Users'
                value={stats.deactivatedUsers.toLocaleString()}
                hint='Needs follow-up'
              />
              <MetricCell
                label='Active User Rate'
                value={`${activeRate.toFixed(1)}%`}
                hint={`${stats.activeUsers.toLocaleString()} / ${stats.totalUsers.toLocaleString()}`}
              />
            </div>
          )}
        </CardContent>
      </Card>

      <DashboardHealthCard />
    </div>
  );
}
