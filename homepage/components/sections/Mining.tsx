'use client';

export function Mining() {
  return (
    <section className="py-12 sm:py-16 md:py-20 px-4 sm:px-6 lg:px-8 bg-surface relative overflow-hidden">
      {/* Background Pattern */}
      <div className="absolute inset-0 opacity-5">
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#2dd4bf_1px,transparent_1px),linear-gradient(to_bottom,#2dd4bf_1px,transparent_1px)] bg-[size:6rem_6rem]" />
      </div>

      <div className="relative z-10 max-w-7xl mx-auto">
        <div className="text-center mb-10 sm:mb-12">
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-bold text-foreground mb-3 sm:mb-4">
            Mining & <span className="text-teal-400">Referrals</span>
          </h2>
          <p className="text-sm sm:text-base text-muted max-w-2xl mx-auto">
            Earn BNT tokens through our unique cycling mining system and grow
            your network with our powerful referral program.
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 sm:gap-8 items-center">
          {/* Mining Card */}
          <div>
            <div className="p-5 sm:p-6 md:p-7 bg-surface-2 border border-border rounded-xl">
              <div className="flex items-center justify-between mb-4 sm:mb-5">
                <h3 className="text-lg sm:text-xl font-bold text-foreground">
                  Mining Session
                </h3>
                <span className="text-xs sm:text-sm px-2.5 py-1 sm:px-3 sm:py-1.5 bg-teal-500/10 text-teal-400 rounded-full">
                  Active
                </span>
              </div>

              {/* Progress Circle */}
              <div className="relative w-32 h-32 sm:w-36 sm:h-36 md:w-40 md:h-40 mx-auto mb-4 sm:mb-5">
                <svg className="w-full h-full -rotate-90">
                  <circle
                    cx="50%"
                    cy="50%"
                    r="45%"
                    stroke="#27272a"
                    strokeWidth="8"
                    fill="none"
                  />
                  <circle
                    cx="50%"
                    cy="50%"
                    r="45%"
                    stroke="#2dd4bf"
                    strokeWidth="8"
                    fill="none"
                    strokeLinecap="round"
                    strokeDasharray="450 1000"
                  />
                </svg>
                <div className="absolute inset-0 flex flex-col items-center justify-center">
                  <span className="text-2xl sm:text-3xl font-bold text-teal-400">
                    65%
                  </span>
                  <span className="text-xs sm:text-sm text-muted">
                    Complete
                  </span>
                </div>
              </div>

              {/* Mining Stats */}
              <div className="grid grid-cols-2 gap-3 sm:gap-4">
                <div className="p-3 sm:p-4 bg-surface border border-border rounded-lg">
                  <div className="text-xs sm:text-sm text-muted mb-1">
                    Points/Cycle
                  </div>
                  <div className="text-lg sm:text-xl font-bold text-foreground">
                    125
                  </div>
                </div>
                <div className="p-3 sm:p-4 bg-surface border border-border rounded-lg">
                  <div className="text-xs sm:text-sm text-muted mb-1">
                    Boost Active
                  </div>
                  <div className="text-lg sm:text-xl font-bold text-teal-400">
                    +25%
                  </div>
                </div>
                <div className="p-3 sm:p-4 bg-surface border border-border rounded-lg">
                  <div className="text-xs sm:text-sm text-muted mb-1">
                    Claimed
                  </div>
                  <div className="text-lg sm:text-xl font-bold text-foreground">
                    2,450
                  </div>
                </div>
                <div className="p-3 sm:p-4 bg-surface border border-border rounded-lg">
                  <div className="text-xs sm:text-sm text-muted mb-1">
                    Lifetime
                  </div>
                  <div className="text-lg sm:text-xl font-bold text-foreground">
                    8,900
                  </div>
                </div>
              </div>

              <button className="w-full mt-4 sm:mt-5 px-4 py-2.5 sm:px-5 sm:py-3 bg-teal-500 text-white rounded-lg font-medium text-sm sm:text-base">
                Claim Rewards
              </button>
            </div>
          </div>

          {/* Features List */}
          <div className="space-y-4 sm:space-y-5">
            {[
              {
                icon: '⛏️',
                title: 'Cycling Mining',
                description:
                  'Start mining sessions and earn points in cycles. No complex hardware needed.',
              },
              {
                icon: '🔗',
                title: 'Referral Codes',
                description:
                  'Generate your unique code and invite others to join your network.',
              },
              {
                icon: '📈',
                title: 'Downline Tracking',
                description:
                  'View your network growth and track earnings from your referrals.',
              },
              {
                icon: '⚡',
                title: 'Bonus Rewards',
                description:
                  'Get up to 25% boost on mining rewards based on your active referrals.',
              },
            ].map((item) => (
              <div
                key={item.title}
                className="flex gap-3 sm:gap-4 p-4 sm:p-5 bg-surface-2/50 border border-border rounded-lg"
              >
                <div className="shrink-0 w-10 h-10 sm:w-12 sm:h-12 flex items-center justify-center bg-teal-500/10 rounded-lg text-xl sm:text-2xl">
                  {item.icon}
                </div>
                <div>
                  <h4 className="text-base sm:text-lg font-semibold text-foreground mb-1">
                    {item.title}
                  </h4>
                  <p className="text-xs sm:text-sm text-muted">
                    {item.description}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Stats Bar */}
        <div className="mt-10 sm:mt-12 grid grid-cols-2 md:grid-cols-4 gap-4 sm:gap-5 p-5 sm:p-6 bg-surface-2/50 border border-border rounded-xl">
          {[
            { label: 'Active Miners', value: '5K+', icon: '👥' },
            { label: 'Total Claimed', value: '$250K', icon: '💰' },
            { label: 'Referrals Made', value: '12K+', icon: '🔗' },
            { label: 'Avg. Daily Earnings', value: '150 BNT', icon: '📊' },
          ].map((stat) => (
            <div key={stat.label} className="text-center">
              <div className="text-xl sm:text-2xl mb-1 sm:mb-2">
                {stat.icon}
              </div>
              <div className="text-xl sm:text-2xl font-bold text-teal-400 mb-0.5 sm:mb-1">
                {stat.value}
              </div>
              <div className="text-xs sm:text-sm text-muted">
                {stat.label}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
