'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';

export function Navbar() {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <nav
      className={`fixed top-0 left-0 right-0 z-50 ${
        scrolled
          ? 'bg-[#09090b]/95 backdrop-blur-md border-b border-border/50'
          : 'bg-[#09090b]/80 backdrop-blur-sm'
      }`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-14 sm:h-16 md:h-20">
          {/* Logo */}
          <Link href="/" className="flex items-center shrink-0">
            <Image
              src="/logo.png"
              alt="Blocnet"
              width={120}
              height={30}
              className="h-6 sm:h-7 md:h-8 w-auto"
            />
          </Link>

          {/* Nav Links - Hidden on Mobile */}
          <div className="hidden md:flex items-center gap-6 lg:gap-8">
            {['Features', 'Mining', 'Wallet', 'Community'].map((item) => (
              <a
                key={item}
                href={`#${item.toLowerCase()}`}
                className="text-sm lg:text-base text-muted"
              >
                {item}
              </a>
            ))}
          </div>

          {/* CTA Button */}
          <div className="flex items-center gap-2 sm:gap-3">
            <a
              href="https://x.com/blocnet"
              target="_blank"
              rel="noopener noreferrer"
              className="hidden sm:inline-flex items-center gap-1.5 sm:gap-2 px-3 py-1.5 sm:px-4 sm:py-2 bg-surface-2 border border-border rounded-lg sm:rounded-xl text-xs sm:text-sm text-foreground"
            >
              <span>Follow on</span>
              <span className="font-bold">𝕏</span>
            </a>
            <a
              href="#"
              className="px-3 py-1.5 sm:px-4 sm:py-2 md:px-5 md:py-2.5 bg-teal-500 text-white rounded-lg sm:rounded-xl font-medium text-xs sm:text-sm md:text-base"
            >
              Download App
            </a>
          </div>
        </div>
      </div>
    </nav>
  );
}
