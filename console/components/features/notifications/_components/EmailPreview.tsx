'use client';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

export function EmailPreview({
  fromAddress,
  fromName,
  subject,
  message,
  audienceLabel,
  isSpecific,
  recipientsCount,
  ratePerMinute,
}: {
  fromAddress: string;
  fromName: string;
  subject: string;
  message: string;
  audienceLabel: string;
  isSpecific: boolean;
  recipientsCount: number;
  ratePerMinute?: number | null;
}) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Email Preview</CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        <div className="rounded-xl border bg-card p-4 shadow-sm">
          <p className="text-xs text-muted-foreground">From</p>
          <p className="text-sm font-medium">
            {(fromName || 'Blocnet Updates') + ' '}
            &lt;{fromAddress || 'updates@blocnet.app'}&gt;
          </p>
          <p className="mt-3 text-xs text-muted-foreground">Subject</p>
          <p className="text-sm font-semibold leading-tight">
            {subject || <span className="italic text-muted-foreground">Email subject</span>}
          </p>
          <p className="mt-3 whitespace-pre-wrap text-xs leading-relaxed text-muted-foreground">
            {message || 'Email message content'}
          </p>
        </div>

        <div className="space-y-2 text-xs text-muted-foreground">
          <div className="flex justify-between">
            <span>Audience</span>
            <span className="font-medium text-foreground">{audienceLabel}</span>
          </div>
          {isSpecific ? (
            <div className="flex justify-between">
              <span>Recipients</span>
              <span className="font-medium text-foreground">{recipientsCount} selected</span>
            </div>
          ) : null}
          <div className="flex justify-between">
            <span>Rate Limit</span>
            <span className="font-medium text-foreground">{ratePerMinute ?? '-'} / min</span>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

