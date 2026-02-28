'use client';

import { useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import axios from 'axios';
import { supabase } from '@/lib/supabase';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Loader2, AlertCircle } from 'lucide-react';

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
  const [stage, setStage] = useState<'credentials' | 'twoFactor'>(
    reason === '2fa_required' ? 'twoFactor' : 'credentials',
  );
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function clearServerSession() {
    await axios.post('/api/auth/sign-out').catch(() => null);
    await axios.post('/api/auth/2fa/clear').catch(() => null);
  }

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

      // Persist tokens first so same-origin /api/proxy can forward to backend.
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
        const bodyText =
          typeof tokenRes.data === 'string'
            ? tokenRes.data
            : JSON.stringify(tokenRes.data ?? '');
        setError(
          bodyText
            ? `Session setup failed [${tokenRes.status}]: ${String(bodyText)}`
            : `Session setup failed [${tokenRes.status}]. Please try again.`,
        );
        await supabase.auth.signOut();
        await clearServerSession();
        return;
      }

      // Verify the user has panel-access role through same-origin proxy.
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

      const twoFactorRes = await axios.get<{
        eligible: boolean;
        challengeRequired: boolean;
      }>('/api/proxy/admin/security/2fa/preflight', {
        validateStatus: () => true,
      });

      if (twoFactorRes.status < 200 || twoFactorRes.status >= 300) {
        setError('Could not evaluate two-factor authentication requirements.');
        await supabase.auth.signOut();
        await clearServerSession();
        return;
      }

      if (twoFactorRes.data?.challengeRequired) {
        setStage('twoFactor');
        setTwoFactorCode('');
        setRecoveryCode('');
        setUseRecoveryCode(false);
        setError(null);
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
    setLoading(true);

    try {
      const payload = useRecoveryCode
        ? { recoveryCode: recoveryCode.trim() }
        : { code: twoFactorCode.trim() };

      const verifyRes = await axios.post('/api/auth/2fa/verify', payload, {
        validateStatus: () => true,
      });

      if (verifyRes.status < 200 || verifyRes.status >= 300) {
        const detail =
          typeof verifyRes.data === 'string'
            ? verifyRes.data
            : JSON.stringify(verifyRes.data ?? {});
        setError(
          `Two-factor verification failed${
            detail ? `: ${String(detail)}` : '.'
          }`,
        );
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

  async function backToCredentials() {
    setLoading(true);
    setError(null);
    try {
      await supabase.auth.signOut();
      await clearServerSession();
      setStage('credentials');
      setTwoFactorCode('');
      setRecoveryCode('');
      setUseRecoveryCode(false);
    } finally {
      setLoading(false);
    }
  }

  return (
    <form
      onSubmit={stage === 'credentials' ? handleCredentialsSubmit : handleTwoFactorSubmit}
      className='space-y-4'
    >
      {error && (
        <Alert variant='destructive'>
          <AlertCircle className='h-4 w-4' />
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      {stage === 'credentials' ? (
        <>
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
        </>
      ) : (
        <>
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
              onChange={(event) => setUseRecoveryCode(event.target.value === 'recovery')}
              disabled={loading}
              className='h-10 w-full rounded-md border border-input bg-background px-3 text-sm'
            >
              <option value='totp'>Authenticator code</option>
              <option value='recovery'>Recovery code</option>
            </select>
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
        </>
      )}

      <Button type='submit' className='w-full' disabled={loading}>
        {loading && <Loader2 className='h-4 w-4 animate-spin' />}
        {loading
          ? stage === 'credentials'
            ? 'Signing in…'
            : 'Verifying…'
          : stage === 'credentials'
            ? 'Sign In'
            : 'Verify 2FA'}
      </Button>

      {stage === 'twoFactor' && (
        <Button
          type='button'
          variant='outline'
          className='w-full'
          onClick={() => void backToCredentials()}
          disabled={loading}
        >
          Use a different account
        </Button>
      )}
    </form>
  );
}
