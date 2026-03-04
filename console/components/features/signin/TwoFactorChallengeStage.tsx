'use client';

import { Loader2 } from 'lucide-react';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

type TwoFactorChallengeStageProps = {
  loading: boolean;
  useRecoveryCode: boolean;
  twoFactorCode: string;
  recoveryCode: string;
  onUseRecoveryCodeChange: (value: boolean) => void;
  onTwoFactorCodeChange: (value: string) => void;
  onRecoveryCodeChange: (value: string) => void;
  onSubmit: (event: React.FormEvent) => Promise<void>;
  onBackToCredentials: () => Promise<void>;
  onGoToSetup: () => void;
};

export function TwoFactorChallengeStage({
  loading,
  useRecoveryCode,
  twoFactorCode,
  recoveryCode,
  onUseRecoveryCodeChange,
  onTwoFactorCodeChange,
  onRecoveryCodeChange,
  onSubmit,
  onBackToCredentials,
  onGoToSetup,
}: TwoFactorChallengeStageProps) {
  return (
    <form onSubmit={(event) => void onSubmit(event)} className='space-y-4'>
      <Alert>
        <AlertDescription>
          Enter your Google Authenticator code to finish admin sign in.
        </AlertDescription>
      </Alert>

      <div className='space-y-2'>
        <Label htmlFor='two-factor-mode'>Verification Method</Label>
        <select
          id='two-factor-mode'
          value={useRecoveryCode ? 'recovery' : 'totp'}
          onChange={(event) => {
            const nextIsRecovery = event.target.value === 'recovery';
            onUseRecoveryCodeChange(nextIsRecovery);
          }}
          disabled={loading}
          className='h-10 w-full rounded-md border border-input bg-background px-3 text-sm'>
          <option value='totp'>Authenticator code</option>
          <option value='recovery'>Recovery code</option>
        </select>
        <p className='text-xs text-muted-foreground'>
          Use Authenticator code for normal sign in. Recovery code is fallback.
        </p>
      </div>

      {useRecoveryCode ? (
        <div className='space-y-2'>
          <Label htmlFor='recovery-code'>Recovery Code</Label>
          <Input
            id='recovery-code'
            type='text'
            placeholder='ABCD-EFGH-IJKL'
            value={recoveryCode}
            onChange={(event) => onRecoveryCodeChange(event.target.value)}
            required
            disabled={loading}
          />
        </div>
      ) : (
        <div className='space-y-2'>
          <Label htmlFor='two-factor-code'>Authenticator Code</Label>
          <Input
            id='two-factor-code'
            type='text'
            inputMode='numeric'
            placeholder='123456'
            value={twoFactorCode}
            onChange={(event) => onTwoFactorCodeChange(event.target.value)}
            required
            disabled={loading}
          />
        </div>
      )}

      <Button type='submit' className='w-full' disabled={loading}>
        {loading ? <Loader2 className='h-4 w-4 animate-spin' /> : null}
        {loading ? 'Verifying…' : 'Verify 2FA'}
      </Button>

      <Button
        type='button'
        variant='outline'
        className='w-full'
        onClick={() => void onBackToCredentials()}
        disabled={loading}>
        Use a different account
      </Button>

      <Button
        type='button'
        variant='ghost'
        className='w-full'
        onClick={onGoToSetup}
        disabled={loading}>
        I have not set up 2FA yet
      </Button>
    </form>
  );
}
