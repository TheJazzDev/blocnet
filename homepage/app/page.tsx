import type { Metadata } from 'next';
import { Navbar } from '@/components/ui/Navbar';
import { Hero } from '@/components/sections/Hero';
import { EdgeEngine } from '@/components/sections/EdgeEngine';
import { FeaturesOverview } from '@/components/sections/FeaturesOverview';
import { Tokenomics } from '@/components/sections/Tokenomics';
import { Roadmap } from '@/components/sections/Roadmap';
import { AppDownload } from '@/components/sections/AppDownload';
import { CTA } from '@/components/sections/CTA';
import { Footer } from '@/components/sections/Footer';

export const metadata: Metadata = {
  title: 'Blocnet — Your AI-Powered Crypto Hub',
  description:
    'AI-powered crypto intelligence meets community-driven updates. Track projects, earn through mining, manage your wallet, and get smart recommendations from Blocnet Edge Engine (BEE).',
  keywords: [
    'blocnet',
    'crypto intelligence',
    'BEE',
    'Blocnet Edge Engine',
    'crypto mining',
    'BNT token',
    'crypto updates',
    'Web3 platform',
    'blockchain intelligence',
    'crypto wallet',
  ],
  openGraph: {
    title: 'Blocnet — Your AI-Powered Crypto Hub',
    description:
      'Track projects, earn through mining, and get AI-powered insights with Blocnet Edge Engine (BEE). Join 10K+ users in the crypto intelligence revolution.',
    type: 'website',
  },
};

export default function Home() {
  return (
    <div className="min-h-screen bg-[#09090b] text-foreground">
      <Navbar />
      <Hero />
      <EdgeEngine />
      <FeaturesOverview />
      <Tokenomics />
      <Roadmap />
      <AppDownload />
      <CTA />
      <Footer />
    </div>
  );
}
