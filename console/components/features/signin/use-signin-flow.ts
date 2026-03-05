'use client';

import { useRouter } from 'next/navigation';
import { useSignInState } from './use-signin-state';
import { useSignInActions } from './use-signin-actions';

export function useSignInFlow() {
  const router = useRouter();
  const state = useSignInState();

  const actions = useSignInActions({
    router,
    email: state.email,
    password: state.password,
    twoFactorCode: state.twoFactorCode,
    recoveryCode: state.recoveryCode,
    useRecoveryCode: state.useRecoveryCode,
    enrollmentCode: state.enrollmentCode,
    generatedRecoveryCodes: state.generatedRecoveryCodes,
    setError: state.setError,
    setLoading: state.setLoading,
    setStage: state.setStage,
    setEnrollment: state.setEnrollment,
    setEnrollmentCode: state.setEnrollmentCode,
    setShowManualSetup: state.setShowManualSetup,
    setShowAdvancedOtpUri: state.setShowAdvancedOtpUri,
    setQrCodeDataUrl: state.setQrCodeDataUrl,
    setQrCodeError: state.setQrCodeError,
    setGeneratedRecoveryCodes: state.setGeneratedRecoveryCodes,
    setTwoFactorCode: state.setTwoFactorCode,
    setRecoveryCode: state.setRecoveryCode,
    setUseRecoveryCode: state.setUseRecoveryCode,
    setCopyStatus: state.setCopyStatus,
    setLastCopiedCode: state.setLastCopiedCode,
    normalizeNextPath: state.normalizeNextPath,
    resetTwoFactorUi: state.resetTwoFactorUi,
    fetchPreflight: state.fetchPreflight,
    resolveStageFromPreflight: state.resolveStageFromPreflight,
  });

  return {
    ...state,
    ...actions,
  };
}
