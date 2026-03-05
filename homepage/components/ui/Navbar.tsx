'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname } from 'next/navigation';

export function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const pathname = usePathname();

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const isHomePage = pathname === '/';

  const navLinks = [
    { label: 'Home', href: '/', type: 'page' },
    { label: 'About', href: '/about', type: 'page' },
    { label: 'Whitepaper', href: '/whitepaper', type: 'page' },
    { label: 'Mining', href: '/mining', type: 'page' },
    { label: 'Community', href: '/community', type: 'page' },
    { label: 'Roadmap', href: '/roadmap', type: 'page' },
    { label: 'Contact', href: '/contact', type: 'page' },
    { label: 'Privacy', href: '/privacy', type: 'page' },
    { label: 'Terms', href: '/terms', type: 'page' },
  ];

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
              width={512}
              height={512}
              priority
              className="h-6 sm:h-7 md:h-8 w-auto"
            />
          </Link>

          {/* Nav Links - Hidden on Mobile */}
          <div className="hidden md:flex items-center gap-4 lg:gap-6">
            {navLinks.map((link) =>
              link.type === 'page' ? (
                <Link
                  key={link.label}
                  href={link.href}
                  className={`text-sm lg:text-base transition-colors ${
                    pathname === link.href
                      ? 'text-teal-400 font-semibold'
                      : 'text-muted hover:text-foreground'
                  }`}
                >
                  {link.label}
                </Link>
              ) : (
                <a
                  key={link.label}
                  href={link.href}
                  className="text-sm lg:text-base text-muted"
                >
                  {link.label}
                </a>
              )
            )}
          </div>

          {/* CTA Buttons */}
          <div className="flex items-center gap-2 sm:gap-3">
            <a
              href="https://x.com/blocnet_app"
              target="_blank"
              rel="noopener noreferrer"
              className="hidden sm:inline-flex items-center gap-1.5 sm:gap-2 px-3 py-1.5 sm:px-4 sm:py-2 bg-surface-2 border border-border rounded-lg sm:rounded-xl text-xs sm:text-sm text-foreground transition-colors hover:border-teal-500/30"
            >
              <span>Follow on</span>
              <span className="font-bold">𝕏</span>
            </a>
            <a
              href={isHomePage ? '#download' : '/#download'}
              className="px-3 py-1.5 sm:px-4 sm:py-2 md:px-5 md:py-2.5 bg-teal-500 text-white rounded-lg sm:rounded-xl font-medium text-xs sm:text-sm md:text-base transition-opacity hover:opacity-90"
            >
              Download App
            </a>

            {/* Mobile Menu Button */}
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="md:hidden p-2 text-muted"
              aria-label="Toggle menu"
            >
              <svg
                className="w-6 h-6"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                {mobileMenuOpen ? (
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M6 18L18 6M6 6l12 12"
                  />
                ) : (
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M4 6h16M4 12h16M4 18h16"
                  />
                )}
              </svg>
            </button>
          </div>
        </div>

        {/* Mobile Menu */}
        {mobileMenuOpen && (
          <div className="md:hidden border-t border-border py-4">
            <div className="flex flex-col gap-3">
              {navLinks.map((link) =>
                link.type === 'page' ? (
                  <Link
                    key={link.label}
                    href={link.href}
                    onClick={() => setMobileMenuOpen(false)}
                    className={`px-4 py-2 text-sm ${
                      pathname === link.href
                        ? 'text-teal-400 font-semibold bg-teal-500/10 rounded-lg'
                        : 'text-muted'
                    }`}
                  >
                    {link.label}
                  </Link>
                ) : (
                  <a
                    key={link.label}
                    href={link.href}
                    onClick={() => setMobileMenuOpen(false)}
                    className="px-4 py-2 text-sm text-muted"
                  >
                    {link.label}
                  </a>
                )
              )}
            </div>
          </div>
        )}
      </div>
    </nav>
  );
}
