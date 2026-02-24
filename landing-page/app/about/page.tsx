import type { Metadata } from 'next';
import { Navbar } from '@/components/ui/Navbar';
import { Footer } from '@/components/sections/Footer';
import { AboutContent } from '@/components/sections/AboutContent';

export const metadata: Metadata = {
  title: 'About — Blocnet',
  description:
    'Learn about Blocnet mission to revolutionize crypto intelligence with AI-powered insights, community-driven content, and the Blocnet Edge Engine (BEE).',
  keywords: [
    'about blocnet',
    'blocnet mission',
    'crypto intelligence platform',
    'Web3 innovation',
    'Blocnet Edge Engine',
    'BEE',
  ],
  openGraph: {
    title: 'About — Blocnet',
    description:
      'Discover how Blocnet is building the future of crypto intelligence with AI, community collaboration, and innovative tokenomics.',
    type: 'website',
  },
};

export default function AboutPage() {
  return (
    <div className="min-h-screen bg-[#09090b] text-foreground">
      <Navbar />
      <AboutContent />
      <Footer />
    </div>
  );
}
