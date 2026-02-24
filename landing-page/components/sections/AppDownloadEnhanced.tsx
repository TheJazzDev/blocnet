'use client';

import { useState, useRef } from 'react';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { useGSAP } from '@gsap/react';

gsap.registerPlugin(ScrollTrigger);

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

export function AppDownloadEnhanced() {
  const [isDownloading, setIsDownloading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const phoneRef = useRef<HTMLDivElement>(null);

  useGSAP(() => {
    if (!containerRef.current) return;

    // Animate header
    gsap.from('.download-header', {
      opacity: 0,
      y: 50,
      duration: 0.8,
      scrollTrigger: {
        trigger: containerRef.current,
        start: 'top 70%',
      },
    });

    // Animate phone mockup
    if (phoneRef.current) {
      gsap.from(phoneRef.current, {
        opacity: 0,
        scale: 0.8,
        rotation: -10,
        duration: 1,
        ease: 'back.out(1.5)',
        scrollTrigger: {
          trigger: phoneRef.current,
          start: 'top 75%',
        },
      });

      // Float animation
      gsap.to(phoneRef.current, {
        y: -20,
        duration: 2,
        repeat: -1,
        yoyo: true,
        ease: 'sine.inOut',
      });
    }

    // Animate feature cards
    gsap.from('.feature-card', {
      opacity: 0,
      x: -30,
      duration: 0.6,
      stagger: 0.15,
      scrollTrigger: {
        trigger: '.features-list',
        start: 'top 75%',
      },
    });

    // Animate stats
    gsap.from('.download-stat', {
      opacity: 0,
      scale: 0.8,
      duration: 0.5,
      stagger: 0.1,
      ease: 'back.out(1.7)',
      scrollTrigger: {
        trigger: '.stats-grid',
        start: 'top 80%',
      },
    });
  }, { scope: containerRef });

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
      ref={containerRef}
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
        <div className="download-header text-center mb-12 sm:mb-16">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-teal-500/10 border border-teal-500/20 rounded-full mb-4 sm:mb-6">
            <span className="text-xl sm:text-2xl">📱</span>
            <span className="text-sm sm:text-base font-semibold text-teal-400">
              Get Started Today
            </span>
          </div>

          <h2 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold text-foreground mb-4 sm:mb-6">
            Download the{' '}
            <span className="text-transparent bg-clip-text bg-linear-to-r from-teal-400 to-primary">
              Blocnet App
            </span>
          </h2>
          <p className="text-base sm:text-lg md:text-xl text-muted max-w-3xl mx-auto">
            Your gateway to AI-powered crypto intelligence, mining rewards, and community-driven insights
          </p>
        </div>

        <div className="grid lg:grid-cols-2 gap-10 sm:gap-12 lg:gap-16 items-center">
          {/* Left Side - Phone Mockup */}
          <div className="flex justify-center lg:justify-end">
            <div ref={phoneRef} className="relative">
              {/* Phone Frame */}
              <div className="w-72 sm:w-80 md:w-96 h-[600px] sm:h-[650px] md:h-[700px] bg-linear-to-br from-gray-900 to-gray-800 rounded-[3rem] p-4 shadow-2xl shadow-teal-500/20 border-8 border-gray-900 relative overflow-hidden">
                {/* Notch */}
                <div className="absolute top-0 left-1/2 -translate-x-1/2 w-40 h-7 bg-gray-900 rounded-b-3xl z-10" />

                {/* Screen Content */}
                <div className="w-full h-full bg-linear-to-br from-[#0a0a0b] to-[#1a1a1f] rounded-[2.5rem] overflow-hidden relative">
                  {/* Gradient Overlay */}
                  <div className="absolute inset-0 bg-linear-to-br from-teal-500/20 to-primary/20" />

                  {/* Mock Content */}
                  <div className="relative p-6 h-full flex flex-col">
                    <div className="text-center mt-8 mb-6">
                      <div className="text-4xl mb-3">🐝</div>
                      <div className="text-2xl font-bold text-white mb-2">Blocnet</div>
                      <div className="text-sm text-teal-400">Edge Engine Active</div>
                    </div>

                    <div className="flex-1 space-y-3">
                      <div className="p-4 bg-surface-2/50 backdrop-blur-sm rounded-xl border border-teal-500/20">
                        <div className="text-xs text-muted mb-1">Mining Status</div>
                        <div className="text-lg font-bold text-teal-400">Active</div>
                      </div>
                      <div className="p-4 bg-surface-2/50 backdrop-blur-sm rounded-xl border border-border">
                        <div className="text-xs text-muted mb-1">BNT Balance</div>
                        <div className="text-lg font-bold text-white">1,250.50</div>
                      </div>
                      <div className="p-4 bg-surface-2/50 backdrop-blur-sm rounded-xl border border-border">
                        <div className="text-xs text-muted mb-1">Updates Today</div>
                        <div className="text-lg font-bold text-white">42</div>
                      </div>
                    </div>

                    <div className="mt-4 p-4 bg-linear-to-r from-teal-500 to-primary rounded-xl text-center">
                      <div className="text-sm font-semibold text-white">Start Mining</div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Floating Elements */}
              <div className="absolute -top-8 -right-8 w-20 h-20 bg-teal-500/20 rounded-full blur-xl animate-pulse" />
              <div className="absolute -bottom-8 -left-8 w-24 h-24 bg-primary/20 rounded-full blur-xl animate-pulse" style={{ animationDelay: '1s' }} />
            </div>
          </div>

          {/* Right Side - Download Info */}
          <div>
            {/* Features */}
            <div className="features-list grid sm:grid-cols-2 gap-4 mb-8 sm:mb-10">
              {features.map((feature, index) => (
                <div
                  key={index}
                  className="feature-card p-5 bg-linear-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-border rounded-xl hover:border-teal-500/30 transition-all duration-300"
                >
                  <div className="text-3xl mb-3">{feature.icon}</div>
                  <h3 className="text-base sm:text-lg font-bold text-foreground mb-1">
                    {feature.title}
                  </h3>
                  <p className="text-sm text-muted">{feature.desc}</p>
                </div>
              ))}
            </div>

            {/* Download Button */}
            <div className="p-6 sm:p-8 bg-linear-to-br from-teal-500/10 to-primary/10 backdrop-blur-sm border-2 border-teal-500/30 rounded-2xl mb-6 sm:mb-8">
              <div className="flex flex-wrap items-center gap-3 mb-5">
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
                onClick={() => void handleDownload()}
                disabled={isDownloading}
                className="group w-full px-8 py-5 bg-linear-to-r from-teal-500 to-primary text-white rounded-xl font-bold text-base sm:text-lg shadow-lg shadow-teal-500/25 hover:shadow-teal-500/40 transition-all duration-300 hover:scale-105 disabled:opacity-60 disabled:cursor-not-allowed disabled:hover:scale-100 relative overflow-hidden"
              >
                <span className="relative z-10 flex items-center justify-center gap-3">
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
                </span>
                <div className="absolute inset-0 bg-linear-to-r from-teal-400 to-purple-500 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
              </button>

              {error && (
                <div className="mt-4 p-4 bg-red-500/10 border border-red-500/20 rounded-lg">
                  <p className="text-sm text-red-400">{error}</p>
                </div>
              )}

              <p className="mt-4 text-xs sm:text-sm text-muted text-center">
                iOS version coming soon on App Store
              </p>
            </div>

            {/* Stats */}
            <div className="stats-grid grid grid-cols-3 gap-3 sm:gap-4">
              {[
                { value: '10K+', label: 'Downloads' },
                { value: '4.8★', label: 'Rating' },
                { value: '24/7', label: 'Support' },
              ].map((stat, index) => (
                <div
                  key={index}
                  className="download-stat text-center p-4 bg-surface-2/50 backdrop-blur-sm border border-border rounded-xl"
                >
                  <div className="text-xl sm:text-2xl font-bold text-transparent bg-clip-text bg-linear-to-r from-teal-400 to-primary mb-1">
                    {stat.value}
                  </div>
                  <div className="text-xs sm:text-sm text-muted">{stat.label}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
