'use client';

import { useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
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

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);

    console.log('🔐 Sign-in started');
    console.log('🌍 NEXT_PUBLIC_API_URL:', process.env.NEXT_PUBLIC_API_URL);
    console.log('➡️ nextPath:', nextPath);

    try {
      const { data, error: signInError } =
        await supabase.auth.signInWithPassword({ email, password });

      console.log('📦 Supabase response:', { data, signInError });

      if (signInError || !data.session) {
        console.error('❌ Supabase sign-in failed:', signInError);
        setError(
          signInError?.message ?? 'Sign in failed. Check your credentials.',
        );
        return;
      }

      const { access_token, refresh_token } = data.session;

      console.log('✅ Supabase session received');
      console.log('🪪 Access token exists:', !!access_token);
      console.log('🔄 Refresh token exists:', !!refresh_token);

      // Verify user role
      const apiUrl = `${process.env.NEXT_PUBLIC_API_URL}/me`;
      console.log('📡 Calling backend:', apiUrl);

      const res = await fetch(apiUrl, {
        headers: { Authorization: `Bearer ${access_token}` },
      });

      console.log('📡 /me response status:', res.status);

      if (!res.ok) {
        const errorText = await res.text();
        console.error('❌ /me failed:', {
          status: res.status,
          body: errorText,
        });

        setError('Could not verify your account. Please try again.');
        await supabase.auth.signOut();
        return;
      }

      const profile = await res.json();
      console.log('👤 Profile response:', profile);

      const hasAccess =
        profile.roles?.includes('owner') ||
        profile.roles?.includes('admin') ||
        profile.roles?.includes('moderator');

      console.log('🔐 Access check result:', hasAccess);

      if (!hasAccess) {
        console.warn('⛔ User lacks required role');
        setError(
          'Access denied. Only owners, admins, and moderators can access this panel.',
        );
        await supabase.auth.signOut();
        return;
      }

      console.log('🍪 Persisting tokens via /api/auth/set-token');

      const tokenRes = await fetch('/api/auth/set-token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          token: access_token,
          refreshToken: refresh_token,
        }),
      });

      console.log('🍪 Token persistence status:', tokenRes.status);

      if (!tokenRes.ok) {
        const tokenError = await tokenRes.text();
        console.error('❌ Token persistence failed:', tokenError);

        setError('Session setup failed. Please try again.');
        return;
      }

      console.log('🚀 Redirecting to:', nextPath);

      router.push(nextPath.startsWith('/') ? nextPath : '/dashboard');
      router.refresh();
    } catch (err) {
      console.error('💥 Unexpected error:', err);
      setError('An unexpected error occurred. Please try again.');
    } finally {
      setLoading(false);
      console.log('🏁 Sign-in finished');
    }
  }

  return (
    <form onSubmit={handleSubmit} className='space-y-4'>
      {error && (
        <Alert variant='destructive'>
          <AlertCircle className='h-4 w-4' />
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

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
  );
}
