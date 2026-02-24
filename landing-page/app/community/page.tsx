import type { Metadata } from 'next';
import { Navbar } from '@/components/ui/Navbar';
import { Footer } from '@/components/sections/Footer';
import { CommunityContent } from '@/components/sections/CommunityContent';

export const metadata: Metadata = {
  title: 'Community — Blocnet',
  description:
    'Join the Blocnet community of crypto enthusiasts, hunters, and contributors. Connect with like-minded individuals, share insights, and grow together.',
  keywords: [
    'blocnet community',
    'crypto community',
    'Web3 community',
    'hunters network',
    'crypto discussions',
    'blockchain community',
  ],
  openGraph: {
    title: 'Community — Blocnet',
    description:
      'Join thousands of crypto enthusiasts in the Blocnet community. Share insights, discover opportunities, and connect with hunters worldwide.',
    type: 'website',
  },
};

export default function CommunityPage() {
  return (
    <div className="min-h-screen bg-[#09090b] text-foreground">
      <Navbar />
      <CommunityContent />
      <Footer />
    </div>
  );
}
