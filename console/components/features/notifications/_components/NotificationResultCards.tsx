'use client';

import { Card, CardContent } from '@/components/ui/card';

type PushResult = {
  recipientCount: number;
  sentCount: number;
  failureCount: number;
  insertedCount: number;
  skipped: boolean;
  skipReason?: string | null;
};

type EmailResult = {
  recipientCount: number;
  delivered: number;
  failed: number;
  skipped: number;
  estimatedRatePerMinute: number;
};

export function PushResultCard({ result }: { result: PushResult }) {
  return (
    <Card className='border-green-500/30 bg-green-500/5'>
      <CardContent className='pt-6'>
        <p className='text-sm font-medium text-green-400'>
          Notification sent successfully
        </p>
        <div className='mt-2 flex flex-wrap gap-3 text-xs text-muted-foreground'>
          <span>
            Recipients:{' '}
            <strong className='text-foreground'>{result.recipientCount}</strong>
          </span>
          <span>
            Push sent:{' '}
            <strong className='text-foreground'>{result.sentCount}</strong>
          </span>
          {result.failureCount > 0 && (
            <span>
              Push failed:{' '}
              <strong className='text-destructive'>{result.failureCount}</strong>
            </span>
          )}
          <span>
            In-app created:{' '}
            <strong className='text-foreground'>{result.insertedCount}</strong>
          </span>
          {result.skipped && (
            <span className='text-amber-400'>
              FCM skipped ({result.skipReason ?? 'not configured'})
            </span>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

export function EmailResultCard({ result }: { result: EmailResult }) {
  return (
    <Card className='border-green-500/30 bg-green-500/5'>
      <CardContent className='pt-6'>
        <p className='text-sm font-medium text-green-400'>
          Email broadcast sent
        </p>
        <div className='mt-2 flex flex-wrap gap-3 text-xs text-muted-foreground'>
          <span>
            Recipients:{' '}
            <strong className='text-foreground'>{result.recipientCount}</strong>
          </span>
          <span>
            Delivered:{' '}
            <strong className='text-foreground'>{result.delivered}</strong>
          </span>
          {result.failed > 0 && (
            <span>
              Failed: <strong className='text-destructive'>{result.failed}</strong>
            </span>
          )}
          {result.skipped > 0 && (
            <span>
              Skipped: <strong className='text-amber-400'>{result.skipped}</strong>
            </span>
          )}
          <span>
            Rate cap:{' '}
            <strong className='text-foreground'>
              {result.estimatedRatePerMinute}/min
            </strong>
          </span>
        </div>
      </CardContent>
    </Card>
  );
}

export function BroadcastErrorCard({ error }: { error: string }) {
  return (
    <Card className='border-destructive/30 bg-destructive/5'>
      <CardContent className='pt-6 text-sm text-destructive'>{error}</CardContent>
    </Card>
  );
}
