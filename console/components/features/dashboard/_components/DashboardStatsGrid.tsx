'use client';

import type { LucideIcon } from 'lucide-react';
import { ArrowUpRight } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { LoadingSpinner } from '@/components/ui/loading-spinner';

type StatCard = {
  title: string;
  value: string;
  change: string;
  icon: LucideIcon;
};

type DashboardStatsGridProps = {
  loading: boolean;
  statCards: StatCard[];
};

export function DashboardStatsGrid({
  loading,
  statCards,
}: DashboardStatsGridProps) {
  return (
    <div className='grid gap-4 sm:grid-cols-2 xl:grid-cols-4'>
      {loading ? (
        <LoadingSpinner className='py-10 sm:col-span-2 xl:col-span-4' />
      ) : (
        statCards.map((stat) => (
          <Card key={stat.title}>
            <CardHeader className='flex flex-row items-center justify-between pb-2'>
              <CardTitle className='text-sm font-medium text-muted-foreground'>
                {stat.title}
              </CardTitle>
              <stat.icon className='h-4 w-4 text-muted-foreground' />
            </CardHeader>
            <CardContent>
              <div className='text-2xl font-bold'>{stat.value}</div>
              <div className='mt-1 flex items-center gap-1 text-xs text-muted-foreground'>
                <ArrowUpRight className='h-3 w-3 text-emerald-500' />
                {stat.change}
              </div>
            </CardContent>
          </Card>
        ))
      )}
    </div>
  );
}
