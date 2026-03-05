'use client';

import { Check, Copy } from 'lucide-react';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';

type RecoveryCodesStageProps = {
  loading: boolean;
  recoveryCodes: string[];
  copyStatus: string | null;
  lastCopiedCode: string | null;
  onCopyAll: () => Promise<void>;
  onCopyOne: (code: string) => Promise<void>;
  onContinue: () => void;
};

export function RecoveryCodesStage({
  loading,
  recoveryCodes,
  copyStatus,
  lastCopiedCode,
  onCopyAll,
  onCopyOne,
  onContinue,
}: RecoveryCodesStageProps) {
  return (
    <div className='space-y-4'>
      <Alert>
        <AlertDescription>
          Save these recovery codes now. Each code can be used once.
        </AlertDescription>
      </Alert>

      <Button
        type='button'
        variant='outline'
        className='w-full'
        onClick={() => void onCopyAll()}
        disabled={loading || recoveryCodes.length === 0}>
        <Copy className='h-4 w-4' />
        Copy All Codes
      </Button>

      <div className='grid grid-cols-1 gap-2'>
        {recoveryCodes.map((code) => (
          <div
            key={code}
            className='flex items-center justify-between rounded-md border border-border px-2 py-1'>
            <code className='text-xs'>{code}</code>
            <Button
              type='button'
              variant='ghost'
              size='sm'
              onClick={() => void onCopyOne(code)}
              disabled={loading}>
              {lastCopiedCode === code ? (
                <Check className='h-4 w-4' />
              ) : (
                <Copy className='h-4 w-4' />
              )}
              {lastCopiedCode === code ? 'Copied' : 'Copy'}
            </Button>
          </div>
        ))}
      </div>

      {copyStatus ? (
        <p className='text-xs text-muted-foreground'>{copyStatus}</p>
      ) : null}

      <Button type='button' className='w-full' onClick={onContinue} disabled={loading}>
        Continue to Admin Panel
      </Button>
    </div>
  );
}
