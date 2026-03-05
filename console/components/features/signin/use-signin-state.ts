'use client';

import { useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import axios from 'axios';
import QRCode from 'qrcode';
import type {
  EnrollmentResponse,
  SignInStage,
  TwoFactorPreflight,
} from './types';

export function useSignInState() {
  const searchParams = useSearchParams();
  const nextPath = searchParams.get('next') ?? '/dashboard';
  const reason = searchParams.get('reason');

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [twoFactorCode, setTwoFactorCode] = useState('');
  const [recoveryCode, setRecoveryCode] = useState('');
  const [useRecoveryCode, setUseRecoveryCode] = useState(false);

  const [stage, setStage] = useState<SignInStage>('credentials');
  const [enrollment, setEnrollment] = useState<EnrollmentResponse | null>(null);
  const [enrollmentCode, setEnrollmentCode] = useState('');
  const [generatedRecoveryCodes, setGeneratedRecoveryCodes] = useState<string[]>(
    [],
  );
  const [showManualSetup, setShowManualSetup] = useState(false);
  const [showAdvancedOtpUri, setShowAdvancedOtpUri] = useState(false);
  const [qrCodeDataUrl, setQrCodeDataUrl] = useState<string | null>(null);
  const [qrCodeError, setQrCodeError] = useState<string | null>(null);
  const [copyStatus, setCopyStatus] = useState<string | null>(null);
  const [lastCopiedCode, setLastCopiedCode] = useState<string | null>(null);

  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const isTwoFactorRedirect = useMemo(
    () => reason === '2fa_required' || reason === '2fa_setup_required',
    [reason],
  );

  function normalizeNextPath() {
    return nextPath.startsWith('/') ? nextPath : '/dashboard';
  }

  function resetTwoFactorUi() {
    setEnrollment(null);
    setEnrollmentCode('');
    setShowManualSetup(false);
    setShowAdvancedOtpUri(false);
    setQrCodeDataUrl(null);
    setQrCodeError(null);
    setGeneratedRecoveryCodes([]);
    setTwoFactorCode('');
    setRecoveryCode('');
    setUseRecoveryCode(false);
    setCopyStatus(null);
    setLastCopiedCode(null);
  }

  async function fetchPreflight(): Promise<TwoFactorPreflight | null> {
    const response = await axios.get<TwoFactorPreflight>(
      '/api/proxy/admin/security/2fa/preflight',
      { validateStatus: () => true },
    );

    if (response.status < 200 || response.status >= 300) {
      return null;
    }

    return response.data;
  }

  function resolveStageFromPreflight(preflight: TwoFactorPreflight): SignInStage {
    if (!preflight.eligible) {
      return 'credentials';
    }
    if (!preflight.totpEnabled) {
      return 'setup2fa';
    }
    return 'twoFactor';
  }

  useEffect(() => {
    if (!isTwoFactorRedirect) {
      return;
    }

    let cancelled = false;

    const run = async () => {
      const preflight = await fetchPreflight().catch(() => null);
      if (cancelled || !preflight) {
        setStage('credentials');
        return;
      }

      setStage(resolveStageFromPreflight(preflight));
      setError(null);
    };

    void run();

    return () => {
      cancelled = true;
    };
  }, [isTwoFactorRedirect]);

  useEffect(() => {
    let cancelled = false;

    const run = async () => {
      if (!enrollment?.otpAuthUrl) {
        setQrCodeDataUrl(null);
        setQrCodeError(null);
        return;
      }

      try {
        const dataUrl = await QRCode.toDataURL(enrollment.otpAuthUrl, {
          width: 220,
          margin: 1,
        });

        if (cancelled) {
          return;
        }

        setQrCodeDataUrl(dataUrl);
        setQrCodeError(null);
      } catch {
        if (cancelled) {
          return;
        }

        setQrCodeDataUrl(null);
        setQrCodeError('Could not render QR code. Use secret key instead.');
      }
    };

    void run();

    return () => {
      cancelled = true;
    };
  }, [enrollment]);

  useEffect(() => {
    if (stage === 'twoFactor') {
      setUseRecoveryCode(false);
      setRecoveryCode('');
      setError(null);
    }
  }, [stage]);

  return {
    isTwoFactorRedirect,
    stage,
    loading,
    error,
    email,
    password,
    twoFactorCode,
    recoveryCode,
    useRecoveryCode,
    enrollment,
    enrollmentCode,
    generatedRecoveryCodes,
    showManualSetup,
    showAdvancedOtpUri,
    qrCodeDataUrl,
    qrCodeError,
    copyStatus,
    lastCopiedCode,
    setEmail,
    setPassword,
    setTwoFactorCode,
    setRecoveryCode,
    setUseRecoveryCode,
    setStage,
    setEnrollmentCode,
    setShowManualSetup,
    setShowAdvancedOtpUri,
    setError,
    setLoading,
    setEnrollment,
    setGeneratedRecoveryCodes,
    setQrCodeDataUrl,
    setQrCodeError,
    setCopyStatus,
    setLastCopiedCode,
    normalizeNextPath,
    resetTwoFactorUi,
    fetchPreflight,
    resolveStageFromPreflight,
  };
}
