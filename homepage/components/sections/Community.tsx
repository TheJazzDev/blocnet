'use client';

export function Community() {
  return (
    <section className="py-12 sm:py-16 md:py-20 px-4 sm:px-6 lg:px-8 bg-[#09090b] relative overflow-hidden">
      {/* Background Grid */}
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#27272a_1px,transparent_1px),linear-gradient(to_bottom,#27272a_1px,transparent_1px)] bg-[size:4rem_4rem] opacity-20" />

      <div className="relative z-10 max-w-7xl mx-auto">
        <div className="text-center mb-10 sm:mb-12">
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-bold text-foreground mb-3 sm:mb-4">
            Thriving <span className="text-teal-400">Community</span>
          </h2>
          <p className="text-sm sm:text-base text-muted max-w-2xl mx-auto">
            Connect with crypto enthusiasts, share insights, and stay updated
            with real-time discussions.
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 sm:gap-8">
          {/* Community Features */}
          <div className="space-y-4 sm:space-y-5">
            {[
              {
                icon: '💬',
                title: 'Discussions',
                description:
                  'Create posts, share opinions, and engage in meaningful conversations about crypto projects.',
              },
              {
                icon: '📢',
                title: 'Announcements',
                description:
                  'Stay informed with official announcements and important updates from projects.',
              },
              {
                icon: '💡',
                title: 'Feedback',
                description:
                  'Share your thoughts and help shape the future of projects you follow.',
              },
              {
                icon: '🔔',
                title: 'Real-time Sync',
                description:
                  'Experience instant updates with Supabase real-time synchronization.',
              },
            ].map((feature) => (
              <div
                key={feature.title}
                className="flex gap-3 sm:gap-4 p-4 sm:p-5 bg-surface-2 border border-border rounded-lg"
              >
                <div className="shrink-0 w-10 h-10 sm:w-12 sm:h-12 flex items-center justify-center bg-teal-500/10 rounded-lg text-xl sm:text-2xl">
                  {feature.icon}
                </div>
                <div>
                  <h4 className="text-base sm:text-lg font-semibold text-foreground mb-1">
                    {feature.title}
                  </h4>
                  <p className="text-xs sm:text-sm text-muted">
                    {feature.description}
                  </p>
                </div>
              </div>
            ))}
          </div>

          {/* Community Feed Preview */}
          <div>
            <div className="p-5 sm:p-6 bg-surface-2 border border-border rounded-xl">
              <div className="flex items-center justify-between mb-4 sm:mb-5">
                <h3 className="text-lg sm:text-xl font-bold text-foreground">
                  Community Feed
                </h3>
                <span className="w-2 h-2 bg-teal-400 rounded-full"></span>
              </div>

              {/* Sample Posts */}
              <div className="space-y-3 sm:space-y-4">
                {[
                  {
                    author: 'CryptoEnthusiast',
                    time: '5 min ago',
                    content:
                      'Just claimed my mining rewards! The cycling system is amazing. 🎉',
                    likes: 24,
                    comments: 8,
                  },
                  {
                    author: 'BlockchainDev',
                    time: '2 hours ago',
                    content:
                      'New project update just dropped. High priority! Check it out.',
                    likes: 56,
                    comments: 15,
                  },
                  {
                    author: 'TokenTracker',
                    time: '1 day ago',
                    content:
                      'Anyone else seeing the BNT price surge? My wallet is looking good! 📈',
                    likes: 89,
                    comments: 32,
                  },
                ].map((post, index) => (
                  <div
                    key={index}
                    className="p-3 sm:p-4 bg-surface border border-border rounded-lg"
                  >
                    {/* Post Header */}
                    <div className="flex items-center gap-2 sm:gap-3 mb-2 sm:mb-3">
                      <div className="w-8 h-8 sm:w-10 sm:h-10 bg-teal-500/10 rounded-full flex items-center justify-center text-teal-400 font-bold text-xs sm:text-sm">
                        {post.author.charAt(0)}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="text-xs sm:text-sm font-semibold text-foreground truncate">
                          {post.author}
                        </div>
                        <div className="text-[10px] sm:text-xs text-muted">
                          {post.time}
                        </div>
                      </div>
                    </div>

                    {/* Post Content */}
                    <p className="text-xs sm:text-sm text-foreground mb-2 sm:mb-3">
                      {post.content}
                    </p>

                    {/* Post Actions */}
                    <div className="flex items-center gap-3 sm:gap-4 text-xs sm:text-sm text-muted">
                      <button className="flex items-center gap-1 sm:gap-1.5">
                        <span>❤️</span>
                        <span>{post.likes}</span>
                      </button>
                      <button className="flex items-center gap-1 sm:gap-1.5">
                        <span>💬</span>
                        <span>{post.comments}</span>
                      </button>
                      <button className="flex items-center gap-1 sm:gap-1.5">
                        <span>🔖</span>
                      </button>
                    </div>
                  </div>
                ))}
              </div>

              {/* Create Post Button */}
              <button className="w-full mt-4 sm:mt-5 px-4 py-2.5 sm:px-5 sm:py-3 bg-teal-500 text-white rounded-lg font-medium text-sm sm:text-base">
                Create Post
              </button>
            </div>
          </div>
        </div>

        {/* Community Stats */}
        <div className="mt-10 sm:mt-12 grid grid-cols-2 md:grid-cols-4 gap-4 sm:gap-5">
          {[
            { icon: '👥', label: 'Active Members', value: '10K+' },
            { icon: '💬', label: 'Posts Created', value: '5K+' },
            { icon: '❤️', label: 'Interactions', value: '50K+' },
            { icon: '🌍', label: 'Countries', value: '120+' },
          ].map((stat) => (
            <div
              key={stat.label}
              className="p-4 sm:p-5 bg-surface-2/50 border border-border rounded-lg text-center"
            >
              <div className="text-2xl sm:text-3xl mb-2">
                {stat.icon}
              </div>
              <div className="text-xl sm:text-2xl font-bold text-teal-400 mb-1">
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
