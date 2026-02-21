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
              Your all-in-one crypto hub for tracking projects, earning rewards,
              and connecting with the community.
            </p>
            <div className="flex gap-3 sm:gap-4">
              <a
                href="https://x.com/blocnet"
                target="_blank"
                rel="noopener noreferrer"
                className="w-8 h-8 sm:w-9 sm:h-9 flex items-center justify-center bg-surface-2 border border-border rounded-lg text-sm sm:text-base"
              >
                𝕏
              </a>
              <a
                href="#"
                className="w-8 h-8 sm:w-9 sm:h-9 flex items-center justify-center bg-surface-2 border border-border rounded-lg text-sm sm:text-base"
              >
                📱
              </a>
              <a
                href="#"
                className="w-8 h-8 sm:w-9 sm:h-9 flex items-center justify-center bg-surface-2 border border-border rounded-lg text-sm sm:text-base"
              >
                💬
              </a>
            </div>
          </div>

          {/* Product */}
          <div>
            <h4 className="text-sm sm:text-base font-semibold text-foreground mb-3 sm:mb-4">
              Product
            </h4>
            <ul className="space-y-2 sm:space-y-3">
              {['Features', 'Mining', 'Wallet', 'Community', 'Pricing'].map(
                (item) => (
                  <li key={item}>
                    <a
                      href={`#${item.toLowerCase()}`}
                      className="text-xs sm:text-sm text-muted"
                    >
                      {item}
                    </a>
                  </li>
                )
              )}
            </ul>
          </div>

          {/* Resources */}
          <div>
            <h4 className="text-sm sm:text-base font-semibold text-foreground mb-3 sm:mb-4">
              Resources
            </h4>
            <ul className="space-y-2 sm:space-y-3">
              {['Documentation', 'API', 'Support', 'Blog', 'Changelog'].map(
                (item) => (
                  <li key={item}>
                    <a
                      href="#"
                      className="text-xs sm:text-sm text-muted"
                    >
                      {item}
                    </a>
                  </li>
                )
              )}
            </ul>
          </div>

          {/* Company */}
          <div>
            <h4 className="text-sm sm:text-base font-semibold text-foreground mb-3 sm:mb-4">
              Company
            </h4>
            <ul className="space-y-2 sm:space-y-3">
              {['About', 'Careers', 'Privacy', 'Terms', 'Contact'].map(
                (item) => (
                  <li key={item}>
                    <a
                      href="#"
                      className="text-xs sm:text-sm text-muted"
                    >
                      {item}
                    </a>
                  </li>
                )
              )}
            </ul>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="pt-6 sm:pt-8 border-t border-border flex flex-col sm:flex-row justify-between items-center gap-3 sm:gap-4">
          <p className="text-xs sm:text-sm text-muted text-center sm:text-left">
            © {new Date().getFullYear()} Blocnet. All rights reserved.
          </p>
          <div className="flex gap-4 sm:gap-6 text-xs sm:text-sm text-muted">
            <a href="#">
              Privacy Policy
            </a>
            <a href="#">
              Terms of Service
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}
