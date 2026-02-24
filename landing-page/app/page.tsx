import type { Metadata } from 'next';
import { Navbar } from '@/components/ui/Navbar';
import { HeroClean } from '@/components/sections/HeroClean';
import { EdgeEngineClean } from '@/components/sections/EdgeEngineClean';
import { FeaturesOverview } from '@/components/sections/FeaturesOverview';
import { TokenomicsClean } from '@/components/sections/TokenomicsClean';
import { RoadmapClean } from '@/components/sections/RoadmapClean';
import { AppDownloadClean } from '@/components/sections/AppDownloadClean';
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
      <HeroClean />
      <EdgeEngineClean />
      <FeaturesOverview />
      <TokenomicsClean />
      <RoadmapClean />
      <AppDownloadClean />
      <CTA />
      <Footer />
    </div>
  );
}
