'use client';

import { useEffect, useRef } from 'react';
import Link from 'next/link';
import gsap from 'gsap';
import { useGSAP } from '@gsap/react';

export function HeroEnhanced() {
  const containerRef = useRef<HTMLDivElement>(null);
  const particlesRef = useRef<HTMLDivElement>(null);
  const statsRef = useRef<HTMLDivElement>(null);

  // Particle animation
  useGSAP(() => {
    if (!particlesRef.current) return;

    // Create floating particles
    const particleCount = 30;
    const particles: HTMLDivElement[] = [];

    for (let i = 0; i < particleCount; i++) {
      const particle = document.createElement('div');
      particle.className = 'absolute rounded-full';

      const size = Math.random() * 4 + 2;
      particle.style.width = `${size}px`;
      particle.style.height = `${size}px`;
      particle.style.left = `${Math.random() * 100}%`;
      particle.style.top = `${Math.random() * 100}%`;

      const opacity = Math.random() * 0.5 + 0.2;
      particle.style.backgroundColor = Math.random() > 0.5
        ? `rgba(45, 212, 191, ${opacity})`
        : `rgba(139, 92, 246, ${opacity})`;

      particlesRef.current.appendChild(particle);
      particles.push(particle);

      // Animate each particle
      gsap.to(particle, {
        y: `random(-100, 100)`,
        x: `random(-100, 100)`,
        duration: `random(10, 20)`,
        repeat: -1,
        yoyo: true,
        ease: 'sine.inOut',
      });

      gsap.to(particle, {
        opacity: `random(0.2, 0.8)`,
        duration: `random(2, 4)`,
        repeat: -1,
        yoyo: true,
      });
    }

    return () => {
      particles.forEach(p => p.remove());
    };
  }, { scope: particlesRef });

  // Hero animation timeline
  useGSAP(() => {
    if (!containerRef.current) return;

    const tl = gsap.timeline({ defaults: { ease: 'power3.out' } });

    tl.from('.hero-badge', {
      opacity: 0,
      scale: 0.8,
      y: 20,
      duration: 0.6,
      stagger: 0.1,
    })
      .from('.hero-title', {
        opacity: 0,
        y: 50,
        duration: 0.8,
      }, '-=0.3')
      .from('.hero-subtitle', {
        opacity: 0,
        y: 30,
        duration: 0.6,
      }, '-=0.4')
      .from('.hero-btn', {
        opacity: 0,
        y: 20,
        duration: 0.5,
        stagger: 0.15,
      }, '-=0.3')
      .from('.hero-stat', {
        opacity: 0,
        y: 30,
        scale: 0.9,
        duration: 0.5,
        stagger: 0.1,
      }, '-=0.4');
  }, { scope: containerRef });

  // Animated counter for stats
  useGSAP(() => {
    if (!statsRef.current) return;

    const stats = [
      { id: 'users', target: 10000, suffix: '+' },
      { id: 'projects', target: 500, suffix: '+' },
      { id: 'updates', target: 1000, suffix: '+' },
      { id: 'posts', target: 5000, suffix: '+' },
    ];

    stats.forEach(stat => {
      const element = document.getElementById(`stat-${stat.id}`);
      if (!element) return;

      const obj = { value: 0 };
      gsap.to(obj, {
        value: stat.target,
        duration: 2,
        delay: 0.5,
        ease: 'power2.out',
        onUpdate: () => {
          if (stat.target >= 1000) {
            element.textContent = `${(obj.value / 1000).toFixed(1)}K${stat.suffix}`;
          } else {
            element.textContent = `${Math.round(obj.value)}${stat.suffix}`;
          }
        },
      });
    });
  }, { scope: statsRef });

  // Mouse move parallax
  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (!containerRef.current) return;

      const { clientX, clientY } = e;
      const { innerWidth, innerHeight } = window;

      const xPos = (clientX - innerWidth / 2) / innerWidth;
      const yPos = (clientY - innerHeight / 2) / innerHeight;

      gsap.to('.parallax-orb', {
        x: xPos * 50,
        y: yPos * 50,
        duration: 2,
        ease: 'power2.out',
      });
    };

    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  return (
    <section
      ref={containerRef}
      className="relative min-h-screen flex items-center justify-center overflow-hidden px-4 sm:px-6 lg:px-8"
    >
      {/* Animated Background */}
      <div className="absolute inset-0 bg-[#09090b]">
        {/* Grid */}
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#27272a_1px,transparent_1px),linear-gradient(to_bottom,#27272a_1px,transparent_1px)] bg-[size:4rem_4rem] [mask-image:radial-gradient(ellipse_80%_50%_at_50%_0%,#000_70%,transparent_110%)]" />

        {/* Parallax Orbs */}
        <div className="parallax-orb absolute top-1/4 left-1/4 w-64 sm:w-96 h-64 sm:h-96 bg-teal-500/20 rounded-full blur-3xl" />
        <div className="parallax-orb absolute bottom-1/4 right-1/4 w-64 sm:w-96 h-64 sm:h-96 bg-primary/20 rounded-full blur-3xl" />

        {/* Floating Particles */}
        <div ref={particlesRef} className="absolute inset-0" />
      </div>

      {/* Content */}
      <div className="relative z-10 max-w-5xl mx-auto text-center">
        {/* Badges */}
        <div className="flex flex-wrap gap-2 sm:gap-3 justify-center mb-4 sm:mb-6">
          <span className="hero-badge text-xs sm:text-sm px-3 py-1.5 sm:px-4 sm:py-2 bg-teal-500/10 border border-teal-500/20 rounded-full text-teal-400 backdrop-blur-sm">
            ✨ AI-Powered Intelligence
          </span>
          <span className="hero-badge text-xs sm:text-sm px-3 py-1.5 sm:px-4 sm:py-2 bg-primary/10 border border-primary/20 rounded-full text-primary backdrop-blur-sm">
            🌐 Crypto Update Network
          </span>
        </div>

        {/* Title */}
        <h1 className="hero-title text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-bold text-foreground mb-4 sm:mb-6 md:mb-8 leading-tight">
          Your <span className="text-transparent bg-clip-text bg-linear-to-r from-teal-400 to-primary">Crypto Hub</span>
          <br />
          All in One Place
        </h1>

        {/* Subtitle */}
        <p className="hero-subtitle text-base sm:text-lg md:text-xl text-muted max-w-3xl mx-auto mb-8 sm:mb-10 px-4 leading-relaxed">
          AI-powered crypto intelligence meets community-driven updates. Track
          projects, earn through mining, manage your wallet, and get smart
          recommendations from Blocnet Edge Engine (BEE).
        </p>

        {/* CTA Buttons */}
        <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center items-center mb-12 sm:mb-16">
          <Link
            href="#download"
            className="hero-btn group relative w-full sm:w-auto px-6 py-3 sm:px-8 sm:py-4 bg-linear-to-r from-teal-500 to-primary text-white rounded-xl font-semibold text-sm sm:text-base shadow-lg shadow-teal-500/25 overflow-hidden"
          >
            <span className="relative z-10">Download App</span>
            <div className="absolute inset-0 bg-linear-to-r from-teal-400 to-purple-500 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
          </Link>
          <Link
            href="/about"
            className="hero-btn w-full sm:w-auto px-6 py-3 sm:px-8 sm:py-4 bg-surface-2/50 backdrop-blur-sm border border-border text-foreground rounded-xl font-semibold text-sm sm:text-base hover:border-teal-500/30 transition-all duration-300"
          >
            Learn More
          </Link>
        </div>

        {/* Animated Stats */}
        <div ref={statsRef} className="grid grid-cols-2 md:grid-cols-4 gap-4 sm:gap-5 md:gap-6">
          {[
            { id: 'users', label: 'Active Users' },
            { id: 'projects', label: 'Projects Tracked' },
            { id: 'updates', label: 'Updates Daily' },
            { id: 'posts', label: 'Community Posts' },
          ].map((stat) => (
            <div
              key={stat.id}
              className="hero-stat group p-5 sm:p-6 bg-surface-2/50 backdrop-blur-sm border border-border rounded-xl hover:border-teal-500/30 transition-all duration-300 hover:scale-105"
            >
              <div
                id={`stat-${stat.id}`}
                className="text-2xl sm:text-3xl md:text-4xl font-bold text-transparent bg-clip-text bg-linear-to-r from-teal-400 to-primary"
              >
                0
              </div>
              <div className="text-sm sm:text-base text-muted mt-2">
                {stat.label}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
