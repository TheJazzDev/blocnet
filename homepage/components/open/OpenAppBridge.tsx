'use client';

import { useEffect, useMemo } from 'react';
import Link from 'next/link';

function normalizePath(rawPath: string): string {
  const trimmed = rawPath.trim();
  if (!trimmed) return '/';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    try {
      const parsed = new URL(trimmed);
      return parsed.pathname.startsWith('/')
        ? `${parsed.pathname}${parsed.search}`
        : `/${parsed.pathname}${parsed.search}`;
    } catch {
      return '/';
    }
  }
  return trimmed.startsWith('/') ? trimmed : `/${trimmed}`;
}

function toSchemeUrl(path: string): string {
  const normalized = normalizePath(path);
  return `io.blocnet.app://${normalized.replace(/^\/+/, '')}`;
}

export function OpenAppBridge({ path }: { path: string }) {
  const normalizedPath = useMemo(() => normalizePath(path), [path]);
  const schemeUrl = useMemo(() => toSchemeUrl(normalizedPath), [normalizedPath]);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    window.location.href = schemeUrl;
  }, [schemeUrl]);

  return (
    <main className='min-h-screen bg-black text-white'>
      <div className='mx-auto flex min-h-screen w-full max-w-xl flex-col items-center justify-center px-6 py-10 text-center'>
        <h1 className='text-2xl font-semibold'>Opening Blocnet App...</h1>
        <p className='mt-3 text-sm text-zinc-300'>
          If the app did not open automatically, use the button below.
        </p>
        <div className='mt-8 flex w-full flex-col gap-3 sm:flex-row sm:justify-center'>
          <a
            href={schemeUrl}
            className='inline-flex items-center justify-center rounded-xl bg-cyan-500 px-5 py-3 text-sm font-semibold text-black transition-opacity hover:opacity-90'>
            Open App
          </a>
          <Link
            href='/#download'
            className='inline-flex items-center justify-center rounded-xl border border-zinc-700 px-5 py-3 text-sm font-semibold text-zinc-100 transition-colors hover:border-zinc-500'>
            Download App
          </Link>
        </div>
        <p className='mt-6 text-xs text-zinc-500'>Target path: {normalizedPath}</p>
      </div>
    </main>
  );
}
