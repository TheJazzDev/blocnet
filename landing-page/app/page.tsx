import { Navbar } from '@/components/ui/Navbar';
import { Hero } from '@/components/sections/Hero';
import { EdgeEngine } from '@/components/sections/EdgeEngine';
import { FeaturesOverview } from '@/components/sections/FeaturesOverview';
import { RoadmapPreview } from '@/components/sections/RoadmapPreview';
import { AppDownload } from '@/components/sections/AppDownload';
import { CTA } from '@/components/sections/CTA';
import { Footer } from '@/components/sections/Footer';

export default function Home() {
  return (
    <div className="min-h-screen bg-[#09090b] text-foreground">
      <Navbar />
      <Hero />
      <EdgeEngine />
      <FeaturesOverview />
      <RoadmapPreview />
      <AppDownload />
      <CTA />
      <Footer />
    </div>
  );
}
