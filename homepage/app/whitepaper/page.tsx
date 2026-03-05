import type { Metadata } from 'next';
import { Navbar } from '@/components/ui/Navbar';
import { Footer } from '@/components/sections/Footer';

export const metadata: Metadata = {
  title: 'Blocnet Whitepaper',
  description:
    'Public overview of Blocnet product, BNB Chain token launch plan, liquidity strategy, and ecosystem impact.',
};

const milestones = [
  'Mainnet transaction reliability hardening',
  'BNT token launch and initial liquidity provisioning',
  'Partner integration APIs and docs',
  'Intelligence engine quality upgrades',
  'Ecosystem rollout with partner onboarding',
];

export default function WhitepaperPage() {
  return (
    <div className="min-h-screen bg-[#09090b] text-foreground">
      <Navbar />
      <main className="pt-20 sm:pt-24 md:pt-28 pb-16 sm:pb-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-4xl mx-auto space-y-8 sm:space-y-10">
          <header>
            <p className="text-xs sm:text-sm uppercase tracking-wide text-teal-400 mb-2">
              Public Technical Brief
            </p>
            <h1 className="text-3xl sm:text-4xl md:text-5xl font-bold mb-4">
              Blocnet Whitepaper
            </h1>
            <p className="text-sm sm:text-base text-muted">
              Blocnet is building the execution layer between Web3 information
              and on-chain action on BNB Chain.
            </p>
          </header>

          <section className="p-5 sm:p-6 rounded-xl border border-border bg-surface-2/40">
            <h2 className="text-xl sm:text-2xl font-semibold mb-3">
              Problem
            </h2>
            <p className="text-sm sm:text-base text-muted">
              Users miss high-value actions because project updates are
              fragmented across social channels. Critical actions like claims,
              launches, governance, and participation windows are often missed.
            </p>
          </section>

          <section className="p-5 sm:p-6 rounded-xl border border-border bg-surface-2/40">
            <h2 className="text-xl sm:text-2xl font-semibold mb-3">
              Solution
            </h2>
            <p className="text-sm sm:text-base text-muted">
              Blocnet structures updates into ranked, actionable intelligence
              and connects them to wallet-ready execution flows. The platform
              combines a deterministic ranking engine, optional AI enrichment,
              and a ledger-backed BNB Chain transaction engine.
            </p>
          </section>

          <section className="p-5 sm:p-6 rounded-xl border border-border bg-surface-2/40">
            <h2 className="text-xl sm:text-2xl font-semibold mb-3">
              Product Overview
            </h2>
            <p className="text-sm sm:text-base text-muted">
              Blocnet provides a consumer experience for discovering high-signal
              project updates, a participation layer for acting on those
              updates, and an operations layer for running campaigns and
              ecosystem programs reliably on BNB Chain.
            </p>
          </section>

          <section className="p-5 sm:p-6 rounded-xl border border-border bg-surface-2/40">
            <h2 className="text-xl sm:text-2xl font-semibold mb-3">
              Token and Liquidity Plan
            </h2>
            <p className="text-sm sm:text-base text-muted">
              Blocnet will execute BNT public launch and initial liquidity
              provisioning on BNB Chain DEX rails as a core part of growth and
              user participation strategy.
            </p>
          </section>

          <section className="p-5 sm:p-6 rounded-xl border border-border bg-surface-2/40">
            <h2 className="text-xl sm:text-2xl font-semibold mb-3">
              Grant Execution Milestones
            </h2>
            <ul className="space-y-2 text-sm sm:text-base text-muted list-disc pl-5">
              {milestones.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          </section>

          <section className="p-5 sm:p-6 rounded-xl border border-border bg-surface-2/40">
            <h2 className="text-xl sm:text-2xl font-semibold mb-3">
              Team
            </h2>
            <p className="text-sm sm:text-base text-muted">
              Blocnet is currently built by a solo founder with end-to-end
              ownership and execution.
            </p>
          </section>

          <section className="p-5 sm:p-6 rounded-xl border border-border bg-surface-2/40">
            <h2 className="text-xl sm:text-2xl font-semibold mb-3">
              Documentation Access
            </h2>
            <p className="text-sm sm:text-base text-muted">
              Source code remains private for security and operational reasons.
              Additional architecture documentation, security notes, and live
              product walkthroughs are available under NDA for partners and
              grant reviewers.
            </p>
          </section>
        </div>
      </main>
      <Footer />
    </div>
  );
}
