'use client';

export function EdgeEngine() {
  return (
    <section className="py-12 sm:py-16 md:py-24 px-4 sm:px-6 lg:px-8 bg-gradient-to-b from-[#09090b] via-teal-950/5 to-[#09090b] relative overflow-hidden">
      {/* Background Effects */}
      <div className="absolute inset-0">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-teal-500/10 rounded-full blur-3xl" />
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-primary/10 rounded-full blur-3xl" />
      </div>

      <div className="relative z-10 max-w-6xl mx-auto">
        {/* Section Header */}
        <div className="text-center mb-10 sm:mb-14">

          <h2 className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-bold text-foreground mb-3 sm:mb-4 md:mb-6">
            Introducing{' '}
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-teal-400 to-primary">
              Blocnet Edge Engine (BEE)
            </span>
          </h2>

          <p className="text-sm sm:text-base md:text-lg text-muted max-w-3xl mx-auto leading-relaxed">
            The world's first AI-powered decision engine for crypto updates.
            Get intelligent action recommendations, urgency scoring, and
            personalized insights tailored to your interests.
          </p>
        </div>

        {/* Main Content Grid */}
        <div className="grid lg:grid-cols-2 gap-6 sm:gap-8 mb-8 sm:mb-12">
          {/* Feature Card 1: AI Decision Making */}
          <div className="p-6 sm:p-8 bg-gradient-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-teal-500/20 rounded-2xl">
            <div className="flex items-center gap-3 mb-4 sm:mb-6">
              <div className="p-3 bg-gradient-to-br from-teal-500/20 to-primary/20 rounded-xl">
                <span className="text-2xl sm:text-3xl">✨</span>
              </div>
              <h3 className="text-lg sm:text-xl font-bold text-teal-300">
                Smart Decision Engine
              </h3>
            </div>

            <p className="text-sm sm:text-base text-muted mb-6 leading-relaxed">
              BEE analyzes every update in real-time and provides
              intelligent recommendations:
            </p>

            <div className="space-y-3 sm:space-y-4">
              {[
                {
                  action: 'Act Now',
                  desc: 'High-priority updates requiring immediate attention',
                  color: 'text-green-400',
                },
                {
                  action: 'Watch',
                  desc: 'Important updates to monitor closely',
                  color: 'text-amber-400',
                },
                {
                  action: 'Ignore',
                  desc: 'Low-relevance content you can skip',
                  color: 'text-gray-400',
                },
              ].map((item) => (
                <div
                  key={item.action}
                  className="flex items-start gap-3 p-3 sm:p-4 bg-surface-2/50 rounded-lg border border-border"
                >
                  <span className={`text-sm sm:text-base font-bold ${item.color} mt-0.5`}>
                    •
                  </span>
                  <div>
                    <span className={`text-sm sm:text-base font-semibold ${item.color}`}>
                      {item.action}
                    </span>
                    <p className="text-xs sm:text-sm text-muted mt-1">
                      {item.desc}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Feature Card 2: Urgency Scoring */}
          <div className="p-6 sm:p-8 bg-gradient-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-teal-500/20 rounded-2xl">
            <div className="flex items-center gap-3 mb-4 sm:mb-6">
              <div className="p-3 bg-gradient-to-br from-teal-500/20 to-primary/20 rounded-xl">
                <span className="text-2xl sm:text-3xl">⚡</span>
              </div>
              <h3 className="text-lg sm:text-xl font-bold text-teal-300">
                Intelligent Urgency Scoring
              </h3>
            </div>

            <p className="text-sm sm:text-base text-muted mb-6 leading-relaxed">
              Every update gets an Edge Score (0-10+) based on multiple factors:
            </p>

            <div className="space-y-3 sm:space-y-4">
              {[
                {
                  icon: '🎯',
                  title: 'Relevance Analysis',
                  desc: 'Matches updates to your followed projects and interests',
                },
                {
                  icon: '⏰',
                  title: 'Time Sensitivity',
                  desc: 'Identifies time-critical opportunities and announcements',
                },
                {
                  icon: '📊',
                  title: 'Impact Assessment',
                  desc: 'Evaluates potential significance to your portfolio',
                },
                {
                  icon: '🧠',
                  title: 'Pattern Learning',
                  desc: 'Learns from your interactions to improve over time',
                },
              ].map((item) => (
                <div
                  key={item.title}
                  className="flex items-start gap-3 p-3 sm:p-4 bg-surface-2/50 rounded-lg border border-border"
                >
                  <span className="text-xl sm:text-2xl">{item.icon}</span>
                  <div>
                    <h4 className="text-sm sm:text-base font-semibold text-foreground">
                      {item.title}
                    </h4>
                    <p className="text-xs sm:text-sm text-muted mt-1">
                      {item.desc}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Benefits Grid */}
        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 mb-8 sm:mb-12">
          {[
            {
              metric: '10x',
              label: 'Faster Decision Making',
              desc: 'AI-powered insights save hours of manual research',
            },
            {
              metric: '24/7',
              label: 'Always Active',
              desc: 'Continuous monitoring and analysis, never miss a beat',
            },
            {
              metric: '100%',
              label: 'Personalized',
              desc: 'Tailored recommendations based on your behavior',
            },
            {
              metric: '∞',
              label: 'Learning System',
              desc: 'Gets smarter with every interaction and feedback',
            },
          ].map((stat) => (
            <div
              key={stat.label}
              className="p-4 sm:p-6 bg-gradient-to-br from-teal-500/10 to-primary/10 border border-teal-500/20 rounded-xl text-center"
            >
              <div className="text-2xl sm:text-3xl md:text-4xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-teal-300 to-primary mb-2">
                {stat.metric}
              </div>
              <div className="text-xs sm:text-sm font-semibold text-teal-300 mb-2">
                {stat.label}
              </div>
              <p className="text-[10px] sm:text-xs text-muted leading-relaxed">
                {stat.desc}
              </p>
            </div>
          ))}
        </div>

        {/* Explainability Feature */}
        <div className="p-6 sm:p-8 bg-gradient-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-teal-500/20 rounded-2xl">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-6">
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-3 sm:mb-4">
                <span className="text-2xl sm:text-3xl">🔍</span>
                <h3 className="text-lg sm:text-xl font-bold text-teal-300">
                  Transparent AI Explanations
                </h3>
              </div>
              <p className="text-sm sm:text-base text-muted leading-relaxed mb-4">
                Curious why BEE made a recommendation? Click "Why ranked?"
                to see the complete reasoning behind every decision. Full
                transparency, no black boxes.
              </p>
              <div className="flex flex-wrap gap-2">
                {['Scoring factors', 'Confidence levels', 'Alternative actions'].map(
                  (tag) => (
                    <span
                      key={tag}
                      className="text-[10px] sm:text-xs px-2 py-1 sm:px-3 sm:py-1.5 bg-teal-500/10 text-teal-400 rounded-full border border-teal-500/20"
                    >
                      {tag}
                    </span>
                  )
                )}
              </div>
            </div>
            <div className="flex-shrink-0">
              <div className="p-4 sm:p-6 bg-gradient-to-br from-teal-500/20 to-primary/20 rounded-xl border border-teal-500/30">
                <div className="text-3xl sm:text-4xl md:text-5xl font-mono font-bold text-transparent bg-clip-text bg-gradient-to-r from-teal-300 to-primary">
                  ?
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* CTA */}
        <div className="mt-10 sm:mt-12 text-center">
          <p className="text-sm sm:text-base text-muted mb-4 sm:mb-6">
            Experience the future of crypto intelligence
          </p>
          <a
            href="#download"
            className="inline-block px-6 py-3 sm:px-8 sm:py-4 bg-gradient-to-r from-teal-500 to-primary text-white rounded-xl font-semibold text-sm sm:text-base shadow-lg shadow-teal-500/25"
          >
            Get Started with BEE
          </a>
        </div>
      </div>
    </section>
  );
}
