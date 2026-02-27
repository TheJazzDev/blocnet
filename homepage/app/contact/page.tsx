import type { Metadata } from 'next';
import Link from 'next/link';
import { Navbar } from '@/components/ui/Navbar';
import { Footer } from '@/components/sections/Footer';

export const metadata: Metadata = {
  title: 'Contact Us — Blocnet',
  description:
    'Get in touch with Blocnet across X, Telegram, Instagram, TikTok, and email.',
};

const channels = [
  {
    label: 'X (Twitter)',
    handle: '@blocnet_app',
    href: 'https://x.com/blocnet_app',
  },
  {
    label: 'Telegram',
    handle: '@blocnet_app',
    href: 'https://t.me/blocnet_app',
  },
  {
    label: 'Instagram',
    handle: '@blocnet_app',
    href: 'https://instagram.com/blocnet_app',
  },
  {
    label: 'TikTok',
    handle: '@blocnet_app',
    href: 'https://tiktok.com/@blocnet_app',
  },
  {
    label: 'Email',
    handle: 'blocnetapp@gmail.com',
    href: 'mailto:blocnetapp@gmail.com',
  },
];

export default function ContactPage() {
  return (
    <div className="min-h-screen bg-[#09090b] text-foreground">
      <Navbar />
      <main className="pt-20 sm:pt-24 md:pt-28 pb-16 sm:pb-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-4xl mx-auto">
          <header className="mb-10 sm:mb-12">
            <h1 className="text-3xl sm:text-4xl md:text-5xl font-bold mb-4">
              Contact Us
            </h1>
            <p className="text-sm sm:text-base text-muted">
              Reach the Blocnet team through any of our official channels.
            </p>
          </header>

          <section className="grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-5">
            {channels.map((channel) => (
              <a
                key={channel.label}
                href={channel.href}
                target={channel.href.startsWith('http') ? '_blank' : undefined}
                rel={
                  channel.href.startsWith('http')
                    ? 'noopener noreferrer'
                    : undefined
                }
                className="p-5 sm:p-6 rounded-xl border border-border bg-surface-2/50 transition-colors hover:border-teal-500/40"
              >
                <p className="text-base sm:text-lg font-semibold">
                  {channel.label}
                </p>
                <p className="text-sm sm:text-base text-teal-400 mt-1">
                  {channel.handle}
                </p>
              </a>
            ))}
          </section>

          <section className="mt-8 p-5 sm:p-6 rounded-xl border border-border bg-surface-2/40">
            <p className="text-sm sm:text-base text-muted">
              Need legal or privacy help? Visit{' '}
              <Link href="/terms" className="text-teal-400 hover:opacity-90">
                Terms of Service
              </Link>{' '}
              and{' '}
              <Link href="/privacy" className="text-teal-400 hover:opacity-90">
                Privacy Policy
              </Link>
              .
            </p>
          </section>
        </div>
      </main>
      <Footer />
    </div>
  );
}
