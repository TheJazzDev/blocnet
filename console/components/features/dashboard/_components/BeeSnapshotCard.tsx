'use client';

import { Brain } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { LoadingSpinner } from '@/components/ui/loading-spinner';
import type { EdgeBriefResponse } from '@/lib/api-client';
import type { EdgeTelemetry } from './dashboard-utils';
import { MetricCell } from './MetricCell';

type BeeSnapshotCardProps = {
  loading: boolean;
  edgeBrief: EdgeBriefResponse | null;
  edgeTelemetry: EdgeTelemetry;
};

export function BeeSnapshotCard({
  loading,
  edgeBrief,
  edgeTelemetry,
}: BeeSnapshotCardProps) {
  return (
    <Card className='xl:col-span-2'>
      <CardHeader>
        <CardTitle className='flex items-center gap-2 text-base'>
          <Brain className='h-4 w-4' />
          BEE Snapshot
        </CardTitle>
        <CardDescription>
          Signal volume, quality pressure, and recent usage telemetry.
        </CardDescription>
      </CardHeader>
      <CardContent className='space-y-3'>
        {loading ? (
          <LoadingSpinner className='py-8' />
        ) : edgeBrief ? (
          <>
            <p className='text-sm text-muted-foreground'>{edgeBrief.headline}</p>
            <div className='grid gap-2 sm:grid-cols-2 lg:grid-cols-4'>
              <MetricCell
                label='Signals'
                value={edgeBrief.totalSignals.toString()}
                hint='7d window'
              />
              <MetricCell
                label='Act Now'
                value={edgeBrief.recommendedNowCount.toString()}
                hint='Critical items'
              />
              <MetricCell
                label='Watch'
                value={edgeBrief.watchCount.toString()}
                hint='Monitor queue'
              />
              <MetricCell
                label='High Urgency'
                value={edgeBrief.highUrgencyCount.toString()}
                hint='Priority pressure'
              />
            </div>
            <div className='grid gap-2 sm:grid-cols-2 lg:grid-cols-4'>
              <MetricCell
                label='Feedback'
                value={edgeTelemetry.feedbackTotal.toString()}
                hint={`${edgeTelemetry.feedbackAct} act · ${edgeTelemetry.feedbackWatch} watch · ${edgeTelemetry.feedbackIgnore} ignore`}
              />
              <MetricCell
                label='Explain Opens'
                value={edgeTelemetry.explainViews.toString()}
                hint='Inspector usage'
              />
              <MetricCell
                label='Brief Views'
                value={edgeTelemetry.briefViews.toString()}
                hint='Read frequency'
              />
              <MetricCell
                label='Feed Items Served'
                value={edgeTelemetry.feedItemsServed.toString()}
                hint='Recent logs'
              />
            </div>
            {edgeBrief.topProjects.length > 0 ? (
              <div className='rounded-lg border p-3'>
                <p className='mb-2 text-xs font-semibold uppercase tracking-wide text-muted-foreground'>
                  Top Projects Under Pressure
                </p>
                <div className='space-y-2'>
                  {edgeBrief.topProjects.slice(0, 3).map((project) => (
                    <div
                      key={project.projectId}
                      className='flex items-center justify-between gap-2 text-xs'>
                      <div className='min-w-0'>
                        <p className='truncate font-medium text-foreground'>
                          {project.projectName}
                        </p>
                        <p className='text-muted-foreground'>
                          {project.count} decisions · {project.highUrgencyCount}{' '}
                          high urgency
                        </p>
                      </div>
                      <Badge variant='outline'>
                        {project.avgEdgeScore.toFixed(3)}
                      </Badge>
                    </div>
                  ))}
                </div>
              </div>
            ) : null}
          </>
        ) : (
          <p className='text-sm text-muted-foreground'>
            Edge brief unavailable for this account yet.
          </p>
        )}
      </CardContent>
    </Card>
  );
}
