'use client';

import Link from 'next/link';

export function CTA() {
  return (
    <section className="py-12 sm:py-16 md:py-20 px-4 sm:px-6 lg:px-8 bg-surface relative overflow-hidden">
      {/* Background Pattern */}
      <div className="absolute inset-0 opacity-5">
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#2dd4bf_1px,transparent_1px),linear-gradient(to_bottom,#2dd4bf_1px,transparent_1px)] bg-[size:6rem_6rem]" />
      </div>

      <div className="relative z-10 max-w-4xl mx-auto text-center">
        <h2 className="text-2xl sm:text-3xl md:text-4xl font-bold text-foreground mb-4 sm:mb-5">
          Ready to Join <span className="text-teal-400">Blocnet?</span>
        </h2>

        <p className="text-sm sm:text-base text-muted mb-6 sm:mb-8 max-w-2xl mx-auto">
          Start earning through mining, track your favorite projects, manage
          your crypto assets, and connect with a global community of crypto
          enthusiasts.
        </p>

        <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center items-center mb-8 sm:mb-10">
          <a
            href="#"
            className="w-full sm:w-auto px-6 py-3 sm:px-7 sm:py-3.5 bg-teal-500 text-white rounded-lg font-medium text-sm sm:text-base"
          >
            Download for iOS
          </a>
          <a
            href="#"
            className="w-full sm:w-auto px-6 py-3 sm:px-7 sm:py-3.5 bg-surface-2 text-foreground border border-border rounded-lg font-medium text-sm sm:text-base"
          >
            Download for Android
          </a>
        </div>

        <div className="flex flex-wrap justify-center items-center gap-4 sm:gap-6 text-xs sm:text-sm text-muted">
          <div className="flex items-center gap-1.5 sm:gap-2">
            <span className="text-teal-400">✓</span>
            <span>Free to use</span>
          </div>
          <div className="flex items-center gap-1.5 sm:gap-2">
            <span className="text-teal-400">✓</span>
            <span>No credit card</span>
          </div>
          <div className="flex items-center gap-1.5 sm:gap-2">
            <span className="text-teal-400">✓</span>
            <span>10K+ users</span>
          </div>
        </div>
      </div>
    </section>
  );
}
