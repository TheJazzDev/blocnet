import { Navbar } from '@/components/ui/Navbar';
import { HeroClean } from '@/components/sections/HeroClean';
import { EdgeEngineClean } from '@/components/sections/EdgeEngineClean';
import { FeaturesOverview } from '@/components/sections/FeaturesOverview';
import { TokenomicsClean } from '@/components/sections/TokenomicsClean';
import { RoadmapClean } from '@/components/sections/RoadmapClean';
import { AppDownloadClean } from '@/components/sections/AppDownloadClean';
import { CTA } from '@/components/sections/CTA';
import { Footer } from '@/components/sections/Footer';

export default function DemoPage() {
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
