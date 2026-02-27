'use client';

const features = [
  {
    icon: '🤖',
    title: 'Blocnet Edge Engine (BEE)',
    description: 'AI-powered decision engine that analyzes updates and provides intelligent action recommendations with urgency scoring.',
    category: 'AI',
    featured: true,
  },
  {
    icon: '🏠',
    title: 'Smart Home Feed',
    description: 'Personalized feed with AI-ranked updates based on your interests and BEE intelligence.',
    category: 'Core',
  },
  {
    icon: '🔍',
    title: 'Project Discovery',
    description: 'Explore and discover new crypto projects with advanced filtering by priority, tags, and trends.',
    category: 'Core',
  },
  {
    icon: '⛏️',
    title: 'Cycling Mining',
    description: 'Earn BNT tokens through our unique 24-hour cycling mining system. Track hourly earnings and referral boosts.',
    category: 'Earn',
  },
  {
    icon: '👥',
    title: 'Referral Network',
    description: 'Build your downline and earn bonus rewards. View your referral tree and track active referrals in real-time.',
    category: 'Earn',
  },
  {
    icon: '💼',
    title: 'Multi-Asset Wallet',
    description: 'Secure custody wallet supporting BNT, USDT, SOL, and more. View real-time USD values and price charts.',
    category: 'Finance',
  },
  {
    icon: '📊',
    title: 'Transaction History',
    description: 'Complete transparency with detailed transaction, deposit, and withdrawal history for all your assets.',
    category: 'Finance',
  },
  {
    icon: '🎯',
    title: 'Hunter System',
    description: 'Become a verified hunter to contribute updates, submit projects, and earn from quality contributions.',
    category: 'Contribute',
  },
  {
    icon: '📝',
    title: 'Create Updates',
    description: 'Share project updates with priority levels. High/medium/low urgency classification for better engagement.',
    category: 'Contribute',
  },
  {
    icon: '💬',
    title: 'Community Hub',
    description: 'Join discussions, create posts, and connect with other crypto enthusiasts in a vibrant community.',
    category: 'Social',
  },
  {
    icon: '🔔',
    title: 'Smart Notifications',
    description: 'Customizable push notifications for project updates, comments, and important activities you care about.',
    category: 'Social',
  },
  {
    icon: '🏆',
    title: 'Mining Leaderboard',
    description: 'Compete globally with real-time mining leaderboards. Track top earners and their session progress.',
    category: 'Earn',
  },
  {
    icon: '⚡',
    title: 'Real-time Sync',
    description: 'Experience instant updates with real-time synchronization and live comment threads across all devices.',
    category: 'Core',
  },
  {
    icon: '💡',
    title: 'Project Watchlist',
    description: 'Follow projects you care about and receive curated updates with customizable alert preferences.',
    category: 'Core',
  },
  {
    icon: '📈',
    title: 'Analytics Dashboard',
    description: 'Track your mining history, referral performance, and wallet activity with detailed insights.',
    category: 'Earn',
  },
  {
    icon: '🎁',
    title: 'Tip System',
    description: 'Support quality contributors by tipping hunters directly for valuable updates and insights.',
    category: 'Social',
  },
];

export function Features() {
  return (
    <section id="features" className="py-12 sm:py-16 md:py-20 px-4 sm:px-6 lg:px-8 bg-[#09090b] relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#27272a_1px,transparent_1px),linear-gradient(to_bottom,#27272a_1px,transparent_1px)] bg-[size:4rem_4rem] opacity-20" />

      <div className="relative z-10 max-w-7xl mx-auto">
        {/* Section Header */}
        <div className="text-center mb-10 sm:mb-12 md:mb-14">
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-bold text-foreground mb-3 sm:mb-4">
            Powerful Features for <span className="text-teal-400">Everyone</span>
          </h2>
          <p className="text-sm sm:text-base text-muted max-w-2xl mx-auto">
            From casual users to active contributors, Blocnet provides all the
            tools you need to engage with the crypto ecosystem.
          </p>
        </div>

        {/* Features Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 sm:gap-5">
          {features.map((feature) => (
            <div
              key={feature.title}
              className={`p-4 sm:p-5 backdrop-blur-sm border rounded-lg ${
                feature.featured
                  ? 'bg-gradient-to-br from-teal-500/10 to-primary/10 border-teal-500/30 shadow-lg shadow-teal-500/10'
                  : 'bg-surface-2/50 border-border'
              }`}
            >
              {/* Category Badge */}
              <div className="flex items-center justify-between mb-3 sm:mb-4">
                <span className="text-2xl sm:text-3xl">{feature.icon}</span>
                <span className={`text-[10px] sm:text-xs px-2 py-0.5 sm:px-2.5 sm:py-1 rounded-full font-semibold ${
                  feature.category === 'AI'
                    ? 'bg-gradient-to-r from-teal-500/20 to-primary/20 text-teal-300 border border-teal-500/30'
                    : 'bg-teal-500/10 text-teal-400'
                }`}>
                  {feature.category}
                </span>
              </div>

              <h3 className={`text-base sm:text-lg font-semibold mb-2 ${
                feature.featured ? 'text-teal-300' : 'text-foreground'
              }`}>
                {feature.title}
              </h3>
              <p className="text-xs sm:text-sm text-muted leading-relaxed">
                {feature.description}
              </p>

              {feature.featured && (
                <div className="mt-3 pt-3 border-t border-teal-500/20">
                  <span className="text-[10px] text-teal-400 font-semibold">
                    ✨ NEW & EXCLUSIVE
                  </span>
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Call to Action */}
        <div className="mt-10 sm:mt-12 text-center">
          <p className="text-sm sm:text-base text-muted mb-4 sm:mb-5">
            And many more features coming soon...
          </p>
          <a
            href="#"
            className="inline-block px-5 py-2.5 sm:px-6 sm:py-3 bg-teal-500 text-white rounded-lg font-medium text-sm sm:text-base"
          >
            Get Started Now
          </a>
        </div>
      </div>
    </section>
  );
}
