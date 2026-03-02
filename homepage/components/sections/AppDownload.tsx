'use client';

import { useState } from 'react';

const androidVersion = process.env.NEXT_PUBLIC_ANDROID_VERSION;

export function AppDownload() {
  const [isDownloading, setIsDownloading] = useState(false);
  const [modalMessage, setModalMessage] = useState<string | null>(null);

  async function handleDownload() {
    if (isDownloading) return;

    setIsDownloading(true);
    setModalMessage(null);

    try {
      const availability = await fetch('/api/download/apk', {
        method: 'HEAD',
        cache: 'no-store',
      });

      if (!availability.ok) {
        setModalMessage(
          'Android APK is not available right now. Please check back soon.'
        );
        setIsDownloading(false);
        return;
      }

      // Create a hidden anchor tag and trigger native browser download
      const anchor = document.createElement('a');
      anchor.href = '/api/download/apk';
      anchor.download = 'blocnet-latest.apk';
      anchor.style.display = 'none';
      document.body.appendChild(anchor);
      anchor.click();

      // Clean up after a short delay
      setTimeout(() => {
        anchor.remove();
        setIsDownloading(false);
      }, 100);
    } catch {
      setModalMessage('Unable to start APK download right now. Please try again.');
      setIsDownloading(false);
    }
  }

  const features = [
    {
      icon: '🚀',
      title: 'Lightning Fast',
      desc: 'Optimized performance for smooth navigation',
    },
    {
      icon: '🔒',
      title: 'Secure Wallet',
      desc: 'Multi-asset custody with bank-level security',
    },
    {
      icon: '⛏️',
      title: 'Mining Ready',
      desc: 'Start earning BNT with one tap',
    },
    {
      icon: '🤖',
      title: 'AI-Powered',
      desc: 'BEE intelligence at your fingertips',
    },
  ];

  return (
    <section
      id="download"
      className="py-16 sm:py-20 md:py-28 px-4 sm:px-6 lg:px-8 bg-linear-to-b from-[#09090b] via-teal-950/5 to-[#09090b] relative overflow-hidden"
    >
      {/* Background */}
      <div className="absolute inset-0">
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#27272a_1px,transparent_1px),linear-gradient(to_bottom,#27272a_1px,transparent_1px)] bg-[size:4rem_4rem] opacity-20" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-teal-500/10 rounded-full blur-3xl" />
      </div>

      <div className="relative z-10 max-w-7xl mx-auto">
        {/* Header */}
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-teal-500/10 border border-teal-500/20 rounded-full mb-6">
            <span className="text-2xl">📱</span>
            <span className="text-base font-semibold text-teal-400">
              Get Started Today
            </span>
          </div>

          <h2 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold text-foreground mb-6">
            Download the{' '}
            <span className="text-transparent bg-clip-text bg-linear-to-r from-teal-400 to-primary">
              Blocnet App
            </span>
          </h2>
          <p className="text-base sm:text-lg md:text-xl text-muted max-w-3xl mx-auto">
            Your gateway to AI-powered crypto intelligence, mining rewards, and community-driven insights
          </p>
        </div>

        <div className="grid lg:grid-cols-2 gap-12 items-center max-w-6xl mx-auto">
          {/* Left Side - Features */}
          <div>
            <div className="grid sm:grid-cols-2 gap-5 mb-10">
              {features.map((feature, index) => (
                <div
                  key={index}
                  className="p-6 bg-linear-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-border rounded-xl transition-colors hover:border-teal-500/30"
                >
                  <div className="text-4xl mb-3">{feature.icon}</div>
                  <h3 className="text-lg font-bold text-foreground mb-2">
                    {feature.title}
                  </h3>
                  <p className="text-sm text-muted">{feature.desc}</p>
                </div>
              ))}
            </div>

            {/* Stats */}
            <div className="grid grid-cols-3 gap-4">
              {[
                { value: '10K+', label: 'Downloads' },
                { value: '4.8★', label: 'Rating' },
                { value: '24/7', label: 'Support' },
              ].map((stat, index) => (
                <div
                  key={index}
                  className="text-center p-5 bg-surface-2/50 backdrop-blur-sm border border-border rounded-xl"
                >
                  <div className="text-2xl font-bold text-transparent bg-clip-text bg-linear-to-r from-teal-400 to-primary mb-1">
                    {stat.value}
                  </div>
                  <div className="text-sm text-muted">{stat.label}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Right Side - Download Card */}
          <div>
            <div className="p-8 bg-linear-to-br from-teal-500/10 to-primary/10 backdrop-blur-sm border-2 border-teal-500/30 rounded-2xl">
              <div className="flex flex-wrap items-center gap-3 mb-6">
                <span className="px-4 py-2 rounded-full bg-surface-2/50 border border-border text-sm font-semibold text-foreground">
                  Android APK
                </span>
                {androidVersion && (
                  <span className="px-4 py-2 rounded-full bg-teal-500/20 border border-teal-500/30 text-sm font-semibold text-teal-400">
                    v{androidVersion}
                  </span>
                )}
                <span className="px-4 py-2 rounded-full bg-green-500/20 border border-green-500/30 text-sm font-semibold text-green-400">
                  Latest
                </span>
              </div>

              <button
                type="button"
                onClick={handleDownload}
                disabled={isDownloading}
                className="w-full px-8 py-5 bg-linear-to-r from-teal-500 to-primary text-white rounded-xl font-bold text-lg shadow-lg shadow-teal-500/25 disabled:opacity-60 disabled:cursor-not-allowed flex items-center justify-center gap-3 transition-opacity hover:opacity-90"
              >
                {isDownloading ? (
                  <>
                    <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                    </svg>
                    <span>Preparing Download...</span>
                  </>
                ) : (
                  <>
                    <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                    </svg>
                    <span>Download for Android</span>
                  </>
                )}
              </button>

              <p className="mt-6 text-sm text-muted text-center">
                iOS version coming soon on App Store
              </p>

              {/* Additional Info */}
              <div className="mt-6 pt-6 border-t border-border space-y-3">
                <div className="flex items-center gap-3 text-sm">
                  <div className="w-8 h-8 bg-teal-500/20 rounded-lg flex items-center justify-center">
                    <span>✓</span>
                  </div>
                  <span className="text-muted">Safe and secure download</span>
                </div>
                <div className="flex items-center gap-3 text-sm">
                  <div className="w-8 h-8 bg-teal-500/20 rounded-lg flex items-center justify-center">
                    <span>✓</span>
                  </div>
                  <span className="text-muted">No registration required</span>
                </div>
                <div className="flex items-center gap-3 text-sm">
                  <div className="w-8 h-8 bg-teal-500/20 rounded-lg flex items-center justify-center">
                    <span>✓</span>
                  </div>
                  <span className="text-muted">Free to download and use</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {modalMessage && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/70 px-4">
          <div className="w-full max-w-sm rounded-2xl border border-border bg-surface p-5 sm:p-6 shadow-2xl">
            <h3 className="text-lg font-bold text-foreground mb-2">
              APK Not Available
            </h3>
            <p className="text-sm text-muted leading-relaxed">
              {modalMessage}
            </p>
            <button
              type="button"
              onClick={() => setModalMessage(null)}
              className="mt-5 w-full rounded-xl bg-linear-to-r from-teal-500 to-primary px-4 py-3 text-sm font-semibold text-white transition-opacity hover:opacity-90"
            >
              Okay
            </button>
          </div>
        </div>
      )}
    </section>
  );
}
