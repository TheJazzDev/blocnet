'use client';

import { Loader2 } from 'lucide-react';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import type { EnrollmentResponse } from './types';

type SetupTwoFactorStageProps = {
  loading: boolean;
  enrollment: EnrollmentResponse | null;
  enrollmentCode: string;
  showManualSetup: boolean;
  showAdvancedOtpUri: boolean;
  qrCodeDataUrl: string | null;
  qrCodeError: string | null;
  onEnrollmentCodeChange: (value: string) => void;
  onToggleManualSetup: () => void;
  onToggleAdvancedUri: () => void;
  onStartEnrollment: () => Promise<void>;
  onConfirmEnrollment: () => Promise<void>;
  onBackToCredentials: () => Promise<void>;
};

export function SetupTwoFactorStage({
  loading,
  enrollment,
  enrollmentCode,
  showManualSetup,
  showAdvancedOtpUri,
  qrCodeDataUrl,
  qrCodeError,
  onEnrollmentCodeChange,
  onToggleManualSetup,
  onToggleAdvancedUri,
  onStartEnrollment,
  onConfirmEnrollment,
  onBackToCredentials,
}: SetupTwoFactorStageProps) {
  return (
    <div className='space-y-4'>
      <Alert>
        <AlertDescription>
          Two-factor setup is required before you can access the admin console.
        </AlertDescription>
      </Alert>

      {!enrollment ? (
        <Button
          type='button'
          className='w-full'
          onClick={() => void onStartEnrollment()}
          disabled={loading}>
          {loading ? <Loader2 className='h-4 w-4 animate-spin' /> : null}
          Start 2FA Setup
        </Button>
      ) : (
        <div className='space-y-3'>
          {qrCodeDataUrl ? (
            <div className='space-y-1'>
              <Label>Scan QR Code</Label>
              <div className='flex justify-center rounded-md border border-border p-3'>
                <img
                  src={qrCodeDataUrl}
                  alt='TOTP enrollment QR code'
                  width={220}
                  height={220}
                />
              </div>
            </div>
          ) : null}

          {qrCodeError ? (
            <Alert>
              <AlertDescription>{qrCodeError}</AlertDescription>
            </Alert>
          ) : null}

          <Button
            type='button'
            variant='ghost'
            className='w-full'
            onClick={onToggleManualSetup}
            disabled={loading}>
            {showManualSetup ? 'Hide Manual Setup' : 'Use Manual Setup Instead'}
          </Button>

          {showManualSetup ? (
            <div className='space-y-3 rounded-md border border-border p-3'>
              <div className='space-y-1'>
                <Label>Secret Key</Label>
                <Input value={enrollment.secret} readOnly />
              </div>

              <Button
                type='button'
                variant='ghost'
                className='w-full'
                onClick={onToggleAdvancedUri}
                disabled={loading}>
                {showAdvancedOtpUri ? 'Hide Advanced URI' : 'Show Advanced URI'}
              </Button>

              {showAdvancedOtpUri ? (
                <div className='space-y-1'>
                  <Label>OTPAuth URI (Advanced)</Label>
                  <Input value={enrollment.otpAuthUrl} readOnly />
                </div>
              ) : null}
            </div>
          ) : null}

          <div className='space-y-1'>
            <Label htmlFor='setup-code'>Authenticator Code</Label>
            <Input
              id='setup-code'
              type='text'
              inputMode='numeric'
              placeholder='123456'
              value={enrollmentCode}
              onChange={(event) => onEnrollmentCodeChange(event.target.value)}
              disabled={loading}
            />
          </div>

          <Button
            type='button'
            className='w-full'
            onClick={() => void onConfirmEnrollment()}
            disabled={loading}>
            {loading ? <Loader2 className='h-4 w-4 animate-spin' /> : null}
            Confirm 2FA Setup
          </Button>
        </div>
      )}

      <Button
        type='button'
        variant='outline'
        className='w-full'
        onClick={() => void onBackToCredentials()}
        disabled={loading}>
        Use a different account
      </Button>
    </div>
  );
}
