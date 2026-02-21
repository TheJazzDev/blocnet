'use client';

export function Hunter() {
  return (
    <section className="py-12 sm:py-16 md:py-20 px-4 sm:px-6 lg:px-8 bg-surface relative overflow-hidden">
      {/* Background Pattern */}
      <div className="absolute inset-0 opacity-5">
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#6366f1_1px,transparent_1px),linear-gradient(to_bottom,#6366f1_1px,transparent_1px)] bg-[size:6rem_6rem]" />
      </div>

      <div className="relative z-10 max-w-7xl mx-auto">
        <div className="text-center mb-10 sm:mb-12">
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-bold text-foreground mb-3 sm:mb-4">
            The <span className="text-indigo-400">Hunter System</span>
          </h2>
          <p className="text-sm sm:text-base text-muted max-w-2xl mx-auto">
            Level up from user to hunter. Contribute quality updates, manage
            projects, and earn rewards for your expertise.
          </p>
        </div>

        {/* Info Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 sm:gap-5 mb-8 sm:mb-10">
          {[
            {
              icon: '📝',
              title: 'Create Updates',
              description:
                'Share project updates with the community. Set priority levels and engage with followers.',
            },
            {
              icon: '🚀',
              title: 'Submit Projects',
              description:
                'Add new crypto projects to the platform and help the community discover opportunities.',
            },
            {
              icon: '🎯',
              title: 'Quality Signals',
              description:
                'Earn points for high-priority updates and maintain a strong success rate.',
            },
          ].map((card) => (
            <div
              key={card.title}
              className="p-5 sm:p-6 bg-surface-2 border border-border rounded-xl"
            >
              <span className="text-3xl sm:text-4xl block mb-3 sm:mb-4">
                {card.icon}
              </span>
              <h3 className="text-base sm:text-lg font-bold text-foreground mb-2">
                {card.title}
              </h3>
              <p className="text-xs sm:text-sm text-muted">
                {card.description}
              </p>
            </div>
          ))}
        </div>

        {/* Hunter Dashboard Preview */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 sm:gap-8">
          {/* Stats Grid */}
          <div>
            <h3 className="text-lg sm:text-xl font-bold text-foreground mb-4 sm:mb-5">
              Hunter Dashboard
            </h3>
            <div className="grid grid-cols-2 gap-3 sm:gap-4 mb-4 sm:mb-5">
              {[
                { label: 'Updates', value: '127', icon: '📄' },
                { label: 'High Priority', value: '45', icon: '⚡' },
                { label: 'Success Rate', value: '94%', icon: '✓' },
                { label: 'Projects Managed', value: '12', icon: '🗂️' },
              ].map((stat) => (
                <div
                  key={stat.label}
                  className="p-4 sm:p-5 bg-surface-2 border border-border rounded-lg"
                >
                  <div className="text-xl sm:text-2xl mb-2">
                    {stat.icon}
                  </div>
                  <div className="text-xl sm:text-2xl font-bold text-indigo-400 mb-1">
                    {stat.value}
                  </div>
                  <div className="text-xs sm:text-sm text-muted">
                    {stat.label}
                  </div>
                </div>
              ))}
            </div>

            {/* Elite Badge */}
            <div className="p-4 sm:p-5 bg-indigo-500/10 border border-indigo-500/20 rounded-xl">
              <div className="flex items-center gap-3 sm:gap-4">
                <div className="w-12 h-12 sm:w-14 sm:h-14 bg-indigo-500/20 rounded-full flex items-center justify-center text-xl sm:text-2xl">
                  👑
                </div>
                <div>
                  <div className="text-sm sm:text-base font-bold text-indigo-400">
                    Elite Hunter
                  </div>
                  <div className="text-xs sm:text-sm text-muted">
                    Top 10% contributor this season
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Leaderboard */}
          <div>
            <div className="flex items-center justify-between mb-4 sm:mb-5">
              <h3 className="text-lg sm:text-xl font-bold text-foreground">
                Season Leaderboard
              </h3>
              <span className="text-xs sm:text-sm px-2.5 py-1 sm:px-3 sm:py-1.5 bg-indigo-500/10 text-indigo-400 rounded-full">
                Season 1
              </span>
            </div>

            <div className="space-y-2 sm:space-y-3 mb-4 sm:mb-5">
              {[
                { rank: 1, name: 'CryptoMaster', points: '2,450', badge: '🥇' },
                { rank: 2, name: 'BlockchainPro', points: '2,120', badge: '🥈' },
                { rank: 3, name: 'TokenHunter', points: '1,890', badge: '🥉' },
                { rank: 4, name: 'You', points: '1,650', badge: '👤', highlight: true },
                { rank: 5, name: 'WebGuru', points: '1,430', badge: '⭐' },
              ].map((user) => (
                <div
                  key={user.rank}
                  className={`flex items-center justify-between p-3 sm:p-4 ${
                    user.highlight
                      ? 'bg-indigo-500/10 border-2 border-indigo-500/50'
                      : 'bg-surface-2 border border-border'
                  } rounded-lg`}
                >
                  <div className="flex items-center gap-2 sm:gap-3">
                    <div className="w-8 h-8 sm:w-10 sm:h-10 shrink-0 bg-surface border border-border rounded-full flex items-center justify-center font-bold text-xs sm:text-sm text-muted">
                      #{user.rank}
                    </div>
                    <span className="text-base sm:text-lg">
                      {user.badge}
                    </span>
                    <div className="text-sm sm:text-base font-semibold text-foreground">
                      {user.name}
                    </div>
                  </div>
                  <div className="text-sm sm:text-base font-bold text-indigo-400">
                    {user.points}
                  </div>
                </div>
              ))}
            </div>

            <a
              href="#"
              className="block text-center px-4 py-2.5 sm:px-5 sm:py-3 bg-indigo-500 text-white rounded-lg font-medium text-sm sm:text-base"
            >
              Become a Hunter
            </a>
          </div>
        </div>

        {/* Benefits */}
        <div className="mt-10 sm:mt-12">
          <h3 className="text-lg sm:text-xl font-bold text-foreground mb-4 sm:mb-5 text-center">
            Hunter Benefits
          </h3>
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-5">
            {[
              { icon: '💰', label: 'Earn More', desc: 'Bonus rewards' },
              { icon: '🎖️', label: 'Recognition', desc: 'Elite status' },
              { icon: '🔓', label: 'Early Access', desc: 'New features' },
              { icon: '📊', label: 'Analytics', desc: 'Detailed insights' },
            ].map((benefit) => (
              <div
                key={benefit.label}
                className="text-center p-4 sm:p-5 bg-surface-2/50 border border-border rounded-lg"
              >
                <div className="text-2xl sm:text-3xl mb-2">
                  {benefit.icon}
                </div>
                <div className="text-sm sm:text-base font-semibold text-foreground mb-0.5 sm:mb-1">
                  {benefit.label}
                </div>
                <div className="text-xs sm:text-sm text-muted">
                  {benefit.desc}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
