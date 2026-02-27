import { Navbar } from '@/components/ui/Navbar';
import { Hero } from '@/components/sections/Hero';
import { EdgeEngine } from '@/components/sections/EdgeEngine';
import { FeaturesOverview } from '@/components/sections/FeaturesOverview';
import { Tokenomics } from '@/components/sections/Tokenomics';
import { Roadmap } from '@/components/sections/Roadmap';
import { AppDownload } from '@/components/sections/AppDownload';
import { CTA } from '@/components/sections/CTA';
import { Footer } from '@/components/sections/Footer';

export default function DemoPage() {
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
