import type { Metadata } from 'next';
import { Navbar } from '@/components/ui/Navbar';
import { Footer } from '@/components/sections/Footer';
import { MiningContent } from '@/components/sections/MiningContent';

export const metadata: Metadata = {
  title: 'Mining — Blocnet',
  description:
    'Earn BNT tokens through Blocnet 24-hour cycling mining system. Build your referral network, compete on leaderboards, and maximize your rewards.',
  keywords: [
    'blocnet mining',
    'BNT mining',
    'crypto mining',
    'referral mining',
    'earn crypto',
    'mining rewards',
    'cycling mining',
  ],
  openGraph: {
    title: 'Mining — Blocnet',
    description:
      'Earn BNT tokens every hour through our unique cycling mining system. Build referrals, compete globally, and claim rewards 24/7.',
    type: 'website',
  },
};

export default function MiningPage() {
  return (
    <div className="min-h-screen bg-[#09090b] text-foreground">
      <Navbar />
      <MiningContent />
      <Footer />
    </div>
  );
}
