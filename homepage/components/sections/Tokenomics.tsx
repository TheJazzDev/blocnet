'use client';

export function Tokenomics() {
  const tokenAllocation = [
    { label: 'Mining Rewards', percentage: 40, color: '#2dd4bf' },
    { label: 'Ecosystem Growth', percentage: 25, color: '#8b5cf6' },
    { label: 'Team & Advisors', percentage: 15, color: '#06b6d4' },
    { label: 'Liquidity Pool', percentage: 10, color: '#3b82f6' },
    { label: 'Community Airdrops', percentage: 10, color: '#10b981' },
  ];

  const tokenStats = [
    { label: 'Total Supply', value: '1,000,000,000', suffix: 'BNT' },
    { label: 'Initial Circulation', value: '100,000,000', suffix: 'BNT' },
    { label: 'Token Type', value: 'Utility', suffix: '' },
    { label: 'Blockchain', value: 'BNB Smart Chain', suffix: '' },
  ];

  const utilities = [
    {
      icon: '⛏️',
      title: 'Mining Rewards',
      description: 'Earn BNT through 24-hour cycling mining. Complete cycles and build referral networks for higher rewards.',
    },
    {
      icon: '💰',
      title: 'Hunter Tipping',
      description: 'Reward quality content creators and hunters with BNT tips. Support contributors who provide valuable updates.',
    },
    {
      icon: '🔄',
      title: 'Swap & Exchange',
      description: 'Built-in swap functionality for BNT, USDT, SOL, and more. Trade directly within the platform.',
    },
    {
      icon: '✨',
      title: 'Premium Access',
      description: 'Unlock exclusive features: advanced analytics, priority support, and early access to new tools.',
    },
    {
      icon: '🗳️',
      title: 'DAO Governance',
      description: 'Vote on platform decisions, feature proposals, and community initiatives. Shape the future of Blocnet.',
    },
    {
      icon: '🎁',
      title: 'Exclusive Benefits',
      description: 'Access sponsored project listings, premium subscriptions, and special community events.',
    },
  ];

  return (
    <section className="py-16 sm:py-20 md:py-24 px-4 sm:px-6 lg:px-8 bg-[#09090b] relative overflow-hidden">
      {/* Background */}
      <div className="absolute inset-0">
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#27272a_1px,transparent_1px),linear-gradient(to_bottom,#27272a_1px,transparent_1px)] bg-[size:4rem_4rem] opacity-20" />
        <div className="absolute top-1/4 right-1/4 w-96 h-96 bg-teal-500/10 rounded-full blur-3xl" />
      </div>

      <div className="relative z-10 max-w-6xl mx-auto">
        {/* Header */}
        <div className="text-center mb-14">
          <h2 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold text-foreground mb-6">
            <span className="text-transparent bg-clip-text bg-linear-to-r from-teal-400 to-primary">
              BNT Token
            </span>{' '}
            Economics
          </h2>
          <p className="text-base sm:text-lg md:text-xl text-muted max-w-2xl mx-auto">
            Fair distribution model designed to reward community participation
            and long-term platform growth
          </p>
        </div>

        {/* Token Stats */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-14">
          {tokenStats.map((stat) => (
            <div
              key={stat.label}
              className="p-6 bg-linear-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-teal-500/20 rounded-xl text-center transition-colors hover:border-teal-500/40"
            >
              <p className="text-sm text-muted mb-2">
                {stat.label}
              </p>
              <p className="text-xl font-bold text-transparent bg-clip-text bg-linear-to-r from-teal-400 to-primary">
                {stat.value}
              </p>
              {stat.suffix && (
                <p className="text-sm text-teal-400 mt-1">{stat.suffix}</p>
              )}
            </div>
          ))}
        </div>

        {/* Allocation */}
        <div className="mb-14">
          <h3 className="text-2xl sm:text-3xl font-bold text-center text-foreground mb-8">
            Token <span className="text-teal-400">Distribution</span>
          </h3>

          <div className="grid sm:grid-cols-2 lg:grid-cols-5 gap-4">
            {tokenAllocation.map((item, index) => (
              <div
                key={index}
                className="p-6 bg-linear-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-border rounded-xl text-center transition-colors hover:border-teal-500/30"
              >
                <div
                  className="w-16 h-16 rounded-full mx-auto mb-4"
                  style={{ backgroundColor: item.color }}
                />
                <div className="text-3xl font-bold text-transparent bg-clip-text bg-linear-to-r from-teal-400 to-primary mb-2">
                  {item.percentage}%
                </div>
                <div className="text-sm font-medium text-foreground">
                  {item.label}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Token Utilities */}
        <div>
          <h3 className="text-2xl sm:text-3xl font-bold text-center text-foreground mb-8">
            Token <span className="text-teal-400">Utility</span>
          </h3>
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-5">
            {utilities.map((utility, index) => (
              <div
                key={index}
                className="p-6 bg-linear-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-border rounded-xl transition-colors hover:border-teal-500/30"
              >
                <div className="flex items-start gap-4">
                  <div className="shrink-0 w-12 h-12 bg-linear-to-br from-teal-500/20 to-primary/20 rounded-xl flex items-center justify-center border border-teal-500/30">
                    <span className="text-2xl">{utility.icon}</span>
                  </div>
                  <div>
                    <h4 className="text-base font-semibold text-foreground mb-2">
                      {utility.title}
                    </h4>
                    <p className="text-sm text-muted leading-relaxed">
                      {utility.description}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
