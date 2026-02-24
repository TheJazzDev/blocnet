'use client';

export function MiningContent() {
  const features = [
    {
      icon: '⏱️',
      title: '24-Hour Cycles',
      description: 'Each mining session lasts 24 hours with hourly checkpoints. Track your progress and accumulate points throughout the day.',
    },
    {
      icon: '📊',
      title: 'Hourly Checkpoints',
      description: 'Earn points every hour you stay active. Each checkpoint adds to your total rewards for the session.',
    },
    {
      icon: '👥',
      title: 'Referral Boost',
      description: 'Build your downline and earn bonus mining rewards. Active referrals increase your hourly point multiplier.',
    },
    {
      icon: '🏆',
      title: 'Global Leaderboard',
      description: 'Compete with miners worldwide. Top performers get featured and earn additional BNT rewards.',
    },
    {
      icon: '💎',
      title: 'Claim Rewards',
      description: 'After completing a 24-hour cycle, claim your accumulated points. Points convert to BNT during airdrops.',
    },
    {
      icon: '🔄',
      title: 'Continuous Mining',
      description: 'Start a new session immediately after claiming. No cooldowns, mine as much as you want.',
    },
  ];

  const howItWorks = [
    {
      step: '1',
      title: 'Start Mining',
      description: 'Tap the "Start Mining" button in the app to begin your 24-hour session.',
      color: 'from-teal-400 to-teal-600',
    },
    {
      step: '2',
      title: 'Earn Hourly',
      description: 'Every hour you mine, you earn checkpoint points. Stay active for maximum rewards.',
      color: 'from-primary to-blue-600',
    },
    {
      step: '3',
      title: 'Build Referrals',
      description: 'Invite friends with your referral code. Each active referral boosts your mining rate.',
      color: 'from-purple-400 to-purple-600',
    },
    {
      step: '4',
      title: 'Claim & Repeat',
      description: 'After 24 hours, claim your points and start a new session. Points accumulate for future BNT airdrops.',
      color: 'from-green-400 to-green-600',
    },
  ];

  const stats = [
    { value: '1M+', label: 'BNT Mined' },
    { value: '5K+', label: 'Active Miners' },
    { value: '24/7', label: 'Mining Available' },
    { value: '10K+', label: 'Referrals Earned' },
  ];

  const faqs = [
    {
      q: 'What is cycling mining?',
      a: 'Cycling mining is our unique 24-hour mining system where you earn points every hour for staying active. After completing a cycle, you claim your rewards and can immediately start a new session.',
    },
    {
      q: 'How do referrals boost my mining?',
      a: 'Each active referral in your downline increases your hourly mining rate. The more referrals you have actively mining, the higher your point multiplier.',
    },
    {
      q: 'When can I claim my rewards?',
      a: 'You can claim your accumulated points after completing a 24-hour mining session. Once claimed, points are added to your total balance for future BNT airdrops.',
    },
    {
      q: 'What happens to my points?',
      a: 'Mined points accumulate in your account and will be converted to BNT tokens during our scheduled airdrops to early miners. Keep mining to maximize your airdrop allocation.',
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
            Mine BNT with{' '}
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-teal-400 to-primary">
              Cycling Mining
            </span>
          </h1>

          <p className="text-sm sm:text-base md:text-lg text-muted max-w-3xl mx-auto leading-relaxed">
            Earn BNT tokens through our unique 24-hour cycling mining system.
            Start mining, build your referral network, and maximize rewards.
          </p>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 sm:gap-6 mb-12 sm:mb-16">
          {stats.map((stat) => (
            <div
              key={stat.label}
              className="p-4 sm:p-6 bg-gradient-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-teal-500/20 rounded-2xl text-center"
            >
              <div className="text-2xl sm:text-3xl md:text-4xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-teal-300 to-primary mb-2">
                {stat.value}
              </div>
              <div className="text-xs sm:text-sm text-muted">{stat.label}</div>
            </div>
          ))}
        </div>

        {/* How It Works */}
        <div className="mb-12 sm:mb-16">
          <h2 className="text-xl sm:text-2xl md:text-3xl font-bold text-center mb-8 sm:mb-10">
            How It Works
          </h2>
          <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
            {howItWorks.map((item) => (
              <div
                key={item.step}
                className="relative p-5 sm:p-6 bg-gradient-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-border rounded-2xl"
              >
                <div className={`absolute -top-3 -left-3 w-10 h-10 sm:w-12 sm:h-12 flex items-center justify-center bg-gradient-to-br ${item.color} rounded-xl font-bold text-base sm:text-lg text-white shadow-lg`}>
                  {item.step}
                </div>
                <h3 className="text-base sm:text-lg font-bold text-foreground mb-2 mt-2">
                  {item.title}
                </h3>
                <p className="text-xs sm:text-sm text-muted leading-relaxed">
                  {item.description}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* Features */}
        <div className="mb-12 sm:mb-16">
          <h2 className="text-xl sm:text-2xl md:text-3xl font-bold text-center mb-8 sm:mb-10">
            Mining Features
          </h2>
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
            {features.map((feature) => (
              <div
                key={feature.title}
                className="p-5 sm:p-6 bg-gradient-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-border rounded-2xl"
              >
                <div className="text-3xl sm:text-4xl mb-3 sm:mb-4">
                  {feature.icon}
                </div>
                <h3 className="text-base sm:text-lg font-bold text-foreground mb-2">
                  {feature.title}
                </h3>
                <p className="text-xs sm:text-sm text-muted leading-relaxed">
                  {feature.description}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* FAQs */}
        <div className="mb-12 sm:mb-16">
          <h2 className="text-xl sm:text-2xl md:text-3xl font-bold text-center mb-8 sm:mb-10">
            Frequently Asked Questions
          </h2>
          <div className="space-y-4 sm:space-y-6">
            {faqs.map((faq, index) => (
              <div
                key={index}
                className="p-5 sm:p-6 bg-gradient-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-border rounded-2xl"
              >
                <h3 className="text-base sm:text-lg font-bold text-foreground mb-2 sm:mb-3">
                  {faq.q}
                </h3>
                <p className="text-xs sm:text-sm text-muted leading-relaxed">
                  {faq.a}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* CTA */}
        <div className="p-6 sm:p-8 md:p-10 bg-gradient-to-br from-teal-500/10 to-primary/10 border border-teal-500/20 rounded-2xl text-center">
          <h2 className="text-xl sm:text-2xl md:text-3xl font-bold text-foreground mb-3 sm:mb-4">
            Start Mining Today
          </h2>
          <p className="text-sm sm:text-base text-muted mb-6 sm:mb-8 max-w-2xl mx-auto">
            Download Blocnet and start your first mining session. Early miners get
            the biggest BNT airdrops when tokens launch.
          </p>
          <a
            href="/#download"
            className="inline-block px-6 py-3 sm:px-8 sm:py-4 bg-gradient-to-r from-teal-500 to-primary text-white rounded-xl font-semibold text-sm sm:text-base shadow-lg shadow-teal-500/25 hover:shadow-teal-500/40 transition-all duration-300 hover:scale-105"
          >
            Download & Start Mining
          </a>
        </div>
      </div>
    </section>
  );
}
