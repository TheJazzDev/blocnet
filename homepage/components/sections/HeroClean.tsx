'use client';

import Link from 'next/link';

export function HeroClean() {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden px-4 sm:px-6 lg:px-8">
      {/* Background Grid */}
      <div className="absolute inset-0 bg-[#09090b]">
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#27272a_1px,transparent_1px),linear-gradient(to_bottom,#27272a_1px,transparent_1px)] bg-[size:4rem_4rem] [mask-image:radial-gradient(ellipse_80%_50%_at_50%_0%,#000_70%,transparent_110%)]" />
      </div>

      {/* Content */}
      <div className="relative z-10 max-w-5xl mx-auto text-center">
        {/* Badges */}
        <div className="flex flex-wrap gap-3 justify-center mb-6">
          <span className="text-sm sm:text-base px-4 py-2 bg-teal-500/10 border border-teal-500/20 rounded-full text-teal-400 backdrop-blur-sm">
            ✨ AI-Powered Intelligence
          </span>
          <span className="text-sm sm:text-base px-4 py-2 bg-primary/10 border border-primary/20 rounded-full text-primary backdrop-blur-sm">
            🌐 Crypto Update Network
          </span>
        </div>

        {/* Title */}
        <h1 className="text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-bold text-foreground mb-6 leading-tight">
          Your <span className="text-transparent bg-clip-text bg-linear-to-r from-teal-400 to-primary">Crypto Hub</span>
          <br />
          All in One Place
        </h1>

        {/* Subtitle */}
        <p className="text-base sm:text-lg md:text-xl text-muted max-w-3xl mx-auto mb-10 px-4 leading-relaxed">
          AI-powered crypto intelligence meets community-driven updates. Track
          projects, earn through mining, manage your wallet, and get smart
          recommendations from Blocnet Edge Engine (BEE).
        </p>

        {/* CTA Buttons */}
        <div className="flex flex-col sm:flex-row gap-4 justify-center items-center mb-16">
          <Link
            href="#download"
            className="w-full sm:w-auto px-8 py-4 bg-linear-to-r from-teal-500 to-primary text-white rounded-xl font-semibold text-base shadow-lg shadow-teal-500/25 transition-opacity hover:opacity-90"
          >
            Download App
          </Link>
          <Link
            href="/about"
            className="w-full sm:w-auto px-8 py-4 bg-surface-2/50 backdrop-blur-sm border border-border text-foreground rounded-xl font-semibold text-base transition-colors hover:border-teal-500/30"
          >
            Learn More
          </Link>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-5">
          {[
            { value: '10K+', label: 'Active Users' },
            { value: '500+', label: 'Projects Tracked' },
            { value: '1K+', label: 'Updates Daily' },
            { value: '5K+', label: 'Community Posts' },
          ].map((stat) => (
            <div
              key={stat.label}
              className="p-6 bg-surface-2/50 backdrop-blur-sm border border-border rounded-xl transition-colors hover:border-teal-500/20"
            >
              <div className="text-3xl sm:text-4xl font-bold text-transparent bg-clip-text bg-linear-to-r from-teal-400 to-primary">
                {stat.value}
              </div>
              <div className="text-sm sm:text-base text-muted mt-2">
                {stat.label}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
