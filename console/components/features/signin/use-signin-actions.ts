'use client';

import type { AppRouterInstance } from 'next/dist/shared/lib/app-router-context.shared-runtime';
import axios from 'axios';
import { supabase } from '@/lib/supabase';
import { extractApiErrorMessage } from '@/lib/api-error';
import { createRecoveryClipboardActions } from './recovery-clipboard';
import type { EnrollmentResponse, SignInStage, TwoFactorPreflight } from './types';

type SignInActionsParams = {
  router: AppRouterInstance;
  email: string;
  password: string;
  twoFactorCode: string;
  recoveryCode: string;
  useRecoveryCode: boolean;
  enrollmentCode: string;
  generatedRecoveryCodes: string[];
  setError: (value: string | null) => void;
  setLoading: (value: boolean) => void;
  setStage: (stage: SignInStage) => void;
  setEnrollment: (value: EnrollmentResponse | null) => void;
  setEnrollmentCode: (value: string) => void;
  setShowManualSetup: (value: boolean) => void;
  setShowAdvancedOtpUri: (value: boolean) => void;
  setQrCodeDataUrl: (value: string | null) => void;
  setQrCodeError: (value: string | null) => void;
  setGeneratedRecoveryCodes: (value: string[]) => void;
  setTwoFactorCode: (value: string) => void;
  setRecoveryCode: (value: string) => void;
  setUseRecoveryCode: (value: boolean) => void;
  setCopyStatus: (value: string | null) => void;
  setLastCopiedCode: (value: string | null) => void;
  normalizeNextPath: () => string;
  resetTwoFactorUi: () => void;
  fetchPreflight: () => Promise<TwoFactorPreflight | null>;
  resolveStageFromPreflight: (preflight: TwoFactorPreflight) => SignInStage;
};

export function useSignInActions(params: SignInActionsParams) {
  async function clearServerSession() {
    await axios.post('/api/auth/sign-out').catch(() => null);
    await axios.post('/api/auth/2fa/clear').catch(() => null);
  }
  async function signInWithCredentials(event: React.FormEvent) {
    event.preventDefault();
    params.setError(null);
    params.setLoading(true);

    try {
      const { data, error: signInError } = await supabase.auth.signInWithPassword({
        email: params.email,
        password: params.password,
      });

      if (signInError || !data.session) {
        params.setError(signInError?.message ?? 'Sign in failed. Check your credentials.');
        return;
      }

      const tokenRes = await axios.post(
        '/api/auth/set-token',
        {
          token: data.session.access_token,
          refreshToken: data.session.refresh_token,
        },
        { validateStatus: () => true },
      );

      if (tokenRes.status < 200 || tokenRes.status >= 300) {
        const detail = extractApiErrorMessage(
          tokenRes.data,
          'Could not initialize your session.',
        );
        params.setError(`Session setup failed: ${detail}`);
        await supabase.auth.signOut();
        await clearServerSession();
        return;
      }

      const profileRes = await axios.get<{ roles: string[] }>('/api/proxy/me', {
        validateStatus: () => true,
      });

      if (profileRes.status < 200 || profileRes.status >= 300) {
        params.setError('Could not verify your account. Please try again.');
        await supabase.auth.signOut();
        await clearServerSession();
        return;
      }

      const hasAccess =
        profileRes.data.roles.includes('owner') ||
        profileRes.data.roles.includes('dev') ||
        profileRes.data.roles.includes('admin');

      if (!hasAccess) {
        params.setError(
          'Access denied. Only owner, dev, and admin accounts can access this panel.',
        );
        await supabase.auth.signOut();
        await clearServerSession();
        return;
      }

      const preflight = await params.fetchPreflight();
      if (!preflight) {
        params.setError('Could not evaluate two-factor authentication requirements.');
        await supabase.auth.signOut();
        await clearServerSession();
        return;
      }

      const nextStage = params.resolveStageFromPreflight(preflight);
      if (nextStage !== 'credentials') {
        params.setStage(nextStage);
        params.resetTwoFactorUi();
        return;
      }

      params.router.push(params.normalizeNextPath());
      params.router.refresh();
    } catch {
      params.setError('An unexpected error occurred. Please try again.');
    } finally {
      params.setLoading(false);
    }
  }

  async function verifyTwoFactor(event: React.FormEvent) {
    event.preventDefault();
    params.setError(null);

    const normalizedTotp = params.twoFactorCode.trim().replace(/\s+/g, '');
    const normalizedRecovery = params.recoveryCode.trim().toUpperCase();

    if (params.useRecoveryCode) {
      if (!normalizedRecovery) {
        params.setError('Enter a recovery code.');
        return;
      }
    } else if (!/^\d{6}$/.test(normalizedTotp)) {
      params.setError('Enter a valid 6-digit authenticator code.');
      return;
    }

    params.setLoading(true);

    try {
      const payload = params.useRecoveryCode
        ? { recoveryCode: normalizedRecovery }
        : { code: normalizedTotp };

      const verifyRes = await axios.post('/api/auth/2fa/verify', payload, {
        validateStatus: () => true,
      });

      if (verifyRes.status < 200 || verifyRes.status >= 300) {
        const detail = extractApiErrorMessage(verifyRes.data);
        params.setError(`Two-factor verification failed: ${detail}`);
        return;
      }

      params.router.push(params.normalizeNextPath());
      params.router.refresh();
    } catch {
      params.setError('Two-factor verification failed. Please try again.');
    } finally {
      params.setLoading(false);
    }
  }

  async function startTwoFactorEnrollment() {
    params.setError(null);
    params.setLoading(true);

    try {
      const response = await axios.post<EnrollmentResponse>(
        '/api/proxy/admin/security/2fa/enrollment/start',
        {},
        { validateStatus: () => true },
      );

      if (response.status < 200 || response.status >= 300) {
        const detail = extractApiErrorMessage(
          response.data,
          'Unable to start two-factor setup right now.',
        );
        params.setError(`Unable to start 2FA setup: ${String(detail)}`);
        return;
      }

      params.setEnrollment(response.data);
      params.setCopyStatus(null);
      params.setLastCopiedCode(null);
    } catch {
      params.setError('Unable to start 2FA setup. Please try again.');
    } finally {
      params.setLoading(false);
    }
  }

  async function confirmTwoFactorEnrollment() {
    if (!params.enrollmentCode.trim()) {
      params.setError('Enter your 6-digit authenticator code.');
      return;
    }

    params.setError(null);
    params.setLoading(true);

    try {
      const response = await axios.post<{
        enabled: true;
        recoveryCodes: string[];
        sessionToken: string;
        sessionExpiresAt: string;
      }>(
        '/api/proxy/admin/security/2fa/enrollment/confirm',
        { code: params.enrollmentCode.trim() },
        { validateStatus: () => true },
      );

      if (response.status < 200 || response.status >= 300) {
        const detail = extractApiErrorMessage(
          response.data,
          'Unable to confirm your two-factor setup.',
        );
        params.setError(`Unable to confirm 2FA setup: ${String(detail)}`);
        return;
      }

      const cookieRes = await axios.post(
        '/api/auth/2fa/session',
        {
          sessionToken: response.data.sessionToken,
          expiresAt: response.data.sessionExpiresAt,
        },
        { validateStatus: () => true },
      );

      if (cookieRes.status < 200 || cookieRes.status >= 300) {
        params.setError('Unable to persist 2FA session. Try sign in again.');
        return;
      }

      params.setGeneratedRecoveryCodes(response.data.recoveryCodes);
      params.setStage('recoveryCodes');
      params.setEnrollment(null);
      params.setEnrollmentCode('');
      params.setShowManualSetup(false);
      params.setShowAdvancedOtpUri(false);
      params.setQrCodeDataUrl(null);
      params.setQrCodeError(null);
      params.setCopyStatus(null);
      params.setLastCopiedCode(null);
    } catch {
      params.setError('Unable to confirm 2FA setup. Please try again.');
    } finally {
      params.setLoading(false);
    }
  }

  async function backToCredentials() {
    params.setLoading(true);
    params.setError(null);

    try {
      await supabase.auth.signOut();
      await clearServerSession();
      params.setStage('credentials');
      params.resetTwoFactorUi();
    } finally {
      params.setLoading(false);
    }
  }

  function continueToDashboard() {
    params.router.push(params.normalizeNextPath());
    params.router.refresh();
  }

  const recoveryClipboardActions = createRecoveryClipboardActions({
    generatedRecoveryCodes: params.generatedRecoveryCodes,
    setCopyStatus: params.setCopyStatus,
    setLastCopiedCode: params.setLastCopiedCode,
    setError: params.setError,
  });

  return {
    signInWithCredentials,
    verifyTwoFactor,
    startTwoFactorEnrollment,
    confirmTwoFactorEnrollment,
    backToCredentials,
    continueToDashboard,
    ...recoveryClipboardActions,
  };
}
