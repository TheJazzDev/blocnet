'use client';

const features = [
  {
    icon: '🏠',
    title: 'Home Feed',
    description: 'Stay updated with personalized project updates and trending content from your followed projects.',
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
    description: 'Earn BNT tokens through our unique cycling mining system. Start, track, and claim your rewards.',
    category: 'Earn',
  },
  {
    icon: '👥',
    title: 'Referral System',
    description: 'Grow your network and earn bonus rewards. Track your downline and get referral boosts.',
    category: 'Earn',
  },
  {
    icon: '💼',
    title: 'Multi-Asset Wallet',
    description: 'Manage BNT and other crypto assets. View balances, track USD value, and make transfers.',
    category: 'Finance',
  },
  {
    icon: '📊',
    title: 'Transaction History',
    description: 'Complete transparency with detailed transaction and withdrawal history for all your assets.',
    category: 'Finance',
  },
  {
    icon: '🎯',
    title: 'Hunter System',
    description: 'Become a hunter to contribute updates, submit projects, and earn from quality contributions.',
    category: 'Contribute',
  },
  {
    icon: '📝',
    title: 'Create Updates',
    description: 'Share project updates with the community. Set priority levels and engage with followers.',
    category: 'Contribute',
  },
  {
    icon: '💬',
    title: 'Community Discussions',
    description: 'Join conversations, share insights, and connect with other crypto enthusiasts.',
    category: 'Social',
  },
  {
    icon: '🔔',
    title: 'Smart Notifications',
    description: 'Get notified about important updates, comments, and activities with customizable preferences.',
    category: 'Social',
  },
  {
    icon: '🏆',
    title: 'Leaderboards',
    description: 'Compete with other hunters and track your ranking based on quality contributions.',
    category: 'Contribute',
  },
  {
    icon: '⚡',
    title: 'Real-time Updates',
    description: 'Experience instant updates with real-time synchronization across all your devices.',
    category: 'Core',
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
              className="p-4 sm:p-5 bg-surface-2/50 backdrop-blur-sm border border-border rounded-lg"
            >
              {/* Category Badge */}
              <div className="flex items-center justify-between mb-3 sm:mb-4">
                <span className="text-2xl sm:text-3xl">{feature.icon}</span>
                <span className="text-[10px] sm:text-xs px-2 py-0.5 sm:px-2.5 sm:py-1 bg-teal-500/10 text-teal-400 rounded-full">
                  {feature.category}
                </span>
              </div>

              <h3 className="text-base sm:text-lg font-semibold text-foreground mb-2">
                {feature.title}
              </h3>
              <p className="text-xs sm:text-sm text-muted leading-relaxed">
                {feature.description}
              </p>
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
