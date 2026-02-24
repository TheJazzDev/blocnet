import type { Metadata } from 'next';
import { Navbar } from '@/components/ui/Navbar';
import { Footer } from '@/components/sections/Footer';
import { RoadmapContent } from '@/components/sections/RoadmapContent';

export const metadata: Metadata = {
  title: 'Roadmap — Blocnet',
  description:
    'Explore Blocnet product roadmap from foundation to global scale. See our progress on Blocnet Edge Engine (BEE), token economy, wallet features, and future expansion plans.',
  keywords: [
    'blocnet roadmap',
    'crypto platform roadmap',
    'Blocnet Edge Engine',
    'BEE development',
    'BNT token launch',
    'Web3 roadmap',
    'crypto app development',
  ],
  openGraph: {
    title: 'Roadmap — Blocnet',
    description:
      'Track our journey from a simple content hub to the most intelligent crypto platform. See what is completed, in progress, and coming next.',
    type: 'website',
  },
};

export default function RoadmapPage() {
  return (
    <div className="min-h-screen bg-[#09090b] text-foreground">
      <Navbar />
      <RoadmapContent />
      <Footer />
    </div>
  );
}
