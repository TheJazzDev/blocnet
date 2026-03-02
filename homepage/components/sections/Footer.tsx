'use client';

import Link from 'next/link';
import Image from 'next/image';

export function Footer() {
  return (
    <footer className="py-8 sm:py-10 md:py-12 px-4 sm:px-6 lg:px-8 bg-[#09090b] border-t border-border">
      <div className="max-w-7xl mx-auto">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 sm:gap-8 mb-8 sm:mb-10">
          {/* Brand */}
          <div className="md:col-span-1">
            <Link href="/" className="inline-block mb-3 sm:mb-4">
              <Image
                src="/logo.png"
                alt="Blocnet"
                width={120}
                height={30}
                className="h-6 sm:h-7 md:h-8 w-auto"
              />
            </Link>
            <p className="text-xs sm:text-sm text-muted mb-3 sm:mb-4">
              AI-powered crypto intelligence hub. Track projects, earn rewards,
              and connect with the community.
            </p>
            <div className="flex gap-2 sm:gap-3">
              <a
                href="https://x.com/blocnet_app"
                target="_blank"
                rel="noopener noreferrer"
                className="w-8 h-8 sm:w-9 sm:h-9 flex items-center justify-center bg-surface-2 border border-border rounded-lg text-sm sm:text-base transition-colors hover:border-teal-500/30"
                aria-label="Follow us on X (Twitter)"
              >
                𝕏
              </a>
              <a
                href="https://t.me/blocnet_app"
                target="_blank"
                rel="noopener noreferrer"
                className="w-8 h-8 sm:w-9 sm:h-9 flex items-center justify-center bg-surface-2 border border-border rounded-lg text-sm sm:text-base transition-colors hover:border-teal-500/30"
                aria-label="Join our Telegram"
              >
                <svg className="w-4 h-4 sm:w-5 sm:h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 0C5.373 0 0 5.373 0 12s5.373 12 12 12 12-5.373 12-12S18.627 0 12 0zm5.562 8.161c-.18 1.897-.962 6.502-1.359 8.627-.168.9-.5 1.201-.82 1.23-.697.064-1.226-.461-1.901-.903-1.056-.693-1.653-1.124-2.678-1.8-1.185-.781-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.248-.024c-.106.024-1.793 1.139-5.062 3.345-.479.329-.913.489-1.302.481-.428-.008-1.252-.241-1.865-.44-.752-.244-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.831-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635.099-.002.321.023.465.141.121.099.155.232.171.326.016.094.036.308.02.475z"/>
                </svg>
              </a>
              <a
                href="https://instagram.com/blocnet_app"
                target="_blank"
                rel="noopener noreferrer"
                className="w-8 h-8 sm:w-9 sm:h-9 flex items-center justify-center bg-surface-2 border border-border rounded-lg text-sm sm:text-base transition-colors hover:border-teal-500/30"
                aria-label="Follow us on Instagram"
              >
                <svg className="w-4 h-4 sm:w-5 sm:h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
                </svg>
              </a>
              <a
                href="https://tiktok.com/@blocnet_app"
                target="_blank"
                rel="noopener noreferrer"
                className="w-8 h-8 sm:w-9 sm:h-9 flex items-center justify-center bg-surface-2 border border-border rounded-lg text-sm sm:text-base transition-colors hover:border-teal-500/30"
                aria-label="Follow us on TikTok"
              >
                <svg className="w-4 h-4 sm:w-5 sm:h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M19.59 6.69a4.83 4.83 0 0 1-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 0 1-5.2 1.74 2.89 2.89 0 0 1 2.31-4.64 2.93 2.93 0 0 1 .88.13V9.4a6.84 6.84 0 0 0-1-.05A6.33 6.33 0 0 0 5 20.1a6.34 6.34 0 0 0 10.86-4.43v-7a8.16 8.16 0 0 0 4.77 1.52v-3.4a4.85 4.85 0 0 1-1-.1z"/>
                </svg>
              </a>
            </div>
          </div>

          {/* Product */}
          <div>
            <h4 className="text-sm sm:text-base font-semibold text-foreground mb-3 sm:mb-4">
              Product
            </h4>
            <ul className="space-y-2 sm:space-y-3">
              <li>
                <Link href="/#features" className="text-xs sm:text-sm text-muted transition-colors hover:text-foreground">
                  Features
                </Link>
              </li>
              <li>
                <Link href="/roadmap" className="text-xs sm:text-sm text-muted transition-colors hover:text-foreground">
                  Roadmap
                </Link>
              </li>
              <li>
                <Link href="/#mining" className="text-xs sm:text-sm text-muted transition-colors hover:text-foreground">
                  Mining
                </Link>
              </li>
              <li>
                <Link href="/#wallet" className="text-xs sm:text-sm text-muted transition-colors hover:text-foreground">
                  Wallet
                </Link>
              </li>
              <li>
                <Link href="/#community" className="text-xs sm:text-sm text-muted transition-colors hover:text-foreground">
                  Community
                </Link>
              </li>
            </ul>
          </div>

          {/* Community */}
          <div>
            <h4 className="text-sm sm:text-base font-semibold text-foreground mb-3 sm:mb-4">
              Community
            </h4>
            <ul className="space-y-2 sm:space-y-3">
              <li>
                <a href="https://x.com/blocnet_app" target="_blank" rel="noopener noreferrer" className="text-xs sm:text-sm text-muted transition-colors hover:text-foreground">
                  X (Twitter)
                </a>
              </li>
              <li>
                <a href="https://t.me/blocnet_app" target="_blank" rel="noopener noreferrer" className="text-xs sm:text-sm text-muted transition-colors hover:text-foreground">
                  Telegram
                </a>
              </li>
              <li>
                <a href="https://instagram.com/blocnet_app" target="_blank" rel="noopener noreferrer" className="text-xs sm:text-sm text-muted transition-colors hover:text-foreground">
                  Instagram
                </a>
              </li>
              <li>
                <a href="https://tiktok.com/@blocnet_app" target="_blank" rel="noopener noreferrer" className="text-xs sm:text-sm text-muted transition-colors hover:text-foreground">
                  TikTok
                </a>
              </li>
              <li>
                <Link href="/#download" className="text-xs sm:text-sm text-muted transition-colors hover:text-foreground">
                  Download App
                </Link>
              </li>
            </ul>
          </div>

          {/* Support */}
          <div>
            <h4 className="text-sm sm:text-base font-semibold text-foreground mb-3 sm:mb-4">
              Support
            </h4>
            <ul className="space-y-2 sm:space-y-3">
              <li>
                <a href="https://blocnet.app" target="_blank" rel="noopener noreferrer" className="text-xs sm:text-sm text-muted transition-colors hover:text-foreground">
                  Help Center
                </a>
              </li>
              <li>
                <Link href="/contact" className="text-xs sm:text-sm text-muted transition-colors hover:text-foreground">
                  Contact Us
                </Link>
              </li>
              <li>
                <Link href="/privacy" className="text-xs sm:text-sm text-muted transition-colors hover:text-foreground">
                  Privacy Policy
                </Link>
              </li>
              <li>
                <Link href="/terms" className="text-xs sm:text-sm text-muted transition-colors hover:text-foreground">
                  Terms of Service
                </Link>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="pt-6 sm:pt-8 border-t border-border flex flex-col sm:flex-row justify-between items-center gap-3 sm:gap-4">
          <p className="text-xs sm:text-sm text-muted text-center sm:text-left">
            © {new Date().getFullYear()} Blocnet. All rights reserved.
          </p>
          <div className="flex gap-4 sm:gap-6 text-xs sm:text-sm text-muted">
            <Link href="/privacy" className="transition-colors hover:text-foreground">
              Privacy Policy
            </Link>
            <Link href="/terms" className="transition-colors hover:text-foreground">
              Terms of Service
            </Link>
          </div>
        </div>
      </div>
    </footer>
  );
}
