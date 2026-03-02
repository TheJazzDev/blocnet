'use client';

export function RoadmapContent() {
  const phases = [
    {
      phase: 'Phase 0',
      title: 'Concept & Planning',
      status: 'Completed',
      timeline: 'Q3 2024',
      items: [
        { text: 'Market research & competitive analysis', done: true },
        { text: 'Product strategy & vision definition', done: true },
        { text: 'Technical architecture planning', done: true },
        { text: 'Tokenomics design & BNT utility model', done: true },
        { text: 'Brand identity & visual design system', done: true },
        { text: 'Team formation & role assignments', done: true },
      ],
    },
    {
      phase: 'Phase 1',
      title: 'Foundation & Launch',
      status: 'Completed',
      timeline: 'Q4 2024',
      items: [
        { text: 'Core platform development', done: true },
        { text: 'Hunter system & content curation', done: true },
        { text: 'Project discovery & tracking', done: true },
        { text: 'Community features & engagement', done: true },
        { text: 'Mobile app (Android APK)', done: true },
        { text: 'Landing page & branding', done: true },
      ],
    },
    {
      phase: 'Phase 2',
      title: 'AI Intelligence & Mining',
      status: 'In Progress',
      timeline: 'Q1 2026',
      items: [
        { text: 'Blocnet Edge Engine (BEE) AI decision system', done: true },
        { text: 'Cycling mining mechanism', done: true },
        { text: 'Referral network & downline tracking', done: true },
        { text: 'Mining leaderboard & competitions', done: true },
        { text: 'Multi-asset wallet infrastructure', done: false },
        { text: 'Initial community growth to 500+ users', done: false },
      ],
    },
    {
      phase: 'Phase 3',
      title: 'Wallet & Token Economy',
      status: 'Upcoming',
      timeline: 'Q2 2026',
      items: [
        { text: 'BNT token launch & liquidity provision', done: false },
        { text: 'Multi-asset wallet (BNT, USDT, SOL)', done: false },
        { text: 'Deposit & withdrawal system', done: false },
        { text: 'Hunter tipping with BNT', done: false },
        { text: 'Swap functionality', done: false },
        { text: 'Mining rewards airdrop to early members', done: false },
      ],
    },
    {
      phase: 'Phase 4',
      title: 'Monetization & Growth',
      status: 'Upcoming',
      timeline: 'Q3 2026',
      items: [
        { text: 'Sponsored project listings', done: false },
        { text: 'Premium hunter subscriptions', done: false },
        { text: 'Exchange affiliate partnerships', done: false },
        { text: 'Advanced analytics dashboard', done: false },
        { text: 'Play Store & App Store listings', done: false },
        { text: 'Community growth to 5,000+ users', done: false },
      ],
    },
    {
      phase: 'Phase 5',
      title: 'Ecosystem Expansion',
      status: 'Future',
      timeline: 'Q4 2026',
      items: [
        { text: 'Web3 jobs marketplace', done: false },
        { text: 'Educational courses & certifications', done: false },
        { text: 'DAO governance for platform decisions', done: false },
        { text: 'Cross-chain wallet support', done: false },
        { text: 'API for third-party integrations', done: false },
        { text: 'Strategic partnerships with major protocols', done: false },
      ],
    },
    {
      phase: 'Phase 6',
      title: 'Global Scale',
      status: 'Future',
      timeline: '2027',
      items: [
        { text: 'Multi-language support', done: false },
        { text: 'Regional community hubs', done: false },
        { text: 'Advanced AI features & personalization', done: false },
        { text: 'Mobile SDK for developers', done: false },
        { text: 'Enterprise solutions', done: false },
        { text: '100,000+ active users milestone', done: false },
      ],
    },
  ];

  return (
    <section className="py-16 sm:py-20 md:py-24 px-4 sm:px-6 lg:px-8 bg-[#09090b] relative overflow-hidden">
      {/* Background Effects */}
      <div className="absolute inset-0">
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#27272a_1px,transparent_1px),linear-gradient(to_bottom,#27272a_1px,transparent_1px)] bg-[size:4rem_4rem] opacity-20" />
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-teal-500/10 rounded-full blur-3xl" />
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-primary/10 rounded-full blur-3xl" />
      </div>

      <div className="relative z-10 max-w-6xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12 sm:mb-16">
          <h1 className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-bold text-foreground mb-3 sm:mb-4 md:mb-6">
            Building the Future of{' '}
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-teal-400 to-primary">
              Crypto Intelligence
            </span>
          </h1>

          <p className="text-sm sm:text-base md:text-lg text-muted max-w-3xl mx-auto leading-relaxed">
            Our journey from a simple content hub to the most intelligent
            crypto platform. Track our progress and see what is coming next.
          </p>
        </div>

        {/* Roadmap Timeline */}
        <div className="space-y-8 sm:space-y-10">
          {phases.map((phase, index) => {
            const isCompleted = phase.status === 'Completed';
            const isInProgress = phase.status === 'In Progress';
            const statusColor = isCompleted
              ? 'text-green-400 bg-green-400/10 border-green-400/30'
              : isInProgress
              ? 'text-amber-400 bg-amber-400/10 border-amber-400/30'
              : 'text-blue-400 bg-blue-400/10 border-blue-400/30';

            return (
              <div key={phase.phase} className="relative">
                {/* Connecting Line */}
                {index !== phases.length - 1 && (
                  <div className="absolute left-6 sm:left-8 top-24 bottom-0 w-0.5 bg-gradient-to-b from-teal-500/30 to-transparent translate-y-4" />
                )}

                <div className="p-5 sm:p-6 md:p-8 bg-gradient-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-teal-500/20 rounded-2xl">
                  {/* Phase Header */}
                  <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 sm:gap-4 mb-5 sm:mb-6">
                    <div className="flex items-center gap-3 sm:gap-4">
                      <div className="shrink-0 w-12 h-12 sm:w-14 sm:h-14 bg-gradient-to-br from-teal-500/20 to-primary/20 rounded-xl flex items-center justify-center border border-teal-500/30">
                        <span className="text-base sm:text-lg font-bold text-teal-300">
                          {phase.phase.replace('Phase ', '')}
                        </span>
                      </div>
                      <div>
                        <h2 className="text-lg sm:text-xl md:text-2xl font-bold text-foreground">
                          {phase.title}
                        </h2>
                        <p className="text-xs sm:text-sm text-muted mt-1">
                          {phase.timeline}
                        </p>
                      </div>
                    </div>

                    <div
                      className={`shrink-0 px-3 py-1.5 sm:px-4 sm:py-2 rounded-lg border text-xs sm:text-sm font-semibold ${statusColor}`}
                    >
                      {phase.status}
                    </div>
                  </div>

                  {/* Items Grid */}
                  <div className="grid sm:grid-cols-2 gap-2 sm:gap-3">
                    {phase.items.map((item, itemIndex) => (
                      <div
                        key={itemIndex}
                        className="flex items-start gap-2 sm:gap-3 p-3 sm:p-4 bg-surface-2/50 rounded-lg border border-border"
                      >
                        <div
                          className={`shrink-0 w-5 h-5 sm:w-6 sm:h-6 rounded-full flex items-center justify-center mt-0.5 ${
                            item.done
                              ? 'bg-green-400/20 border-2 border-green-400'
                              : 'bg-surface-2 border-2 border-border'
                          }`}
                        >
                          {item.done && (
                            <svg
                              className="w-3 h-3 sm:w-4 sm:h-4 text-green-400"
                              fill="none"
                              viewBox="0 0 24 24"
                              stroke="currentColor"
                              strokeWidth={3}
                            >
                              <path
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                d="M5 13l4 4L19 7"
                              />
                            </svg>
                          )}
                        </div>
                        <span
                          className={`text-xs sm:text-sm leading-relaxed ${
                            item.done ? 'text-foreground' : 'text-muted'
                          }`}
                        >
                          {item.text}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Footer Note */}
        <div className="mt-10 sm:mt-12 p-5 sm:p-6 bg-gradient-to-br from-teal-500/10 to-primary/10 border border-teal-500/20 rounded-2xl text-center">
          <p className="text-sm sm:text-base text-muted leading-relaxed">
            <span className="text-teal-300 font-semibold">Note:</span> This
            roadmap is subject to change based on community feedback, market
            conditions, and strategic priorities. We&apos;re building in public and
            adapting as we grow.
          </p>
        </div>
      </div>
    </section>
  );
}
