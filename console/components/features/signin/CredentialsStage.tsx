'use client';

import { Loader2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

type CredentialsStageProps = {
  email: string;
  password: string;
  loading: boolean;
  onEmailChange: (value: string) => void;
  onPasswordChange: (value: string) => void;
  onSubmit: (event: React.FormEvent) => Promise<void>;
};

export function CredentialsStage({
  email,
  password,
  loading,
  onEmailChange,
  onPasswordChange,
  onSubmit,
}: CredentialsStageProps) {
  return (
    <form onSubmit={(event) => void onSubmit(event)} className='space-y-4'>
      <div className='space-y-2'>
        <Label htmlFor='email'>Email</Label>
        <Input
          id='email'
          type='email'
          placeholder='admin@blocnet.io'
          value={email}
          onChange={(event) => onEmailChange(event.target.value)}
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
          onChange={(event) => onPasswordChange(event.target.value)}
          required
          disabled={loading}
        />
      </div>

      <Button type='submit' className='w-full' disabled={loading}>
        {loading ? <Loader2 className='h-4 w-4 animate-spin' /> : null}
        {loading ? 'Signing in…' : 'Sign In'}
      </Button>
    </form>
  );
}
