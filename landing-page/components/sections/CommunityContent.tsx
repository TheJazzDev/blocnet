'use client';

export function CommunityContent() {
  const socialPlatforms = [
    {
      icon: '𝕏',
      name: 'X (Twitter)',
      handle: '@blocnet_app',
      link: 'https://x.com/blocnet_app',
      description: 'Follow for real-time updates, announcements, and crypto alpha',
      color: 'from-gray-400 to-gray-600',
    },
    {
      icon: '📱',
      name: 'Telegram',
      handle: '@blocnet_app',
      link: 'https://t.me/blocnet_app',
      description: 'Join our main chat for support, discussions, and community events',
      color: 'from-blue-400 to-blue-600',
    },
    {
      icon: '📸',
      name: 'Instagram',
      handle: '@blocnet_app',
      link: 'https://instagram.com/blocnet_app',
      description: 'Visual updates, behind-the-scenes, and community highlights',
      color: 'from-pink-400 to-purple-600',
    },
    {
      icon: '🎵',
      name: 'TikTok',
      handle: '@blocnet_app',
      link: 'https://tiktok.com/@blocnet_app',
      description: 'Short-form crypto content, tips, and platform tutorials',
      color: 'from-black to-gray-800',
    },
  ];

  const communityStats = [
    { value: '10K+', label: 'Active Members' },
    { value: '500+', label: 'Verified Hunters' },
    { value: '50K+', label: 'Monthly Updates' },
    { value: '24/7', label: 'Community Support' },
  ];

  const benefits = [
    {
      icon: '🎯',
      title: 'Early Access',
      description: 'Get first access to new features, airdrops, and exclusive opportunities',
    },
    {
      icon: '💬',
      title: 'Direct Support',
      description: 'Connect with our team and experienced community members for help',
    },
    {
      icon: '🏆',
      title: 'Competitions & Rewards',
      description: 'Participate in mining competitions, contests, and earn BNT rewards',
    },
    {
      icon: '🤝',
      title: 'Networking',
      description: 'Build connections with crypto enthusiasts, hunters, and projects',
    },
    {
      icon: '📚',
      title: 'Learn & Grow',
      description: 'Access educational content, AMAs, and insights from top hunters',
    },
    {
      icon: '🎤',
      title: 'Voice & Influence',
      description: 'Shape the platform through feedback, suggestions, and DAO governance',
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
            Connect with{' '}
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-teal-400 to-primary">
              Crypto Enthusiasts
            </span>
          </h1>

          <p className="text-sm sm:text-base md:text-lg text-muted max-w-3xl mx-auto leading-relaxed">
            Join thousands of hunters, traders, and crypto enthusiasts in the Blocnet
            community. Share insights, discover alpha, and grow together.
          </p>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 sm:gap-6 mb-12 sm:mb-16">
          {communityStats.map((stat) => (
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

        {/* Social Platforms */}
        <div className="mb-12 sm:mb-16">
          <h2 className="text-xl sm:text-2xl md:text-3xl font-bold text-center mb-8 sm:mb-10">
            Follow Us Everywhere
          </h2>
          <div className="grid sm:grid-cols-2 gap-4 sm:gap-6">
            {socialPlatforms.map((platform) => (
              <a
                key={platform.name}
                href={platform.link}
                target="_blank"
                rel="noopener noreferrer"
                className="group p-5 sm:p-6 bg-gradient-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-border rounded-2xl "
              >
                <div className="flex items-start gap-4">
                  <div className={`shrink-0 w-12 h-12 sm:w-14 sm:h-14 flex items-center justify-center bg-gradient-to-br ${platform.color} rounded-xl text-xl sm:text-2xl`}>
                    {platform.icon}
                  </div>
                  <div className="flex-1">
                    <h3 className="text-base sm:text-lg font-bold text-foreground mb-1">
                      {platform.name}
                    </h3>
                    <p className="text-xs sm:text-sm text-teal-400 mb-2">
                      {platform.handle}
                    </p>
                    <p className="text-xs sm:text-sm text-muted leading-relaxed">
                      {platform.description}
                    </p>
                  </div>
                  <svg
                    className="shrink-0 w-5 h-5 text-muted "
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
                    />
                  </svg>
                </div>
              </a>
            ))}
          </div>
        </div>

        {/* Community Benefits */}
        <div className="mb-12 sm:mb-16">
          <h2 className="text-xl sm:text-2xl md:text-3xl font-bold text-center mb-8 sm:mb-10">
            Why Join Our Community?
          </h2>
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
            {benefits.map((benefit) => (
              <div
                key={benefit.title}
                className="p-5 sm:p-6 bg-gradient-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-border rounded-2xl"
              >
                <div className="text-3xl sm:text-4xl mb-3 sm:mb-4">
                  {benefit.icon}
                </div>
                <h3 className="text-base sm:text-lg font-bold text-foreground mb-2">
                  {benefit.title}
                </h3>
                <p className="text-xs sm:text-sm text-muted leading-relaxed">
                  {benefit.description}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* CTA */}
        <div className="p-6 sm:p-8 md:p-10 bg-gradient-to-br from-teal-500/10 to-primary/10 border border-teal-500/20 rounded-2xl text-center">
          <h2 className="text-xl sm:text-2xl md:text-3xl font-bold text-foreground mb-3 sm:mb-4">
            Ready to Join?
          </h2>
          <p className="text-sm sm:text-base text-muted mb-6 sm:mb-8 max-w-2xl mx-auto">
            Download the app and become part of the fastest-growing crypto intelligence
            community. Start earning, learning, and connecting today.
          </p>
          <a
            href="/#download"
            className="inline-block px-6 py-3 sm:px-8 sm:py-4 bg-gradient-to-r from-teal-500 to-primary text-white rounded-xl font-semibold text-sm sm:text-base shadow-lg shadow-teal-500/25 "
          >
            Download Blocnet
          </a>
        </div>
      </div>
    </section>
  );
}
