'use client';

import Link from 'next/link';

export function RoadmapPreview() {
  const currentPhase = {
    phase: 'Phase 2',
    title: 'AI Intelligence & Mining',
    status: 'In Progress',
    timeline: 'Q1 2026',
    progress: 65,
    items: [
      { text: 'Blocnet Edge Engine (BEE) AI system', done: true },
      { text: 'Cycling mining mechanism', done: true },
      { text: 'Referral network & downline tracking', done: true },
      { text: 'Multi-asset wallet infrastructure', done: false },
      { text: 'Community growth to 500+ users', done: false },
    ],
  };

  const upcomingPhases = [
    {
      phase: 'Phase 3',
      title: 'Wallet & Token Economy',
      timeline: 'Q2 2026',
      highlights: ['BNT Token Launch', 'Multi-Asset Wallet', 'Mining Airdrops'],
    },
    {
      phase: 'Phase 4',
      title: 'Monetization & Growth',
      timeline: 'Q3 2026',
      highlights: ['Sponsored Listings', 'Premium Features', 'App Store Launch'],
    },
  ];

  return (
    <section className="py-12 sm:py-16 md:py-20 px-4 sm:px-6 lg:px-8 bg-[#09090b] relative overflow-hidden">
      {/* Background Effects */}
      <div className="absolute inset-0">
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#27272a_1px,transparent_1px),linear-gradient(to_bottom,#27272a_1px,transparent_1px)] bg-[size:4rem_4rem] opacity-20" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-teal-500/10 rounded-full blur-3xl" />
      </div>

      <div className="relative z-10 max-w-6xl mx-auto">
        {/* Header */}
        <div className="text-center mb-10 sm:mb-12">
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-bold text-foreground mb-3 sm:mb-4">
            Our <span className="text-transparent bg-clip-text bg-gradient-to-r from-teal-400 to-primary">Roadmap</span>
          </h2>
          <p className="text-sm sm:text-base text-muted max-w-2xl mx-auto">
            Track our progress from concept to global scale. See what we've built and what's coming next.
          </p>
        </div>

        {/* Current Phase - Highlighted */}
        <div className="p-6 sm:p-8 bg-gradient-to-br from-teal-500/10 to-primary/10 border-2 border-teal-500/30 rounded-2xl mb-6 sm:mb-8 shadow-lg shadow-teal-500/10">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-4 sm:mb-6">
            <div>
              <div className="flex items-center gap-3 mb-2">
                <span className="text-sm sm:text-base font-bold text-teal-300">{currentPhase.phase}</span>
                <span className="px-3 py-1 bg-amber-400/20 border border-amber-400/30 rounded-full text-xs font-semibold text-amber-400">
                  {currentPhase.status}
                </span>
              </div>
              <h3 className="text-lg sm:text-xl md:text-2xl font-bold text-foreground">
                {currentPhase.title}
              </h3>
            </div>
            <div className="text-left sm:text-right">
              <p className="text-xs sm:text-sm text-muted mb-1">Timeline</p>
              <p className="text-sm sm:text-base font-semibold text-teal-400">{currentPhase.timeline}</p>
            </div>
          </div>

          {/* Progress Bar */}
          <div className="mb-4 sm:mb-6">
            <div className="flex justify-between items-center mb-2">
              <span className="text-xs sm:text-sm text-muted">Overall Progress</span>
              <span className="text-xs sm:text-sm font-semibold text-teal-400">{currentPhase.progress}%</span>
            </div>
            <div className="h-2 sm:h-3 bg-surface-2 rounded-full overflow-hidden">
              <div
                className="h-full bg-gradient-to-r from-teal-400 to-primary"
                style={{ width: `${currentPhase.progress}%` }}
              />
            </div>
          </div>

          {/* Items Grid */}
          <div className="grid sm:grid-cols-2 gap-2 sm:gap-3">
            {currentPhase.items.map((item, index) => (
              <div key={index} className="flex items-center gap-2 sm:gap-3 text-xs sm:text-sm">
                <div className={`shrink-0 w-5 h-5 rounded-full flex items-center justify-center ${
                  item.done
                    ? 'bg-green-400/20 border-2 border-green-400'
                    : 'bg-surface-2 border-2 border-border'
                }`}>
                  {item.done && (
                    <svg className="w-3 h-3 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                    </svg>
                  )}
                </div>
                <span className={item.done ? 'text-foreground' : 'text-muted'}>{item.text}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Upcoming Phases */}
        <div className="grid sm:grid-cols-2 gap-4 sm:gap-6 mb-8 sm:mb-10">
          {upcomingPhases.map((phase) => (
            <div key={phase.phase} className="p-5 sm:p-6 bg-gradient-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-border rounded-2xl">
              <div className="flex items-center gap-3 mb-3 sm:mb-4">
                <div className="shrink-0 w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-teal-500/20 to-primary/20 rounded-xl flex items-center justify-center border border-teal-500/30">
                  <span className="text-sm sm:text-base font-bold text-teal-300">
                    {phase.phase.replace('Phase ', '')}
                  </span>
                </div>
                <div>
                  <h4 className="text-base sm:text-lg font-bold text-foreground">{phase.title}</h4>
                  <p className="text-xs sm:text-sm text-teal-400">{phase.timeline}</p>
                </div>
              </div>
              <div className="space-y-2">
                {phase.highlights.map((highlight, index) => (
                  <div key={index} className="flex items-center gap-2 text-xs sm:text-sm text-muted">
                    <div className="shrink-0 w-1.5 h-1.5 bg-teal-400 rounded-full" />
                    {highlight}
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>

        {/* CTA */}
        <div className="text-center">
          <Link
            href="/roadmap"
            className="inline-flex items-center gap-2 px-5 py-2.5 sm:px-6 sm:py-3 bg-gradient-to-r from-teal-500/10 to-primary/10 border border-teal-500/20 text-foreground rounded-xl font-semibold text-sm sm:text-base"
          >
            View Full Roadmap
            <svg className="w-4 h-4 sm:w-5 sm:h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </Link>
        </div>
      </div>
    </section>
  );
}
