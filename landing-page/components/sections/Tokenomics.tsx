'use client';

import { useRef } from 'react';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { useGSAP } from '@gsap/react';

gsap.registerPlugin(ScrollTrigger);

export function Tokenomics() {
  const containerRef = useRef<HTMLDivElement>(null);
  const chartRef = useRef<SVGSVGElement>(null);

  const tokenAllocation = [
    { label: 'Mining Rewards', percentage: 40, color: '#2dd4bf', delay: 0 },
    { label: 'Ecosystem Growth', percentage: 25, color: '#8b5cf6', delay: 0.1 },
    { label: 'Team & Advisors', percentage: 15, color: '#06b6d4', delay: 0.2 },
    { label: 'Liquidity Pool', percentage: 10, color: '#3b82f6', delay: 0.3 },
    { label: 'Community Airdrops', percentage: 10, color: '#10b981', delay: 0.4 },
  ];

  const tokenStats = [
    { label: 'Total Supply', value: '1,000,000,000', suffix: 'BNT' },
    { label: 'Initial Circulation', value: '100,000,000', suffix: 'BNT' },
    { label: 'Token Type', value: 'Utility', suffix: '' },
    { label: 'Blockchain', value: 'Solana', suffix: '' },
  ];

  const utilities = [
    {
      icon: '⛏️',
      title: 'Mining Rewards',
      description: 'Earn BNT through 24-hour cycling mining. Complete cycles and build referral networks for higher rewards.',
    },
    {
      icon: '💰',
      title: 'Hunter Tipping',
      description: 'Reward quality content creators and hunters with BNT tips. Support contributors who provide valuable updates.',
    },
    {
      icon: '🔄',
      title: 'Swap & Exchange',
      description: 'Built-in swap functionality for BNT, USDT, SOL, and more. Trade directly within the platform.',
    },
    {
      icon: '✨',
      title: 'Premium Access',
      description: 'Unlock exclusive features: advanced analytics, priority support, and early access to new tools.',
    },
    {
      icon: '🗳️',
      title: 'DAO Governance',
      description: 'Vote on platform decisions, feature proposals, and community initiatives. Shape the future of Blocnet.',
    },
    {
      icon: '🎁',
      title: 'Exclusive Benefits',
      description: 'Access sponsored project listings, premium subscriptions, and special community events.',
    },
  ];

  useGSAP(() => {
    if (!containerRef.current || !chartRef.current) return;

    // Animate allocation segments
    const segments = chartRef.current.querySelectorAll('.allocation-segment');
    segments.forEach((segment, index) => {
      gsap.from(segment, {
        opacity: 0,
        scale: 0,
        transformOrigin: 'center',
        duration: 1,
        delay: tokenAllocation[index].delay,
        ease: 'back.out(1.7)',
        scrollTrigger: {
          trigger: containerRef.current,
          start: 'top 70%',
          toggleActions: 'play none none reverse',
        },
      });
    });

    // Animate legend items
    gsap.from('.legend-item', {
      opacity: 0,
      x: -30,
      duration: 0.6,
      stagger: 0.1,
      scrollTrigger: {
        trigger: containerRef.current,
        start: 'top 70%',
        toggleActions: 'play none none reverse',
      },
    });

    // Animate stats cards
    gsap.from('.stat-card', {
      opacity: 0,
      y: 50,
      scale: 0.9,
      duration: 0.6,
      stagger: 0.1,
      scrollTrigger: {
        trigger: '.stats-grid',
        start: 'top 80%',
        toggleActions: 'play none none reverse',
      },
    });

    // Animate utility cards
    gsap.from('.utility-card', {
      opacity: 0,
      y: 30,
      duration: 0.5,
      stagger: 0.1,
      scrollTrigger: {
        trigger: '.utilities-grid',
        start: 'top 80%',
        toggleActions: 'play none none reverse',
      },
    });
  }, { scope: containerRef });

  // Calculate pie chart segments
  const createPieSegments = () => {
    let currentAngle = -90; // Start from top
    const radius = 100;
    const centerX = 120;
    const centerY = 120;

    return tokenAllocation.map((item) => {
      const angle = (item.percentage / 100) * 360;
      const startAngle = currentAngle;
      const endAngle = currentAngle + angle;

      const x1 = centerX + radius * Math.cos((startAngle * Math.PI) / 180);
      const y1 = centerY + radius * Math.sin((startAngle * Math.PI) / 180);
      const x2 = centerX + radius * Math.cos((endAngle * Math.PI) / 180);
      const y2 = centerY + radius * Math.sin((endAngle * Math.PI) / 180);

      const largeArc = angle > 180 ? 1 : 0;

      const pathData = [
        `M ${centerX} ${centerY}`,
        `L ${x1} ${y1}`,
        `A ${radius} ${radius} 0 ${largeArc} 1 ${x2} ${y2}`,
        'Z',
      ].join(' ');

      currentAngle += angle;

      return {
        pathData,
        color: item.color,
      };
    });
  };

  const pieSegments = createPieSegments();

  return (
    <section
      ref={containerRef}
      className="py-12 sm:py-16 md:py-24 px-4 sm:px-6 lg:px-8 bg-[#09090b] relative overflow-hidden"
    >
      {/* Background */}
      <div className="absolute inset-0">
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#27272a_1px,transparent_1px),linear-gradient(to_bottom,#27272a_1px,transparent_1px)] bg-[size:4rem_4rem] opacity-20" />
        <div className="absolute top-1/4 right-1/4 w-96 h-96 bg-teal-500/10 rounded-full blur-3xl" />
      </div>

      <div className="relative z-10 max-w-6xl mx-auto">
        {/* Header */}
        <div className="text-center mb-10 sm:mb-14">
          <h2 className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-bold text-foreground mb-3 sm:mb-4">
            <span className="text-transparent bg-clip-text bg-linear-to-r from-teal-400 to-primary">
              BNT Token
            </span>{' '}
            Economics
          </h2>
          <p className="text-sm sm:text-base md:text-lg text-muted max-w-2xl mx-auto">
            Fair distribution model designed to reward community participation
            and long-term platform growth
          </p>
        </div>

        {/* Token Stats */}
        <div className="stats-grid grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4 mb-10 sm:mb-14">
          {tokenStats.map((stat) => (
            <div
              key={stat.label}
              className="stat-card p-4 sm:p-5 bg-linear-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-teal-500/20 rounded-xl text-center"
            >
              <p className="text-xs sm:text-sm text-muted mb-1 sm:mb-2">
                {stat.label}
              </p>
              <p className="text-base sm:text-lg md:text-xl font-bold text-transparent bg-clip-text bg-linear-to-r from-teal-400 to-primary">
                {stat.value}
              </p>
              {stat.suffix && (
                <p className="text-xs text-teal-400 mt-1">{stat.suffix}</p>
              )}
            </div>
          ))}
        </div>

        {/* Allocation Chart */}
        <div className="grid lg:grid-cols-2 gap-8 sm:gap-10 mb-10 sm:mb-14">
          {/* Pie Chart */}
          <div className="flex items-center justify-center p-6 sm:p-8 bg-linear-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-teal-500/20 rounded-2xl">
            <svg
              ref={chartRef}
              viewBox="0 0 240 240"
              className="w-full max-w-xs"
            >
              {/* Outer glow */}
              <circle
                cx="120"
                cy="120"
                r="105"
                fill="none"
                stroke="url(#gradient)"
                strokeWidth="2"
                opacity="0.3"
              />

              {/* Pie segments */}
              {pieSegments.map((segment, index) => (
                <path
                  key={index}
                  className="allocation-segment"
                  d={segment.pathData}
                  fill={segment.color}
                  opacity="0.8"
                  stroke="#09090b"
                  strokeWidth="2"
                />
              ))}

              {/* Center circle */}
              <circle
                cx="120"
                cy="120"
                r="40"
                fill="#09090b"
                stroke="url(#gradient)"
                strokeWidth="2"
              />

              <text
                x="120"
                y="115"
                textAnchor="middle"
                className="text-xs fill-teal-400 font-semibold"
              >
                BNT
              </text>
              <text
                x="120"
                y="130"
                textAnchor="middle"
                className="text-[10px] fill-muted"
              >
                Distribution
              </text>

              {/* Gradient definition */}
              <defs>
                <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="100%">
                  <stop offset="0%" stopColor="#2dd4bf" />
                  <stop offset="100%" stopColor="#8b5cf6" />
                </linearGradient>
              </defs>
            </svg>
          </div>

          {/* Legend */}
          <div className="flex flex-col justify-center space-y-3 sm:space-y-4">
            {tokenAllocation.map((item, index) => (
              <div
                key={index}
                className="legend-item flex items-center justify-between p-3 sm:p-4 bg-surface-2/50 backdrop-blur-sm border border-border rounded-xl"
              >
                <div className="flex items-center gap-3">
                  <div
                    className="shrink-0 w-4 h-4 sm:w-5 sm:h-5 rounded-full"
                    style={{ backgroundColor: item.color }}
                  />
                  <span className="text-xs sm:text-sm md:text-base text-foreground font-medium">
                    {item.label}
                  </span>
                </div>
                <span className="text-sm sm:text-base md:text-lg font-bold text-transparent bg-clip-text bg-linear-to-r from-teal-400 to-primary">
                  {item.percentage}%
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Token Utilities */}
        <div>
          <h3 className="text-xl sm:text-2xl md:text-3xl font-bold text-center text-foreground mb-6 sm:mb-8">
            Token <span className="text-teal-400">Utility</span>
          </h3>
          <div className="utilities-grid grid sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-5">
            {utilities.map((utility, index) => (
              <div
                key={index}
                className="utility-card group p-4 sm:p-5 bg-linear-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-border rounded-xl"
              >
                <div className="flex items-start gap-3 sm:gap-4">
                  <div className="shrink-0 w-10 h-10 sm:w-12 sm:h-12 bg-linear-to-br from-teal-500/20 to-primary/20 rounded-xl flex items-center justify-center border border-teal-500/30">
                    <span className="text-xl sm:text-2xl">{utility.icon}</span>
                  </div>
                  <div>
                    <h4 className="text-sm sm:text-base font-semibold text-foreground mb-1 sm:mb-2">
                      {utility.title}
                    </h4>
                    <p className="text-xs sm:text-sm text-muted leading-relaxed">
                      {utility.description}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
