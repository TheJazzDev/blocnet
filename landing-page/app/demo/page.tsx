import { Navbar } from '@/components/ui/Navbar';
import { HeroEnhanced } from '@/components/sections/HeroEnhanced';
import { EdgeEngineEnhanced } from '@/components/sections/EdgeEngineEnhanced';
import { RoadmapWeb3 } from '@/components/sections/RoadmapWeb3';
import { Tokenomics } from '@/components/sections/Tokenomics';
import { ScrollReveal } from '@/components/animations/ScrollReveal';
import { FeaturesOverview } from '@/components/sections/FeaturesOverview';
import { AppDownloadEnhanced } from '@/components/sections/AppDownloadEnhanced';
import { LiveActivity } from '@/components/sections/LiveActivity';
import { CTA } from '@/components/sections/CTA';
import { Footer } from '@/components/sections/Footer';

export default function DemoPage() {
  return (
    <div className="min-h-screen bg-[#09090b] text-foreground">
      <Navbar />
      <HeroEnhanced />
      <EdgeEngineEnhanced />

      <ScrollReveal animation="fade-scale">
        <FeaturesOverview />
      </ScrollReveal>

      <Tokenomics />
      <RoadmapWeb3 />

      <ScrollReveal animation="fade-scale">
        <LiveActivity />
      </ScrollReveal>

      <AppDownloadEnhanced />

      <ScrollReveal animation="fade-scale">
        <CTA />
      </ScrollReveal>

      <Footer />
    </div>
  );
}
