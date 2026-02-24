'use client';

import { useRef } from 'react';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { useGSAP } from '@gsap/react';
import { MagneticButton } from '@/components/ui/MagneticButton';

gsap.registerPlugin(ScrollTrigger);

export function EdgeEngineEnhanced() {
  const containerRef = useRef<HTMLDivElement>(null);
  const networkRef = useRef<SVGSVGElement>(null);

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
      metric: '95%',
    },
    {
      icon: '⏰',
      title: 'Time Sensitivity',
      desc: 'Identifies time-critical opportunities',
      metric: '8.5/10',
    },
    {
      icon: '📊',
      title: 'Impact Assessment',
      desc: 'Evaluates potential portfolio significance',
      metric: 'High',
    },
    {
      icon: '🧠',
      title: 'Pattern Learning',
      desc: 'Learns from your behavior',
      metric: 'Active',
    },
  ];

  useGSAP(() => {
    if (!containerRef.current) return;

    // Animate header
    gsap.from('.bee-header', {
      opacity: 0,
      y: 50,
      duration: 0.8,
      scrollTrigger: {
        trigger: containerRef.current,
        start: 'top 70%',
      },
    });

    // Animate decision cards
    gsap.from('.decision-card', {
      opacity: 0,
      x: -50,
      duration: 0.6,
      stagger: 0.15,
      scrollTrigger: {
        trigger: '.decisions-container',
        start: 'top 75%',
      },
    });

    // Animate scoring cards with 3D rotation
    gsap.from('.scoring-card', {
      opacity: 0,
      rotationY: 90,
      y: 30,
      duration: 0.7,
      stagger: 0.1,
      scrollTrigger: {
        trigger: '.scoring-grid',
        start: 'top 75%',
      },
    });

    // Animate benefits with scale
    gsap.from('.benefit-stat', {
      opacity: 0,
      scale: 0.5,
      duration: 0.6,
      stagger: 0.1,
      ease: 'back.out(1.7)',
      scrollTrigger: {
        trigger: '.benefits-grid',
        start: 'top 80%',
      },
    });

    // Animated network visualization
    if (networkRef.current) {
      const nodes = networkRef.current.querySelectorAll('.network-node');
      const connections = networkRef.current.querySelectorAll('.network-connection');

      // Animate connections
      gsap.from(connections, {
        strokeDashoffset: 1000,
        duration: 2,
        stagger: 0.1,
        ease: 'power2.inOut',
        scrollTrigger: {
          trigger: networkRef.current,
          start: 'top 75%',
        },
      });

      // Pulse animation for nodes
      nodes.forEach((node, index) => {
        gsap.to(node, {
          scale: 1.2,
          opacity: 1,
          duration: 1,
          delay: index * 0.2,
          repeat: -1,
          yoyo: true,
          ease: 'sine.inOut',
          scrollTrigger: {
            trigger: networkRef.current,
            start: 'top 75%',
          },
        });
      });
    }
  }, { scope: containerRef });

  return (
    <section
      ref={containerRef}
      className="py-12 sm:py-16 md:py-24 px-4 sm:px-6 lg:px-8 bg-linear-to-b from-[#09090b] via-teal-950/5 to-[#09090b] relative overflow-hidden"
    >
      {/* Background */}
      <div className="absolute inset-0">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-teal-500/10 rounded-full blur-3xl animate-pulse" />
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-primary/10 rounded-full blur-3xl animate-pulse" style={{ animationDelay: '1s' }} />
      </div>

      <div className="relative z-10 max-w-6xl mx-auto">
        {/* Header */}
        <div className="bee-header text-center mb-10 sm:mb-14">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-teal-500/10 border border-teal-500/20 rounded-full mb-4 sm:mb-6">
            <span className="text-xl sm:text-2xl">🐝</span>
            <span className="text-xs sm:text-sm font-semibold text-teal-400">
              AI-Powered Intelligence
            </span>
          </div>

          <h2 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold text-foreground mb-4 sm:mb-6">
            Meet{' '}
            <span className="text-transparent bg-clip-text bg-linear-to-r from-teal-400 to-primary">
              Blocnet Edge Engine
            </span>
          </h2>

          <p className="text-base sm:text-lg md:text-xl text-muted max-w-3xl mx-auto leading-relaxed">
            The world's first AI-powered decision engine for crypto updates.
            Smart recommendations, urgency scoring, and personalized insights.
          </p>
        </div>

        {/* AI Network Visualization */}
        <div className="mb-10 sm:mb-14 flex justify-center">
          <div className="relative p-6 sm:p-8 bg-linear-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-teal-500/20 rounded-2xl">
            <svg
              ref={networkRef}
              viewBox="0 0 400 200"
              className="w-full max-w-2xl h-auto"
            >
              {/* Connections */}
              <line
                className="network-connection"
                x1="200"
                y1="100"
                x2="100"
                y2="50"
                stroke="url(#lineGradient)"
                strokeWidth="2"
                strokeDasharray="5,5"
              />
              <line
                className="network-connection"
                x1="200"
                y1="100"
                x2="300"
                y2="50"
                stroke="url(#lineGradient)"
                strokeWidth="2"
                strokeDasharray="5,5"
              />
              <line
                className="network-connection"
                x1="200"
                y1="100"
                x2="100"
                y2="150"
                stroke="url(#lineGradient)"
                strokeWidth="2"
                strokeDasharray="5,5"
              />
              <line
                className="network-connection"
                x1="200"
                y1="100"
                x2="300"
                y2="150"
                stroke="url(#lineGradient)"
                strokeWidth="2"
                strokeDasharray="5,5"
              />

              {/* Center Node (BEE) */}
              <circle
                className="network-node"
                cx="200"
                cy="100"
                r="25"
                fill="url(#nodeGradient)"
                opacity="0.8"
              />
              <text
                x="200"
                y="105"
                textAnchor="middle"
                className="text-sm fill-white font-bold"
              >
                BEE
              </text>

              {/* Peripheral Nodes */}
              <circle className="network-node" cx="100" cy="50" r="15" fill="#2dd4bf" opacity="0.6" />
              <circle className="network-node" cx="300" cy="50" r="15" fill="#8b5cf6" opacity="0.6" />
              <circle className="network-node" cx="100" cy="150" r="15" fill="#3b82f6" opacity="0.6" />
              <circle className="network-node" cx="300" cy="150" r="15" fill="#10b981" opacity="0.6" />

              {/* Labels */}
              <text x="100" y="35" textAnchor="middle" className="text-[10px] fill-teal-400">
                Updates
              </text>
              <text x="300" y="35" textAnchor="middle" className="text-[10px] fill-purple-400">
                Projects
              </text>
              <text x="100" y="175" textAnchor="middle" className="text-[10px] fill-blue-400">
                User Data
              </text>
              <text x="300" y="175" textAnchor="middle" className="text-[10px] fill-green-400">
                Insights
              </text>

              {/* Gradients */}
              <defs>
                <linearGradient id="lineGradient" x1="0%" y1="0%" x2="100%" y2="0%">
                  <stop offset="0%" stopColor="#2dd4bf" stopOpacity="0.3" />
                  <stop offset="100%" stopColor="#8b5cf6" stopOpacity="0.3" />
                </linearGradient>
                <radialGradient id="nodeGradient">
                  <stop offset="0%" stopColor="#2dd4bf" />
                  <stop offset="100%" stopColor="#8b5cf6" />
                </radialGradient>
              </defs>
            </svg>
          </div>
        </div>

        {/* Decision Engine */}
        <div className="decisions-container mb-10 sm:mb-14">
          <h3 className="text-xl sm:text-2xl md:text-3xl font-bold text-center text-foreground mb-6 sm:mb-8">
            Smart <span className="text-teal-400">Decision Recommendations</span>
          </h3>

          <div className="grid md:grid-cols-3 gap-4 sm:gap-6">
            {decisions.map((item) => (
              <div
                key={item.action}
                className="decision-card group p-5 sm:p-6 bg-linear-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-border rounded-xl hover:border-teal-500/30 transition-all duration-300 hover:scale-105"
              >
                <div className="flex items-center gap-3 mb-3 sm:mb-4">
                  <div className={`w-12 h-12 sm:w-14 sm:h-14 bg-linear-to-br ${item.color} rounded-xl flex items-center justify-center text-2xl sm:text-3xl group-hover:scale-110 transition-transform`}>
                    {item.icon}
                  </div>
                  <span className={`text-lg sm:text-xl font-bold ${item.textColor}`}>
                    {item.action}
                  </span>
                </div>
                <p className="text-xs sm:text-sm text-muted leading-relaxed">
                  {item.desc}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* Scoring Factors */}
        <div className="scoring-grid grid sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-5 mb-10 sm:mb-14">
          {scoringFactors.map((factor, index) => (
            <div
              key={index}
              className="scoring-card p-4 sm:p-5 bg-linear-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-teal-500/20 rounded-xl hover:border-teal-500/40 transition-all duration-300"
              style={{ perspective: '1000px' }}
            >
              <div className="text-2xl sm:text-3xl mb-2 sm:mb-3">{factor.icon}</div>
              <h4 className="text-sm sm:text-base font-semibold text-foreground mb-1 sm:mb-2">
                {factor.title}
              </h4>
              <p className="text-xs text-muted mb-2 sm:mb-3 leading-relaxed">
                {factor.desc}
              </p>
              <div className="text-xs sm:text-sm font-bold text-transparent bg-clip-text bg-linear-to-r from-teal-400 to-primary">
                {factor.metric}
              </div>
            </div>
          ))}
        </div>

        {/* Benefits */}
        <div className="benefits-grid grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4 mb-8 sm:mb-10">
          {[
            { metric: '10x', label: 'Faster Decisions' },
            { metric: '24/7', label: 'Always Active' },
            { metric: '100%', label: 'Personalized' },
            { metric: '∞', label: 'Learning System' },
          ].map((stat) => (
            <div
              key={stat.label}
              className="benefit-stat p-4 sm:p-5 bg-linear-to-br from-teal-500/10 to-primary/10 border border-teal-500/20 rounded-xl text-center hover:scale-110 transition-transform duration-300"
            >
              <div className="text-2xl sm:text-3xl md:text-4xl font-bold text-transparent bg-clip-text bg-linear-to-r from-teal-300 to-primary mb-1 sm:mb-2">
                {stat.metric}
              </div>
              <div className="text-xs sm:text-sm font-semibold text-teal-300">
                {stat.label}
              </div>
            </div>
          ))}
        </div>

        {/* CTA */}
        <div className="text-center">
          <p className="text-sm sm:text-base text-muted mb-4 sm:mb-6">
            Experience AI-powered crypto intelligence
          </p>
          <MagneticButton
            href="#download"
            className="px-6 py-3 sm:px-8 sm:py-4 bg-linear-to-r from-teal-500 to-primary text-white rounded-xl font-semibold text-sm sm:text-base shadow-lg shadow-teal-500/25"
          >
            Get Started with BEE
          </MagneticButton>
        </div>
      </div>
    </section>
  );
}
