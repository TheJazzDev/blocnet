'use client';

export function RoadmapClean() {
  const phases = [
    {
      phase: 0,
      quarter: 'Q3 2024',
      title: 'Concept & Planning',
      status: 'completed',
      icon: '🎯',
      achievements: [
        'Market research completed',
        'Tokenomics designed',
        'Team assembled',
      ],
    },
    {
      phase: 1,
      quarter: 'Q4 2024',
      title: 'Foundation & Launch',
      status: 'completed',
      icon: '🚀',
      achievements: [
        'Platform launched',
        'Hunter system live',
        'Mobile app released',
      ],
    },
    {
      phase: 2,
      quarter: 'Q1 2026',
      title: 'AI Intelligence & Mining',
      status: 'active',
      icon: '🤖',
      achievements: [
        'BEE AI deployed',
        'Mining mechanism active',
        'Referral network built',
      ],
      progress: 65,
    },
    {
      phase: 3,
      quarter: 'Q2 2026',
      title: 'Wallet & Token Economy',
      status: 'upcoming',
      icon: '💎',
      achievements: [
        'BNT token launch',
        'Multi-asset wallet',
        'Swap functionality',
      ],
    },
    {
      phase: 4,
      quarter: 'Q3 2026',
      title: 'Monetization & Growth',
      status: 'upcoming',
      icon: '📈',
      achievements: [
        'Sponsored listings',
        'Premium features',
        'App store launch',
      ],
    },
    {
      phase: 5,
      quarter: 'Q4 2026',
      title: 'Ecosystem Expansion',
      status: 'upcoming',
      icon: '🌐',
      achievements: [
        'Web3 jobs marketplace',
        'DAO governance',
        'Cross-chain support',
      ],
    },
    {
      phase: 6,
      quarter: '2027',
      title: 'Global Scale',
      status: 'future',
      icon: '🌍',
      achievements: [
        'Multi-language support',
        'Enterprise solutions',
        '100K+ users',
      ],
    },
  ];

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'from-green-500/20 to-green-600/20 border-green-500/40';
      case 'active':
        return 'from-teal-500/20 to-primary/20 border-teal-500/50';
      case 'upcoming':
        return 'from-blue-500/20 to-blue-600/20 border-blue-500/40';
      case 'future':
        return 'from-gray-500/20 to-gray-600/20 border-gray-500/30';
      default:
        return 'from-surface-2/50 to-surface-2/30 border-border';
    }
  };

  const getStatusBadgeColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'bg-green-400/20 border-green-400/40 text-green-400';
      case 'active':
        return 'bg-amber-400/20 border-amber-400/40 text-amber-400';
      case 'upcoming':
        return 'bg-blue-400/20 border-blue-400/40 text-blue-400';
      case 'future':
        return 'bg-gray-400/20 border-gray-400/40 text-gray-400';
      default:
        return 'bg-surface-2 border-border text-muted';
    }
  };

  return (
    <section className="py-16 sm:py-20 md:py-24 px-4 sm:px-6 lg:px-8 bg-[#09090b] relative overflow-hidden">
      {/* Background */}
      <div className="absolute inset-0">
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#27272a_1px,transparent_1px),linear-gradient(to_bottom,#27272a_1px,transparent_1px)] bg-[size:4rem_4rem] opacity-20" />
        <div className="absolute top-1/4 left-1/4 w-[500px] h-[500px] bg-teal-500/10 rounded-full blur-3xl" />
        <div className="absolute bottom-1/4 right-1/4 w-[500px] h-[500px] bg-primary/10 rounded-full blur-3xl" />
      </div>

      <div className="relative z-10 max-w-7xl mx-auto">
        {/* Header */}
        <div className="text-center mb-16">
          <h2 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold text-foreground mb-6">
            Our{' '}
            <span className="text-transparent bg-clip-text bg-linear-to-r from-teal-400 to-primary">
              Journey
            </span>
          </h2>
          <p className="text-base sm:text-lg md:text-xl text-muted max-w-3xl mx-auto">
            From concept to global scale - building the future of crypto intelligence
          </p>
        </div>

        {/* Roadmap Grid */}
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {phases.map((phase) => (
            <div key={phase.phase} className="relative">
              {/* Phase Card */}
              <div
                className={`relative p-8 bg-linear-to-br ${getStatusColor(phase.status)} backdrop-blur-sm border-2 rounded-2xl h-full`}
              >
                {/* Phase Number Badge */}
                <div className="absolute -top-4 -left-4 w-14 h-14 bg-linear-to-br from-teal-500 to-primary rounded-full flex items-center justify-center border-4 border-[#09090b] shadow-lg shadow-teal-500/50">
                  <span className="text-xl font-bold text-white">
                    {phase.phase}
                  </span>
                </div>

                {/* Icon */}
                <div className="flex justify-center mb-5">
                  <div className="w-24 h-24 bg-linear-to-br from-teal-500/20 to-primary/20 rounded-2xl flex items-center justify-center border border-teal-500/30">
                    <span className="text-5xl">{phase.icon}</span>
                  </div>
                </div>

                {/* Header */}
                <div className="text-center mb-5">
                  <div
                    className={`inline-flex items-center gap-2 px-4 py-2 rounded-full text-sm font-semibold border ${getStatusBadgeColor(phase.status)} mb-3`}
                  >
                    {phase.status === 'completed' && '✓'}
                    {phase.status === 'active' && '⚡'}
                    {phase.status === 'upcoming' && '⏳'}
                    {phase.status === 'future' && '🔮'}
                    <span className="capitalize">{phase.status}</span>
                  </div>
                  <p className="text-base text-teal-400 font-semibold mb-2">
                    {phase.quarter}
                  </p>
                  <h3 className="text-xl font-bold text-foreground">
                    {phase.title}
                  </h3>
                </div>

                {/* Progress Bar (for active phase) */}
                {phase.progress !== undefined && (
                  <div className="mb-5">
                    <div className="flex justify-between items-center mb-2">
                      <span className="text-sm text-muted">Progress</span>
                      <span className="text-sm font-semibold text-teal-400">
                        {phase.progress}%
                      </span>
                    </div>
                    <div className="h-3 bg-surface-2 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-linear-to-r from-teal-400 to-primary"
                        style={{ width: `${phase.progress}%` }}
                      />
                    </div>
                  </div>
                )}

                {/* Achievements */}
                <div className="space-y-3">
                  {phase.achievements.map((achievement, i) => (
                    <div
                      key={i}
                      className="flex items-start gap-3 p-3 bg-surface-2/50 rounded-lg border border-border"
                    >
                      <div
                        className={`shrink-0 w-5 h-5 rounded-full mt-0.5 flex items-center justify-center ${
                          phase.status === 'completed'
                            ? 'bg-green-400/20 border-2 border-green-400'
                            : 'bg-surface-2 border-2 border-border'
                        }`}
                      >
                        {phase.status === 'completed' && (
                          <svg
                            className="w-3 h-3 text-green-400"
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
                      <span className="text-sm text-muted leading-relaxed">
                        {achievement}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
