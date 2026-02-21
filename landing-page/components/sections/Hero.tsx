'use client';

import Link from 'next/link';

export function Hero() {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden px-4 sm:px-6 lg:px-8">
      {/* Simple Background Grid */}
      <div className="absolute inset-0 bg-[#09090b]">
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#27272a_1px,transparent_1px),linear-gradient(to_bottom,#27272a_1px,transparent_1px)] bg-[size:4rem_4rem] [mask-image:radial-gradient(ellipse_80%_50%_at_50%_0%,#000_70%,transparent_110%)]" />
      </div>

      {/* Content */}
      <div className="relative z-10 max-w-5xl mx-auto text-center">
        <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold text-foreground mb-3 sm:mb-4 md:mb-6 leading-tight">
          Your <span className="text-teal-400">Crypto Hub</span>
          <br />
          All in One Place
        </h1>

        <p className="text-sm sm:text-base md:text-lg text-muted max-w-2xl mx-auto mb-4 sm:mb-6 px-4">
          Track projects, earn through mining, manage your wallet, and join a
          thriving community. Everything you need to stay ahead in crypto.
        </p>

        <div className="inline-block mb-6 sm:mb-8">
          <span className="text-xs sm:text-sm px-3 py-1.5 sm:px-4 sm:py-2 bg-teal-500/10 border border-teal-500/20 rounded-full text-teal-400">
            Crypto Update Network
          </span>
        </div>

        <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center items-center">
          <Link
            href="#"
            className="w-full sm:w-auto px-5 py-2.5 sm:px-6 sm:py-3 bg-teal-500 text-white rounded-lg font-medium text-sm sm:text-base"
          >
            Download App
          </Link>
          <Link
            href="#features"
            className="w-full sm:w-auto px-5 py-2.5 sm:px-6 sm:py-3 bg-surface-2 text-foreground rounded-lg font-medium text-sm sm:text-base"
          >
            Explore Features
          </Link>
        </div>

        {/* Stats */}
        <div className="mt-12 sm:mt-16 md:mt-20 grid grid-cols-2 md:grid-cols-4 gap-4 sm:gap-6">
          {[
            { label: 'Active Users', value: '10K+' },
            { label: 'Projects Tracked', value: '500+' },
            { label: 'Updates Daily', value: '1K+' },
            { label: 'Community Posts', value: '5K+' },
          ].map((stat) => (
            <div
              key={stat.label}
              className="p-4 sm:p-5 bg-surface-2/50 backdrop-blur-sm border border-border rounded-lg"
            >
              <div className="text-xl sm:text-2xl font-bold text-teal-400">
                {stat.value}
              </div>
              <div className="text-xs sm:text-sm text-muted mt-1">
                {stat.label}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
