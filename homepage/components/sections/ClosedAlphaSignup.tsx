'use client';

import { FormEvent, useEffect, useMemo, useState } from 'react';

type Status = 'idle' | 'loading' | 'success' | 'error';

export function ClosedAlphaSignup() {
  const [enabled, setEnabled] = useState(false);
  const [loading, setLoading] = useState(true);
  const [email, setEmail] = useState('');
  const [status, setStatus] = useState<Status>('idle');
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    let active = true;

    async function loadStatus() {
      try {
        const response = await fetch('/api/closed-alpha/status', {
          method: 'GET',
          cache: 'no-store',
        });
        const payload = await response.json().catch(() => ({}));
        if (!active) return;
        setEnabled(payload?.enabled === true);
      } catch {
        if (!active) return;
        setEnabled(false);
      } finally {
        if (active) {
          setLoading(false);
        }
      }
    }

    void loadStatus();

    return () => {
      active = false;
    };
  }, []);

  const submitDisabled = useMemo(
    () => status === 'loading' || !enabled || email.trim().length === 0,
    [email, enabled, status],
  );

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const trimmedEmail = email.trim();
    if (!trimmedEmail || status === 'loading') return;

    setStatus('loading');
    setMessage(null);

    try {
      const response = await fetch('/api/closed-alpha/join', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: trimmedEmail }),
      });
      const payload = await response.json().catch(() => ({}));
      if (!response.ok) {
        setStatus('error');
        setMessage(
          typeof payload?.message === 'string'
            ? payload.message
            : 'Unable to submit right now.',
        );
        return;
      }

      setStatus('success');
      setEmail('');
      setMessage(
        typeof payload?.message === 'string'
          ? payload.message
          : 'Email submitted successfully.',
      );
    } catch {
      setStatus('error');
      setMessage('Unable to submit right now. Please try again.');
    }
  }

  return (
    <section className="py-10 sm:py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-5xl mx-auto rounded-2xl border border-teal-500/30 bg-linear-to-r from-teal-500/10 via-surface to-primary/10 p-6 sm:p-8 shadow-[0_0_0_1px_rgba(45,212,191,0.12)]">
        <p className="text-xs uppercase tracking-[0.18em] text-teal-300 mb-2 font-semibold">
          Closed Alpha
        </p>
        <h2 className="text-2xl sm:text-3xl md:text-4xl font-semibold text-foreground">
          Closed alpha access is live
        </h2>
        <p className="text-sm sm:text-base text-muted mt-3 max-w-3xl">
          Submit your email to request access. Only allowlisted testers can
          sign in during this phase.
        </p>

        {loading ? (
          <p className="text-sm text-muted mt-4">Checking availability...</p>
        ) : enabled ? (
          <form onSubmit={onSubmit} className="mt-5 flex flex-col sm:flex-row gap-3">
            <input
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder="you@domain.com"
              className="flex-1 rounded-xl border border-border bg-[#0f0f12] px-4 py-3 text-sm text-foreground outline-none focus:border-teal-500/60"
              required
            />
            <button
              type="submit"
              disabled={submitDisabled}
              className="rounded-xl bg-teal-500 px-5 py-3 text-sm font-semibold text-white disabled:opacity-60"
            >
              {status === 'loading' ? 'Submitting...' : 'Join Closed Alpha'}
            </button>
          </form>
        ) : (
          <p className="text-sm text-muted mt-4">
            Closed alpha requests are currently paused.
          </p>
        )}

        {message ? (
          <p
            className={`mt-3 text-sm ${
              status === 'error' ? 'text-red-400' : 'text-teal-300'
            }`}
          >
            {message}
          </p>
        ) : null}
      </div>
    </section>
  );
}
