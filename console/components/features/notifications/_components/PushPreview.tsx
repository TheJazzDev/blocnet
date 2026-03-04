'use client';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

export function PushPreview({
  title,
  body,
  audienceLabel,
  isSpecific,
  recipientsCount,
}: {
  title: string;
  body: string;
  audienceLabel: string;
  isSpecific: boolean;
  recipientsCount: number;
}) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Push Preview</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="rounded-xl border bg-card p-4 shadow-sm space-y-1">
          <div className="mb-2 flex items-center gap-2">
            <div className="flex h-6 w-6 items-center justify-center rounded-md bg-primary/20">
              <span className="text-[10px] font-bold text-primary">B</span>
            </div>
            <span className="text-xs font-medium text-muted-foreground">Blocnet</span>
            <span className="ml-auto text-xs text-muted-foreground">now</span>
          </div>
          <p className="text-sm font-semibold leading-tight">
            {title || <span className="italic text-muted-foreground">Notification title</span>}
          </p>
          <p className="text-xs leading-relaxed text-muted-foreground">
            {body || <span className="italic">Notification body message</span>}
          </p>
        </div>

        <div className="mt-4 space-y-2 text-xs text-muted-foreground">
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
            <span>Delivery</span>
            <span className="font-medium text-foreground">Push + In-app</span>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

