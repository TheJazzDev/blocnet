'use client';

import { AlertCircle } from 'lucide-react';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { CredentialsStage } from './CredentialsStage';
import { SetupTwoFactorStage } from './SetupTwoFactorStage';
import { TwoFactorChallengeStage } from './TwoFactorChallengeStage';
import { RecoveryCodesStage } from './RecoveryCodesStage';
import { useSignInFlow } from './use-signin-flow';

export function SignInForm() {
  const flow = useSignInFlow();

  return (
    <div className='space-y-4'>
      {flow.error ? (
        <Alert variant='destructive'>
          <AlertCircle className='h-4 w-4' />
          <AlertDescription>{flow.error}</AlertDescription>
        </Alert>
      ) : null}

      {flow.isTwoFactorRedirect && flow.stage === 'credentials' ? (
        <Alert>
          <AlertDescription>
            Sign in with email and password first. Two-factor verification/setup
            comes next.
          </AlertDescription>
        </Alert>
      ) : null}

      {flow.stage === 'credentials' ? (
        <CredentialsStage
          email={flow.email}
          password={flow.password}
          loading={flow.loading}
          onEmailChange={flow.setEmail}
          onPasswordChange={flow.setPassword}
          onSubmit={flow.signInWithCredentials}
        />
      ) : null}

      {flow.stage === 'setup2fa' ? (
        <SetupTwoFactorStage
          loading={flow.loading}
          enrollment={flow.enrollment}
          enrollmentCode={flow.enrollmentCode}
          showManualSetup={flow.showManualSetup}
          showAdvancedOtpUri={flow.showAdvancedOtpUri}
          qrCodeDataUrl={flow.qrCodeDataUrl}
          qrCodeError={flow.qrCodeError}
          onEnrollmentCodeChange={flow.setEnrollmentCode}
          onToggleManualSetup={() => {
            flow.setShowManualSetup(!flow.showManualSetup);
            if (flow.showManualSetup) {
              flow.setShowAdvancedOtpUri(false);
            }
          }}
          onToggleAdvancedUri={() =>
            flow.setShowAdvancedOtpUri(!flow.showAdvancedOtpUri)
          }
          onStartEnrollment={flow.startTwoFactorEnrollment}
          onConfirmEnrollment={flow.confirmTwoFactorEnrollment}
          onBackToCredentials={flow.backToCredentials}
        />
      ) : null}

      {flow.stage === 'twoFactor' ? (
        <TwoFactorChallengeStage
          loading={flow.loading}
          useRecoveryCode={flow.useRecoveryCode}
          twoFactorCode={flow.twoFactorCode}
          recoveryCode={flow.recoveryCode}
          onUseRecoveryCodeChange={(nextIsRecovery) => {
            flow.setUseRecoveryCode(nextIsRecovery);
            flow.setError(null);
            if (nextIsRecovery) {
              flow.setTwoFactorCode('');
            } else {
              flow.setRecoveryCode('');
            }
          }}
          onTwoFactorCodeChange={flow.setTwoFactorCode}
          onRecoveryCodeChange={flow.setRecoveryCode}
          onSubmit={flow.verifyTwoFactor}
          onBackToCredentials={flow.backToCredentials}
          onGoToSetup={() => flow.setStage('setup2fa')}
        />
      ) : null}

      {flow.stage === 'recoveryCodes' ? (
        <RecoveryCodesStage
          loading={flow.loading}
          recoveryCodes={flow.generatedRecoveryCodes}
          copyStatus={flow.copyStatus}
          lastCopiedCode={flow.lastCopiedCode}
          onCopyAll={flow.copyAllRecoveryCodes}
          onCopyOne={flow.copyRecoveryCode}
          onContinue={flow.continueToDashboard}
        />
      ) : null}
    </div>
  );
}
