import { Navbar } from '@/components/ui/Navbar';
import { Hero } from '@/components/sections/Hero';
import { AppDownload } from '@/components/sections/AppDownload';
import { Features } from '@/components/sections/Features';
import { EdgeEngine } from '@/components/sections/EdgeEngine';
import { Mining } from '@/components/sections/Mining';
import { Wallet } from '@/components/sections/Wallet';
import { Hunter } from '@/components/sections/Hunter';
import { Community } from '@/components/sections/Community';
import { CTA } from '@/components/sections/CTA';
import { Footer } from '@/components/sections/Footer';

export default function Home() {
  return (
    <div className="min-h-screen bg-[#09090b] text-foreground">
      <Navbar />
      <Hero />
      <AppDownload />
      <Features />
      <EdgeEngine />
      <Mining />
      <Wallet />
      <Hunter />
      <Community />
      <CTA />
      <Footer />
    </div>
  );
}
