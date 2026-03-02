'use client';

import Link from 'next/link';

export function AboutContent() {
  const mission = [
    {
      icon: '🎯',
      title: 'Our Mission',
      description:
        'To democratize crypto intelligence by providing AI-powered insights and community-driven content that empowers everyone to make informed decisions in the Web3 space.',
    },
    {
      icon: '🔮',
      title: 'Our Vision',
      description:
        'To become the global standard for crypto intelligence, where BEE powers millions of users daily with personalized, actionable insights across all blockchain ecosystems.',
    },
    {
      icon: '💎',
      title: 'Our Values',
      description:
        'Transparency, community-first approach, continuous innovation, and rewarding quality contributions. We believe in building together and sharing success.',
    },
  ];

  const milestones = [
    {
      date: 'Q3 2024',
      title: 'Concept & Planning',
      description: 'Initial research, product strategy, and technical architecture design.',
    },
    {
      date: 'Q4 2024',
      title: 'Platform Launch',
      description: 'Launched core platform with Hunter system, project tracking, and community features.',
    },
    {
      date: 'Q1 2026',
      title: 'BEE & Mining',
      description: 'Released Blocnet Edge Engine (BEE) AI system and cycling mining mechanism.',
    },
    {
      date: 'Q2 2026',
      title: 'Token Economy',
      description: 'Planned BNT token launch, multi-asset wallet, and airdrop to early miners.',
    },
  ];

  const team = [
    {
      role: 'Product & Engineering',
      description: 'Building innovative solutions for crypto intelligence and AI-powered decision making.',
    },
    {
      role: 'Community & Growth',
      description: 'Fostering global community engagement and driving platform adoption.',
    },
    {
      role: 'Research & AI',
      description: 'Developing BEE algorithms and advanced crypto market analysis systems.',
    },
  ];

  const principles = [
    {
      icon: '🤖',
      title: 'AI-First Approach',
      description: 'BEE analyzes thousands of updates daily to surface what matters most to you.',
    },
    {
      icon: '👥',
      title: 'Community-Driven',
      description: 'Hunters contribute quality content. Community validates. Everyone benefits.',
    },
    {
      icon: '🔓',
      title: 'Open & Transparent',
      description: 'Full transparency in AI decisions, platform metrics, and future development.',
    },
    {
      icon: '🏆',
      title: 'Merit-Based Rewards',
      description: 'Quality contributions, active mining, and helpful community members earn more.',
    },
    {
      icon: '🌍',
      title: 'Global Accessibility',
      description: 'Built for everyone, everywhere. No barriers to accessing crypto intelligence.',
    },
    {
      icon: '🔒',
      title: 'Security First',
      description: 'Your assets and data are protected with industry-leading security practices.',
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
            Building the Future of{' '}
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-teal-400 to-primary">
              Crypto Intelligence
            </span>
          </h1>

          <p className="text-sm sm:text-base md:text-lg text-muted max-w-3xl mx-auto leading-relaxed">
            Blocnet combines AI-powered intelligence, community collaboration, and
            innovative rewards to create the ultimate platform for navigating the
            crypto ecosystem.
          </p>
        </div>

        {/* Mission, Vision, Values */}
        <div className="grid sm:grid-cols-3 gap-4 sm:gap-6 mb-12 sm:mb-16">
          {mission.map((item) => (
            <div
              key={item.title}
              className="p-5 sm:p-6 bg-gradient-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-teal-500/20 rounded-2xl text-center"
            >
              <div className="text-3xl sm:text-4xl mb-3 sm:mb-4">{item.icon}</div>
              <h3 className="text-base sm:text-lg font-bold text-foreground mb-2 sm:mb-3">
                {item.title}
              </h3>
              <p className="text-xs sm:text-sm text-muted leading-relaxed">
                {item.description}
              </p>
            </div>
          ))}
        </div>

        {/* Story */}
        <div className="p-6 sm:p-8 bg-gradient-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-border rounded-2xl mb-12 sm:mb-16">
          <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4 sm:mb-6">
            Our Story
          </h2>
          <div className="space-y-4 text-sm sm:text-base text-muted leading-relaxed">
            <p>
              Blocnet was born from a simple observation: the crypto space moves fast, but
              finding quality information is slow and scattered. Airdrops, updates, project
              launches — critical opportunities buried in noise across dozens of channels.
            </p>
            <p>
              We built Blocnet to solve this. A platform where <strong className="text-foreground">Hunters</strong> share
              verified alpha, <strong className="text-foreground">BEE</strong> ranks what matters to you, and the{' '}
              <strong className="text-foreground">community</strong> rewards quality contributions with BNT tokens.
            </p>
            <p>
              Today, Blocnet is more than a content aggregator. It is an AI-powered intelligence
              network where every user — from casual observers to active hunters — has the tools
              to stay ahead in crypto. And we are just getting started.
            </p>
          </div>
        </div>

        {/* Milestones */}
        <div className="mb-12 sm:mb-16">
          <h2 className="text-xl sm:text-2xl md:text-3xl font-bold text-center mb-8 sm:mb-10">
            Our Journey
          </h2>
          <div className="relative">
            {/* Timeline line */}
            <div className="absolute left-6 top-0 bottom-0 w-0.5 bg-gradient-to-b from-teal-500/30 via-primary/30 to-transparent hidden sm:block" />

            <div className="space-y-6 sm:space-y-8">
              {milestones.map((milestone, index) => (
                <div key={index} className="relative pl-0 sm:pl-16">
                  {/* Dot */}
                  <div className="absolute left-0 sm:left-4 top-2 w-5 h-5 bg-gradient-to-br from-teal-400 to-primary rounded-full border-2 border-[#09090b] hidden sm:block" />

                  <div className="p-5 sm:p-6 bg-gradient-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-border rounded-2xl">
                    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-2">
                      <h3 className="text-base sm:text-lg font-bold text-foreground">
                        {milestone.title}
                      </h3>
                      <span className="text-xs sm:text-sm text-teal-400 font-semibold">
                        {milestone.date}
                      </span>
                    </div>
                    <p className="text-xs sm:text-sm text-muted leading-relaxed">
                      {milestone.description}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Core Principles */}
        <div className="mb-12 sm:mb-16">
          <h2 className="text-xl sm:text-2xl md:text-3xl font-bold text-center mb-8 sm:mb-10">
            What We Stand For
          </h2>
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
            {principles.map((principle) => (
              <div
                key={principle.title}
                className="p-5 sm:p-6 bg-gradient-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-border rounded-2xl"
              >
                <div className="text-3xl sm:text-4xl mb-3 sm:mb-4">
                  {principle.icon}
                </div>
                <h3 className="text-base sm:text-lg font-bold text-foreground mb-2">
                  {principle.title}
                </h3>
                <p className="text-xs sm:text-sm text-muted leading-relaxed">
                  {principle.description}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* Team */}
        <div className="mb-12 sm:mb-16">
          <h2 className="text-xl sm:text-2xl md:text-3xl font-bold text-center mb-8 sm:mb-10">
            Our Team
          </h2>
          <div className="grid sm:grid-cols-3 gap-4 sm:gap-6">
            {team.map((area) => (
              <div
                key={area.role}
                className="p-5 sm:p-6 bg-gradient-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-border rounded-2xl text-center"
              >
                <h3 className="text-base sm:text-lg font-bold text-teal-300 mb-2 sm:mb-3">
                  {area.role}
                </h3>
                <p className="text-xs sm:text-sm text-muted leading-relaxed">
                  {area.description}
                </p>
              </div>
            ))}
          </div>
          <p className="text-xs sm:text-sm text-muted text-center mt-6 sm:mt-8">
            We are a lean, remote-first team passionate about crypto and AI innovation.
            Interested in joining? Reach out at{' '}
            <a
              href="mailto:blocnetapp@gmail.com"
              className="text-teal-400"
            >
              blocnetapp@gmail.com
            </a>
          </p>
        </div>

        {/* CTA */}
        <div className="p-6 sm:p-8 md:p-10 bg-gradient-to-br from-teal-500/10 to-primary/10 border border-teal-500/20 rounded-2xl text-center">
          <h2 className="text-xl sm:text-2xl md:text-3xl font-bold text-foreground mb-3 sm:mb-4">
            Join Our Mission
          </h2>
          <p className="text-sm sm:text-base text-muted mb-6 sm:mb-8 max-w-2xl mx-auto">
            Be part of the movement to make crypto intelligence accessible to everyone.
            Download Blocnet and experience the future today.
          </p>
          <Link
            href="/#download"
            className="inline-block px-6 py-3 sm:px-8 sm:py-4 bg-gradient-to-r from-teal-500 to-primary text-white rounded-xl font-semibold text-sm sm:text-base shadow-lg shadow-teal-500/25 "
          >
            Download Blocnet
          </Link>
        </div>
      </div>
    </section>
  );
}
