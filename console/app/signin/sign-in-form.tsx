'use client';

import { useEffect, useMemo, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import axios from 'axios';
import QRCode from 'qrcode';
import { supabase } from '@/lib/supabase';
import { extractApiErrorMessage } from '@/lib/api-error';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Loader2, AlertCircle, Copy, Check } from 'lucide-react';

type Stage = 'credentials' | 'setup2fa' | 'twoFactor' | 'recoveryCodes';

type TwoFactorPreflight = {
  eligible: boolean;
  totpEnabled: boolean;
  challengeRequired: boolean;
};

type EnrollmentResponse = {
  secret: string;
  otpAuthUrl: string;
  issuer: string;
  accountName: string;
  expiresAt: string;
};

export function SignInForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const nextPath = searchParams.get('next') ?? '/dashboard';
  const reason = searchParams.get('reason');

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const [twoFactorCode, setTwoFactorCode] = useState('');
  const [recoveryCode, setRecoveryCode] = useState('');
  const [useRecoveryCode, setUseRecoveryCode] = useState(false);

  const [stage, setStage] = useState<Stage>('credentials');
  const [enrollment, setEnrollment] = useState<EnrollmentResponse | null>(null);
  const [enrollmentCode, setEnrollmentCode] = useState('');
  const [generatedRecoveryCodes, setGeneratedRecoveryCodes] = useState<
    string[]
  >([]);
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

  async function clearServerSession() {
    await axios.post('/api/auth/sign-out').catch(() => null);
    await axios.post('/api/auth/2fa/clear').catch(() => null);
  }

  async function fetchPreflight(): Promise<TwoFactorPreflight | null> {
    const twoFactorRes = await axios.get<TwoFactorPreflight>(
      '/api/proxy/admin/security/2fa/preflight',
      { validateStatus: () => true },
    );

    if (twoFactorRes.status < 200 || twoFactorRes.status >= 300) {
      return null;
    }

    return twoFactorRes.data;
  }

  function resolveStageFromPreflight(preflight: TwoFactorPreflight): Stage {
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
        if (cancelled) return;
        setQrCodeDataUrl(dataUrl);
        setQrCodeError(null);
      } catch {
        if (cancelled) return;
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

  async function handleCredentialsSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const { data, error: signInError } =
        await supabase.auth.signInWithPassword({ email, password });

      if (signInError || !data.session) {
        setError(
          signInError?.message ?? 'Sign in failed. Check your credentials.',
        );
        return;
      }

      const { access_token, refresh_token } = data.session;

      const tokenRes = await axios.post(
        '/api/auth/set-token',
        {
          token: access_token,
          refreshToken: refresh_token,
        },
        {
          validateStatus: () => true,
        },
      );

      if (tokenRes.status < 200 || tokenRes.status >= 300) {
        const detail = extractApiErrorMessage(
          tokenRes.data,
          'Could not initialize your session.',
        );
        setError(`Session setup failed: ${detail}`);
        await supabase.auth.signOut();
        await clearServerSession();
        return;
      }

      const res = await axios.get<{ roles: string[] }>('/api/proxy/me', {
        validateStatus: () => true,
      });

      if (res.status < 200 || res.status >= 300) {
        setError('Could not verify your account. Please try again.');
        await supabase.auth.signOut();
        await clearServerSession();
        return;
      }

      const profile = res.data;

      const hasAccess =
        profile.roles.includes('owner') ||
        profile.roles.includes('admin') ||
        profile.roles.includes('moderator');

      if (!hasAccess) {
        setError(
          'Access denied. Only owners, admins, and moderators can access this panel.',
        );
        await supabase.auth.signOut();
        await clearServerSession();
        return;
      }

      const preflight = await fetchPreflight();
      if (!preflight) {
        setError('Could not evaluate two-factor authentication requirements.');
        await supabase.auth.signOut();
        await clearServerSession();
        return;
      }

      const nextStage = resolveStageFromPreflight(preflight);
      if (nextStage !== 'credentials') {
        setStage(nextStage);
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
        return;
      }

      router.push(nextPath.startsWith('/') ? nextPath : '/dashboard');
      router.refresh();
    } catch {
      setError('An unexpected error occurred. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  async function handleTwoFactorSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    const normalizedTotp = twoFactorCode.trim().replace(/\s+/g, '');
    const normalizedRecovery = recoveryCode.trim().toUpperCase();

    if (useRecoveryCode) {
      if (!normalizedRecovery) {
        setError('Enter a recovery code.');
        return;
      }
    } else if (!/^\d{6}$/.test(normalizedTotp)) {
      setError('Enter a valid 6-digit authenticator code.');
      return;
    }

    setLoading(true);

    try {
      const payload = useRecoveryCode
        ? { recoveryCode: normalizedRecovery }
        : { code: normalizedTotp };

      const verifyRes = await axios.post('/api/auth/2fa/verify', payload, {
        validateStatus: () => true,
      });

      if (verifyRes.status < 200 || verifyRes.status >= 300) {
        const detail = extractApiErrorMessage(verifyRes.data);
        setError(`Two-factor verification failed: ${detail}`);
        return;
      }

      router.push(nextPath.startsWith('/') ? nextPath : '/dashboard');
      router.refresh();
    } catch {
      setError('Two-factor verification failed. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  async function startTwoFactorEnrollment() {
    setError(null);
    setLoading(true);
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
        setError(`Unable to start 2FA setup: ${String(detail)}`);
        return;
      }

      setEnrollment(response.data);
      setCopyStatus(null);
      setLastCopiedCode(null);
    } catch {
      setError('Unable to start 2FA setup. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  async function confirmTwoFactorEnrollment() {
    if (!enrollmentCode.trim()) {
      setError('Enter your 6-digit authenticator code.');
      return;
    }

    setError(null);
    setLoading(true);

    try {
      const response = await axios.post<{
        enabled: true;
        recoveryCodes: string[];
        sessionToken: string;
        sessionExpiresAt: string;
      }>(
        '/api/proxy/admin/security/2fa/enrollment/confirm',
        { code: enrollmentCode.trim() },
        { validateStatus: () => true },
      );

      if (response.status < 200 || response.status >= 300) {
        const detail = extractApiErrorMessage(
          response.data,
          'Unable to confirm your two-factor setup.',
        );
        setError(`Unable to confirm 2FA setup: ${String(detail)}`);
        return;
      }

      const cookieRes = await axios.post(
        '/api/auth/2fa/session',
        {
          sessionToken: response.data.sessionToken,
          expiresAt: response.data.sessionExpiresAt,
        },
        {
          validateStatus: () => true,
        },
      );

      if (cookieRes.status < 200 || cookieRes.status >= 300) {
        setError('Unable to persist 2FA session. Try sign in again.');
        return;
      }

      setGeneratedRecoveryCodes(response.data.recoveryCodes);
      setStage('recoveryCodes');
      setEnrollment(null);
      setEnrollmentCode('');
      setShowManualSetup(false);
      setShowAdvancedOtpUri(false);
      setQrCodeDataUrl(null);
      setQrCodeError(null);
      setCopyStatus(null);
      setLastCopiedCode(null);
    } catch {
      setError('Unable to confirm 2FA setup. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  async function backToCredentials() {
    setLoading(true);
    setError(null);
    try {
      await supabase.auth.signOut();
      await clearServerSession();
      setStage('credentials');
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
    } finally {
      setLoading(false);
    }
  }

  function continueToDashboard() {
    router.push(nextPath.startsWith('/') ? nextPath : '/dashboard');
    router.refresh();
  }

  async function copyToClipboard(
    value: string,
    successMessage: string,
    code?: string,
  ) {
    try {
      if (!navigator.clipboard) {
        throw new Error('Clipboard API unavailable');
      }
      await navigator.clipboard.writeText(value);
      setCopyStatus(successMessage);
      setLastCopiedCode(code ?? null);
    } catch {
      setCopyStatus(null);
      setLastCopiedCode(null);
      setError('Could not copy. Please copy manually.');
    }
  }

  async function copyAllRecoveryCodes() {
    if (generatedRecoveryCodes.length === 0) {
      return;
    }
    await copyToClipboard(
      generatedRecoveryCodes.join('\n'),
      'All recovery codes copied.',
    );
  }

  async function copyRecoveryCode(code: string) {
    await copyToClipboard(code, `Copied ${code}.`, code);
  }

  return (
    <div className='space-y-4'>
      {error && (
        <Alert variant='destructive'>
          <AlertCircle className='h-4 w-4' />
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      {isTwoFactorRedirect && stage === 'credentials' && (
        <Alert>
          <AlertDescription>
            Sign in with email and password first. Two-factor verification/setup
            comes next.
          </AlertDescription>
        </Alert>
      )}

      {stage === 'credentials' && (
        <form onSubmit={handleCredentialsSubmit} className='space-y-4'>
          <div className='space-y-2'>
            <Label htmlFor='email'>Email</Label>
            <Input
              id='email'
              type='email'
              placeholder='admin@blocnet.io'
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              disabled={loading}
            />
          </div>

          <div className='space-y-2'>
            <Label htmlFor='password'>Password</Label>
            <Input
              id='password'
              type='password'
              placeholder='Enter your password'
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              disabled={loading}
            />
          </div>

          <Button type='submit' className='w-full' disabled={loading}>
            {loading && <Loader2 className='h-4 w-4 animate-spin' />}
            {loading ? 'Signing in…' : 'Sign In'}
          </Button>
        </form>
      )}

      {stage === 'setup2fa' && (
        <div className='space-y-4'>
          <Alert>
            <AlertDescription>
              Two-factor setup is required before you can access the admin
              console.
            </AlertDescription>
          </Alert>

          {!enrollment ? (
            <Button
              type='button'
              className='w-full'
              onClick={() => void startTwoFactorEnrollment()}
              disabled={loading}>
              {loading && <Loader2 className='h-4 w-4 animate-spin' />}
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
                onClick={() =>
                  setShowManualSetup((prev) => {
                    const next = !prev;
                    if (!next) {
                      setShowAdvancedOtpUri(false);
                    }
                    return next;
                  })
                }
                disabled={loading}>
                {showManualSetup
                  ? 'Hide Manual Setup'
                  : 'Use Manual Setup Instead'}
              </Button>

              {showManualSetup && (
                <div className='space-y-3 rounded-md border border-border p-3'>
                  <div className='space-y-1'>
                    <Label>Secret Key</Label>
                    <Input value={enrollment.secret} readOnly />
                  </div>

                  <Button
                    type='button'
                    variant='ghost'
                    className='w-full'
                    onClick={() => setShowAdvancedOtpUri((prev) => !prev)}
                    disabled={loading}>
                    {showAdvancedOtpUri
                      ? 'Hide Advanced URI'
                      : 'Show Advanced URI'}
                  </Button>

                  {showAdvancedOtpUri && (
                    <div className='space-y-1'>
                      <Label>OTPAuth URI (Advanced)</Label>
                      <Input value={enrollment.otpAuthUrl} readOnly />
                    </div>
                  )}
                </div>
              )}
              <div className='space-y-1'>
                <Label htmlFor='setup-code'>Authenticator Code</Label>
                <Input
                  id='setup-code'
                  type='text'
                  inputMode='numeric'
                  placeholder='123456'
                  value={enrollmentCode}
                  onChange={(e) => setEnrollmentCode(e.target.value)}
                  disabled={loading}
                />
              </div>
              <Button
                type='button'
                className='w-full'
                onClick={() => void confirmTwoFactorEnrollment()}
                disabled={loading}>
                {loading && <Loader2 className='h-4 w-4 animate-spin' />}
                Confirm 2FA Setup
              </Button>
            </div>
          )}

          <Button
            type='button'
            variant='outline'
            className='w-full'
            onClick={() => void backToCredentials()}
            disabled={loading}>
            Use a different account
          </Button>
        </div>
      )}

      {stage === 'twoFactor' && (
        <form onSubmit={handleTwoFactorSubmit} className='space-y-4'>
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
                setUseRecoveryCode(nextIsRecovery);
                setError(null);
                if (nextIsRecovery) {
                  setTwoFactorCode('');
                } else {
                  setRecoveryCode('');
                }
              }}
              disabled={loading}
              className='h-10 w-full rounded-md border border-input bg-background px-3 text-sm'>
              <option value='totp'>Authenticator code</option>
              <option value='recovery'>Recovery code</option>
            </select>
            <p className='text-xs text-muted-foreground'>
              Use Authenticator code for normal sign in. Recovery code is
              fallback.
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
                onChange={(event) => setRecoveryCode(event.target.value)}
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
                onChange={(event) => setTwoFactorCode(event.target.value)}
                required
                disabled={loading}
              />
            </div>
          )}

          <Button type='submit' className='w-full' disabled={loading}>
            {loading && <Loader2 className='h-4 w-4 animate-spin' />}
            {loading ? 'Verifying…' : 'Verify 2FA'}
          </Button>

          <Button
            type='button'
            variant='outline'
            className='w-full'
            onClick={() => void backToCredentials()}
            disabled={loading}>
            Use a different account
          </Button>

          <Button
            type='button'
            variant='ghost'
            className='w-full'
            onClick={() => setStage('setup2fa')}
            disabled={loading}>
            I have not set up 2FA yet
          </Button>
        </form>
      )}

      {stage === 'recoveryCodes' && (
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
            onClick={() => void copyAllRecoveryCodes()}
            disabled={loading || generatedRecoveryCodes.length === 0}>
            <Copy className='h-4 w-4' />
            Copy All Codes
          </Button>

          <div className='grid grid-cols-1 gap-2'>
            {generatedRecoveryCodes.map((code) => (
              <div
                key={code}
                className='flex items-center justify-between rounded-md border border-border px-2 py-1'>
                <code className='text-xs'>{code}</code>
                <Button
                  type='button'
                  variant='ghost'
                  size='sm'
                  onClick={() => void copyRecoveryCode(code)}
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

          <Button
            type='button'
            className='w-full'
            onClick={continueToDashboard}
            disabled={loading}>
            Continue to Admin Panel
          </Button>
        </div>
      )}
    </div>
  );
}
