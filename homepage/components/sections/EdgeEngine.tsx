'use client';

export function EdgeEngine() {
  const decisions = [
    {
      action: 'Act Now',
      desc: 'High-priority updates requiring immediate attention',
      color: 'from-green-400 to-green-600',
      textColor: 'text-green-400',
      icon: '🚨',
    },
    {
      action: 'Watch',
      desc: 'Important updates to monitor closely',
      color: 'from-amber-400 to-amber-600',
      textColor: 'text-amber-400',
      icon: '👁️',
    },
    {
      action: 'Ignore',
      desc: 'Low-relevance content you can skip',
      color: 'from-gray-400 to-gray-600',
      textColor: 'text-gray-400',
      icon: '🔇',
    },
  ];

  const scoringFactors = [
    {
      icon: '🎯',
      title: 'Relevance Analysis',
      desc: 'Matches updates to your followed projects',
    },
    {
      icon: '⏰',
      title: 'Time Sensitivity',
      desc: 'Identifies time-critical opportunities',
    },
    {
      icon: '📊',
      title: 'Impact Assessment',
      desc: 'Evaluates potential portfolio significance',
    },
    {
      icon: '🧠',
      title: 'Pattern Learning',
      desc: 'Learns from your behavior over time',
    },
  ];

  return (
    <section className="py-16 sm:py-20 md:py-24 px-4 sm:px-6 lg:px-8 bg-linear-to-b from-[#09090b] via-teal-950/5 to-[#09090b] relative overflow-hidden">
      {/* Background Effects */}
      <div className="absolute inset-0">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-teal-500/10 rounded-full blur-3xl" />
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-primary/10 rounded-full blur-3xl" />
      </div>

      <div className="relative z-10 max-w-6xl mx-auto">
        {/* Header */}
        <div className="text-center mb-14">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-teal-500/10 border border-teal-500/20 rounded-full mb-6">
            <span className="text-2xl">🐝</span>
            <span className="text-sm font-semibold text-teal-400">
              AI-Powered Intelligence
            </span>
          </div>

          <h2 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold text-foreground mb-6">
            Meet{' '}
            <span className="text-transparent bg-clip-text bg-linear-to-r from-teal-400 to-primary">
              Blocnet Edge Engine
            </span>
          </h2>

          <p className="text-base sm:text-lg md:text-xl text-muted max-w-3xl mx-auto leading-relaxed">
            The world&apos;s first AI-powered decision engine for crypto updates.
            Smart recommendations, urgency scoring, and personalized insights.
          </p>
        </div>

        {/* Decision Engine */}
        <div className="mb-14">
          <h3 className="text-2xl sm:text-3xl font-bold text-center text-foreground mb-8">
            Smart <span className="text-teal-400">Decision Recommendations</span>
          </h3>

          <div className="grid md:grid-cols-3 gap-6">
            {decisions.map((item) => (
              <div
                key={item.action}
                className="p-6 bg-linear-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-border rounded-xl transition-colors hover:border-teal-500/30"
              >
                <div className="flex items-center gap-3 mb-4">
                  <div className={`w-14 h-14 bg-linear-to-br ${item.color} rounded-xl flex items-center justify-center text-3xl`}>
                    {item.icon}
                  </div>
                  <span className={`text-xl font-bold ${item.textColor}`}>
                    {item.action}
                  </span>
                </div>
                <p className="text-sm text-muted leading-relaxed">
                  {item.desc}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* Scoring Factors */}
        <div className="mb-14">
          <h3 className="text-2xl sm:text-3xl font-bold text-center text-foreground mb-8">
            How <span className="text-teal-400">BEE Works</span>
          </h3>

          <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-5">
            {scoringFactors.map((factor, index) => (
              <div
                key={index}
                className="p-6 bg-linear-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-teal-500/20 rounded-xl transition-colors hover:border-teal-500/40"
              >
                <div className="text-3xl mb-3">{factor.icon}</div>
                <h4 className="text-base font-semibold text-foreground mb-2">
                  {factor.title}
                </h4>
                <p className="text-sm text-muted leading-relaxed">
                  {factor.desc}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* Benefits */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-10">
          {[
            { metric: '10x', label: 'Faster Decisions' },
            { metric: '24/7', label: 'Always Active' },
            { metric: '100%', label: 'Personalized' },
            { metric: '∞', label: 'Learning System' },
          ].map((stat) => (
            <div
              key={stat.label}
              className="p-6 bg-linear-to-br from-teal-500/10 to-primary/10 border border-teal-500/20 rounded-xl text-center"
            >
              <div className="text-4xl font-bold text-transparent bg-clip-text bg-linear-to-r from-teal-300 to-primary mb-2">
                {stat.metric}
              </div>
              <div className="text-sm font-semibold text-teal-300">
                {stat.label}
              </div>
            </div>
          ))}
        </div>

        {/* CTA */}
        <div className="text-center">
          <p className="text-base text-muted mb-6">
            Experience AI-powered crypto intelligence
          </p>
          <a
            href="#download"
            className="inline-block px-8 py-4 bg-linear-to-r from-teal-500 to-primary text-white rounded-xl font-semibold transition-opacity hover:opacity-90 text-base shadow-lg shadow-teal-500/25"
          >
            Get Started with BEE
          </a>
        </div>
      </div>
    </section>
  );
}
