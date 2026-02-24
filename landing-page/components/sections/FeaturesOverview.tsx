'use client';

import Link from 'next/link';

export function FeaturesOverview() {
  const features = [
    {
      icon: '⛏️',
      title: 'Mining & Rewards',
      description: 'Earn BNT tokens through our 24-hour cycling mining system. Build referrals and compete on global leaderboards.',
      link: '/mining',
      linkText: 'Learn About Mining',
      color: 'from-teal-500/20 to-teal-600/20',
      borderColor: 'border-teal-500/30',
    },
    {
      icon: '💼',
      title: 'Multi-Asset Wallet',
      description: 'Secure custody wallet supporting BNT, USDT, SOL and more. View real-time USD values and transaction history.',
      link: '/roadmap',
      linkText: 'View Roadmap',
      color: 'from-primary/20 to-blue-600/20',
      borderColor: 'border-primary/30',
    },
    {
      icon: '🎯',
      title: 'Hunter System',
      description: 'Become a verified hunter to contribute updates, submit projects, and earn from quality contributions.',
      link: '/about',
      linkText: 'Learn More',
      color: 'from-purple-500/20 to-purple-600/20',
      borderColor: 'border-purple-500/30',
    },
    {
      icon: '👥',
      title: 'Community Hub',
      description: 'Join discussions, create posts, and connect with crypto enthusiasts in our vibrant global community.',
      link: '/community',
      linkText: 'Join Community',
      color: 'from-pink-500/20 to-pink-600/20',
      borderColor: 'border-pink-500/30',
    },
  ];

  return (
    <section className="py-12 sm:py-16 md:py-20 px-4 sm:px-6 lg:px-8 bg-[#09090b] relative overflow-hidden">
      {/* Background Effects */}
      <div className="absolute inset-0">
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#27272a_1px,transparent_1px),linear-gradient(to_bottom,#27272a_1px,transparent_1px)] bg-[size:4rem_4rem] opacity-20" />
      </div>

      <div className="relative z-10 max-w-6xl mx-auto">
        {/* Header */}
        <div className="text-center mb-10 sm:mb-12">
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-bold text-foreground mb-3 sm:mb-4">
            Everything You Need in{' '}
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-teal-400 to-primary">
              One Platform
            </span>
          </h2>
          <p className="text-sm sm:text-base text-muted max-w-2xl mx-auto">
            From mining and wallets to community engagement and AI-powered insights,
            Blocnet provides all the tools you need.
          </p>
        </div>

        {/* Features Grid */}
        <div className="grid sm:grid-cols-2 gap-4 sm:gap-6">
          {features.map((feature) => (
            <div
              key={feature.title}
              className={`group p-5 sm:p-6 bg-gradient-to-br ${feature.color} backdrop-blur-sm border ${feature.borderColor} rounded-2xl hover:scale-[1.02] transition-all duration-300`}
            >
              <div className="flex items-start gap-4 mb-4">
                <div className="shrink-0 text-3xl sm:text-4xl">{feature.icon}</div>
                <div className="flex-1">
                  <h3 className="text-lg sm:text-xl font-bold text-foreground mb-2">
                    {feature.title}
                  </h3>
                  <p className="text-xs sm:text-sm text-muted leading-relaxed mb-4">
                    {feature.description}
                  </p>
                  <Link
                    href={feature.link}
                    className="inline-flex items-center gap-2 text-xs sm:text-sm font-semibold text-teal-400 hover:text-teal-300 transition-colors"
                  >
                    {feature.linkText}
                    <svg
                      className="w-4 h-4 group-hover:translate-x-1 transition-transform"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </Link>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Additional Features Pills */}
        <div className="mt-8 sm:mt-10 flex flex-wrap justify-center gap-2 sm:gap-3">
          {[
            'Project Discovery',
            'Smart Notifications',
            'Real-time Updates',
            'Analytics Dashboard',
            'Referral Network',
            'Tip System',
          ].map((pill) => (
            <span
              key={pill}
              className="px-3 py-1.5 sm:px-4 sm:py-2 bg-surface-2/50 border border-border rounded-full text-xs sm:text-sm text-muted"
            >
              {pill}
            </span>
          ))}
        </div>
      </div>
    </section>
  );
}
