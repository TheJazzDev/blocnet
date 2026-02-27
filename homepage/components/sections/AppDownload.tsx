'use client';

import { useState } from 'react';

const androidVersion = process.env.NEXT_PUBLIC_ANDROID_VERSION;

function extractFilename(contentDisposition: string | null): string {
  if (!contentDisposition) {
    return 'blocnet-latest.apk';
  }

  const utfMatch = contentDisposition.match(/filename\*=UTF-8''([^;]+)/i);
  if (utfMatch?.[1]) {
    try {
      return decodeURIComponent(utfMatch[1]);
    } catch {
      return utfMatch[1];
    }
  }

  const plainMatch = contentDisposition.match(/filename="?([^"]+)"?/i);
  if (plainMatch?.[1]) {
    return plainMatch[1];
  }

  return 'blocnet-latest.apk';
}

export function AppDownload() {
  const [isDownloading, setIsDownloading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleDownload() {
    if (isDownloading) return;

    setIsDownloading(true);
    setError(null);

    try {
      const response = await fetch('/api/download/apk', {
        method: 'GET',
        cache: 'no-store',
      });

      if (!response.ok) {
        const message = await response.text();
        throw new Error(message || 'Failed to download APK.');
      }

      const blob = await response.blob();
      const filename = extractFilename(response.headers.get('content-disposition'));
      const objectUrl = window.URL.createObjectURL(blob);
      const anchor = document.createElement('a');

      anchor.href = objectUrl;
      anchor.download = filename;
      document.body.appendChild(anchor);
      anchor.click();
      anchor.remove();
      window.URL.revokeObjectURL(objectUrl);
    } catch (downloadError) {
      const message =
        downloadError instanceof Error
          ? downloadError.message
          : 'Unable to download APK right now.';
      setError(message);
    } finally {
      setIsDownloading(false);
    }
  }

  return (
    <section
      id='download'
      className='py-12 sm:py-16 md:py-20 px-4 sm:px-6 lg:px-8 bg-[#09090b] relative overflow-hidden'>
      <div className='absolute inset-0 bg-[linear-gradient(to_right,#27272a_1px,transparent_1px),linear-gradient(to_bottom,#27272a_1px,transparent_1px)] bg-size-[4rem_4rem] opacity-20' />

      <div className='relative z-10 max-w-5xl mx-auto'>
        <div className='text-center mb-8 sm:mb-10'>
          <h2 className='text-2xl sm:text-3xl md:text-4xl font-bold text-foreground mb-3 sm:mb-4'>
            Download Latest <span className='text-teal-400'>Blocnet App</span>
          </h2>
          <p className='text-sm sm:text-base text-muted max-w-2xl mx-auto'>
            This section always points to your active release channel.
          </p>
        </div>

        <div className='rounded-2xl border border-border bg-surface-2/60 p-5 sm:p-6 md:p-8'>
          <div className='flex flex-wrap items-center gap-2 mb-5'>
            <span className='text-xs sm:text-sm px-3 py-1 rounded-full border border-border text-muted'>
              Android APK
            </span>
            {androidVersion ? (
              <span className='text-xs sm:text-sm px-3 py-1 rounded-full border border-border text-foreground'>
                Version {androidVersion}
              </span>
            ) : null}
          </div>

          <div className='flex flex-col sm:flex-row gap-3'>
            <button
              type='button'
              onClick={() => void handleDownload()}
              disabled={isDownloading}
              className='w-full sm:w-auto px-6 py-3 sm:px-7 sm:py-3.5 bg-teal-500 text-white rounded-lg font-medium text-sm sm:text-base text-center disabled:opacity-60 disabled:cursor-not-allowed'>
              {isDownloading ? 'Preparing Download...' : 'Download Android APK'}
            </button>
          </div>

          {error ? (
            <p className='mt-4 text-xs sm:text-sm text-red-400'>{error}</p>
          ) : null}
        </div>
      </div>
    </section>
  );
}
