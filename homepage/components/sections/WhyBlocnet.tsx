'use client';

export function WhyBlocnet() {
  const points = [
    {
      title: 'Follow Only What You Care About',
      description:
        'Users follow specific projects and receive timely updates for those projects, instead of generic noisy feeds.',
      badge: 'Personalized',
    },
    {
      title: 'Contributor Accountability Built In',
      description:
        'Ontas are measured by trust and performance signals. Poor-quality behavior can reduce reputation and remove Onta status.',
      badge: 'Trust Layer',
    },
    {
      title: 'Continuous Guidance, Not One-Off Posts',
      description:
        'Project updates are tracked through full participation cycles such as KYC windows, claims, launches, and key deadlines.',
      badge: 'Execution Focus',
    },
  ];

  return (
    <section
      id="why-blocnet"
      className="py-12 sm:py-16 md:py-20 px-4 sm:px-6 lg:px-8 bg-[#09090b] relative overflow-hidden"
    >
      <div className="absolute inset-0">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_top,_rgba(20,184,166,0.12),_transparent_45%)]" />
      </div>

      <div className="relative z-10 max-w-6xl mx-auto">
        <div className="text-center mb-10 sm:mb-12">
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-bold text-foreground mb-3 sm:mb-4">
            Why Blocnet Is Different
          </h2>
          <p className="text-sm sm:text-base text-muted max-w-3xl mx-auto">
            Most platforms optimize for posting volume. Blocnet optimizes for
            accountable updates and user action outcomes.
          </p>
        </div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
          {points.map((point) => (
            <article
              key={point.title}
              className="p-5 sm:p-6 bg-gradient-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-teal-500/20 rounded-2xl"
            >
              <span className="inline-flex px-2.5 py-1 rounded-full text-xs font-semibold bg-teal-500/15 text-teal-300 border border-teal-500/25 mb-3">
                {point.badge}
              </span>
              <h3 className="text-base sm:text-lg font-bold text-foreground mb-2">
                {point.title}
              </h3>
              <p className="text-xs sm:text-sm text-muted leading-relaxed">
                {point.description}
              </p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
