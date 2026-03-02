'use client';

import { useRef, useState, useEffect } from 'react';
import gsap from 'gsap';
import { useGSAP } from '@gsap/react';

interface Activity {
  id: string;
  type: 'mining' | 'update' | 'project' | 'tip';
  user: string;
  action: string;
  time: string;
  amount?: string;
  icon: string;
}

export function LiveActivity() {
  const containerRef = useRef<HTMLDivElement>(null);
  const [activities, setActivities] = useState<Activity[]>([
    {
      id: '1',
      type: 'mining',
      user: '@crypto_hunter',
      action: 'earned 125 BNT from mining',
      time: '2s ago',
      icon: '⛏️',
    },
    {
      id: '2',
      type: 'update',
      user: '@blockchain_news',
      action: 'posted update on Solana',
      time: '15s ago',
      icon: '📰',
    },
    {
      id: '3',
      type: 'project',
      user: '@defi_tracker',
      action: 'added new project: Raydium',
      time: '32s ago',
      icon: '🚀',
    },
    {
      id: '4',
      type: 'tip',
      user: '@generous_user',
      action: 'tipped 50 BNT to @top_hunter',
      time: '1m ago',
      amount: '50 BNT',
      icon: '💰',
    },
    {
      id: '5',
      type: 'mining',
      user: '@daily_miner',
      action: 'completed mining cycle',
      time: '2m ago',
      icon: '⛏️',
    },
  ]);

  // Simulate new activities
  useEffect(() => {
    const mockActivities: Omit<Activity, 'id' | 'time'>[] = [
      {
        type: 'mining',
        user: '@crypto_enthusiast',
        action: 'earned 200 BNT from mining',
        icon: '⛏️',
      },
      {
        type: 'update',
        user: '@market_watcher',
        action: 'posted update on Bitcoin',
        icon: '📰',
      },
      {
        type: 'project',
        user: '@project_hunter',
        action: 'added new project: Jupiter',
        icon: '🚀',
      },
      {
        type: 'tip',
        user: '@supporter',
        action: 'tipped 25 BNT to @hunter123',
        amount: '25 BNT',
        icon: '💰',
      },
    ];

    const interval = setInterval(() => {
      const randomActivity = mockActivities[Math.floor(Math.random() * mockActivities.length)];
      const newActivity: Activity = {
        ...randomActivity,
        id: Date.now().toString(),
        time: 'Just now',
      };

      setActivities(prev => [newActivity, ...prev.slice(0, 9)]);
    }, 5000); // New activity every 5 seconds

    return () => clearInterval(interval);
  }, []);

  useGSAP(() => {
    if (!containerRef.current) return;

    // Animate header
    gsap.from('.activity-header', {
      opacity: 0,
      y: 30,
      duration: 0.8,
      scrollTrigger: {
        trigger: containerRef.current,
        start: 'top 70%',
      },
    });

    // Animate initial activities
    gsap.from('.activity-item', {
      opacity: 0,
      x: -30,
      duration: 0.5,
      stagger: 0.1,
      scrollTrigger: {
        trigger: containerRef.current,
        start: 'top 70%',
      },
    });
  }, { scope: containerRef });

  // Animate new activities
  useEffect(() => {
    const newItem = document.querySelector('.activity-item:first-child');
    if (!newItem) return;

    gsap.fromTo(
      newItem,
      {
        opacity: 0,
        x: -30,
        backgroundColor: 'rgba(45, 212, 191, 0.2)',
      },
      {
        opacity: 1,
        x: 0,
        backgroundColor: 'rgba(39, 39, 42, 0.5)',
        duration: 0.5,
        ease: 'power2.out',
      }
    );
  }, [activities]);

  const getTypeColor = (type: string) => {
    switch (type) {
      case 'mining':
        return 'text-teal-400 border-teal-500/30';
      case 'update':
        return 'text-blue-400 border-blue-500/30';
      case 'project':
        return 'text-purple-400 border-purple-500/30';
      case 'tip':
        return 'text-amber-400 border-amber-500/30';
      default:
        return 'text-muted border-border';
    }
  };

  return (
    <section
      ref={containerRef}
      className="py-12 sm:py-16 md:py-20 px-4 sm:px-6 lg:px-8 bg-[#09090b] relative overflow-hidden"
    >
      {/* Background */}
      <div className="absolute inset-0">
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#27272a_1px,transparent_1px),linear-gradient(to_bottom,#27272a_1px,transparent_1px)] bg-[size:4rem_4rem] opacity-20" />
        <div className="absolute top-1/2 left-1/4 w-96 h-96 bg-teal-500/10 rounded-full blur-3xl" />
      </div>

      <div className="relative z-10 max-w-4xl mx-auto">
        {/* Header */}
        <div className="activity-header text-center mb-8 sm:mb-10">
          <div className="inline-flex items-center gap-2 px-3 py-1.5 sm:px-4 sm:py-2 bg-teal-500/10 border border-teal-500/20 rounded-full mb-3 sm:mb-4">
            <span className="relative flex h-2 w-2 sm:h-3 sm:w-3">
              <span className=" absolute inline-flex h-full w-full rounded-full bg-teal-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 sm:h-3 sm:w-3 bg-teal-500"></span>
            </span>
            <span className="text-xs sm:text-sm font-semibold text-teal-400">
              Live Activity
            </span>
          </div>

          <h2 className="text-xl sm:text-2xl md:text-3xl font-bold text-foreground mb-2 sm:mb-3">
            See What&apos;s <span className="text-teal-400">Happening Now</span>
          </h2>
          <p className="text-xs sm:text-sm text-muted max-w-xl mx-auto">
            Real-time activity from the Blocnet community. Join thousands of users earning, sharing, and growing together.
          </p>
        </div>

        {/* Activity Feed */}
        <div className="p-4 sm:p-6 bg-linear-to-br from-surface-2/80 to-surface-2/40 backdrop-blur-sm border border-teal-500/20 rounded-2xl">
          <div className="space-y-2 sm:space-y-3 max-h-96 sm:max-h-[500px] overflow-y-auto custom-scrollbar">
            {activities.map((activity) => (
              <div
                key={activity.id}
                className={`activity-item flex items-start gap-3 sm:gap-4 p-3 sm:p-4 bg-surface-2/50 backdrop-blur-sm border ${getTypeColor(activity.type)} rounded-xl`}
              >
                {/* Icon */}
                <div className="shrink-0 w-8 h-8 sm:w-10 sm:h-10 bg-linear-to-br from-teal-500/20 to-primary/20 rounded-lg flex items-center justify-center border border-teal-500/30 text-lg sm:text-xl">
                  {activity.icon}
                </div>

                {/* Content */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2 mb-1">
                    <p className="text-xs sm:text-sm text-foreground">
                      <span className="font-semibold text-teal-400">
                        {activity.user}
                      </span>{' '}
                      <span className="text-muted">{activity.action}</span>
                    </p>
                    <span className="shrink-0 text-[10px] sm:text-xs text-muted">
                      {activity.time}
                    </span>
                  </div>

                  {/* Amount badge if present */}
                  {activity.amount && (
                    <div className="inline-flex items-center gap-1 px-2 py-0.5 sm:px-3 sm:py-1 bg-amber-400/10 border border-amber-400/20 rounded-full">
                      <span className="text-[10px] sm:text-xs font-semibold text-amber-400">
                        {activity.amount}
                      </span>
                    </div>
                  )}
                </div>

                {/* Type badge */}
                <div className={`shrink-0 px-2 py-0.5 sm:px-3 sm:py-1 rounded-full text-[10px] sm:text-xs font-semibold capitalize border ${getTypeColor(activity.type)}`}>
                  {activity.type}
                </div>
              </div>
            ))}
          </div>

          {/* Stats Footer */}
          <div className="grid grid-cols-3 gap-3 sm:gap-4 mt-4 sm:mt-6 pt-4 sm:pt-6 border-t border-border">
            {[
              { label: 'Active Now', value: '1,247', icon: '👥' },
              { label: 'Last Hour', value: '3,891', icon: '⚡' },
              { label: 'Today', value: '52K+', icon: '📊' },
            ].map((stat) => (
              <div
                key={stat.label}
                className="text-center p-2 sm:p-3 bg-surface-2/50 rounded-lg"
              >
                <div className="text-base sm:text-lg mb-0.5 sm:mb-1">
                  {stat.icon}
                </div>
                <div className="text-sm sm:text-base font-bold text-transparent bg-clip-text bg-linear-to-r from-teal-400 to-primary">
                  {stat.value}
                </div>
                <div className="text-[10px] sm:text-xs text-muted">
                  {stat.label}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* CTA */}
        <div className="text-center mt-6 sm:mt-8">
          <p className="text-xs sm:text-sm text-muted mb-3 sm:mb-4">
            Join the community and start earning today
          </p>
          <a
            href="#download"
            className="inline-block px-5 py-2.5 sm:px-6 sm:py-3 bg-linear-to-r from-teal-500 to-primary text-white rounded-xl font-semibold text-sm sm:text-base shadow-lg shadow-teal-500/25"
          >
            Get Started
          </a>
        </div>
      </div>

      <style jsx>{`
        .custom-scrollbar::-webkit-scrollbar {
          width: 6px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
          background: rgba(39, 39, 42, 0.5);
          border-radius: 10px;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
          background: linear-gradient(to bottom, #2dd4bf, #8b5cf6);
          border-radius: 10px;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover {
          background: linear-gradient(to bottom, #14b8a6, #7c3aed);
        }
      `}</style>
    </section>
  );
}
