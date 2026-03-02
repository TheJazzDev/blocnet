import type { Metadata } from 'next';
import { Navbar } from '@/components/ui/Navbar';
import { Footer } from '@/components/sections/Footer';

export const metadata: Metadata = {
  title: 'Terms and Conditions — Blocnet',
  description: 'Terms and Conditions for using the Blocnet platform, app, and services.',
};

export default function TermsPage() {
  return (
    <div className="min-h-screen bg-[#09090b] text-foreground">
      <Navbar />
      <main className="pt-20 sm:pt-24 md:pt-28 pb-16 sm:pb-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-4xl mx-auto">
        <div className="mb-10 sm:mb-12">
          <h1 className="text-3xl sm:text-4xl md:text-5xl font-bold text-foreground mb-4">
            Terms and Conditions
          </h1>
          <p className="text-sm sm:text-base text-muted">
            Last Updated: February 25, 2026
          </p>
        </div>

        <div className="space-y-8 sm:space-y-10 text-muted">
          {/* Introduction */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              1. Introduction
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p>
                Welcome to Blocnet (&quot;Platform&quot;, &quot;we&quot;, &quot;us&quot;, or &quot;our&quot;). By accessing or using the Blocnet platform, mobile application, website, or any associated services (collectively, the &quot;Services&quot;), you agree to be bound by these Terms and Conditions (&quot;Terms&quot;).
              </p>
              <p>
                Blocnet is a decentralized crypto intelligence platform that provides AI-powered recommendations, community-driven updates, mining rewards, and wallet services. These Terms govern your use of all features including but not limited to: the Blocnet Edge Engine (BEE), mining mechanisms, BNT token, wallet services, and community features.
              </p>
              <p>
                If you do not agree to these Terms, please do not use our Services.
              </p>
            </div>
          </section>

          {/* Eligibility */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              2. Eligibility
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p>
                To use Blocnet Services, you must:
              </p>
              <ul className="list-disc pl-5 sm:pl-6 space-y-2">
                <li>Be at least 18 years of age or the age of legal majority in your jurisdiction</li>
                <li>Have the legal capacity to enter into binding agreements</li>
                <li>Not be prohibited from using our Services under applicable laws</li>
                <li>Not be located in or a resident of any jurisdiction where crypto services are prohibited</li>
                <li>Comply with all local laws regarding online conduct and cryptocurrency transactions</li>
              </ul>
              <p className="mt-4">
                By using our Services, you represent and warrant that you meet all eligibility requirements.
              </p>
            </div>
          </section>

          {/* Account and Wallet */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              3. Account and Wallet Responsibilities
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p className="font-semibold text-foreground">
                3.1 Non-Custodial Wallet
              </p>
              <p>
                Blocnet provides a non-custodial wallet solution. You retain full control and ownership of your private keys and seed phrases. We do not have access to, store, or control your private keys.
              </p>

              <p className="font-semibold text-foreground mt-4">
                3.2 Your Responsibilities
              </p>
              <ul className="list-disc pl-5 sm:pl-6 space-y-2">
                <li>Safeguarding your private keys, seed phrases, and passwords</li>
                <li>Maintaining the confidentiality of your account credentials</li>
                <li>Being solely responsible for all activities under your account</li>
                <li>Immediately notifying us of any unauthorized access or security breach</li>
              </ul>

              <p className="font-semibold text-foreground mt-4">
                3.3 Loss of Access
              </p>
              <p>
                If you lose your private keys or seed phrase, we cannot recover your wallet or assets. You acknowledge that lost credentials result in permanent loss of access to your digital assets.
              </p>
            </div>
          </section>

          {/* BNT Token and Mining */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              4. BNT Token and Mining Mechanism
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p className="font-semibold text-foreground">
                4.1 Token Nature
              </p>
              <p>
                BNT is a utility token on the BNB Smart Chain blockchain designed for use within the Blocnet ecosystem. BNT is NOT an investment, security, or financial instrument. It does not represent ownership, equity, or profit-sharing rights in Blocnet.
              </p>

              <p className="font-semibold text-foreground mt-4">
                4.2 Mining Rewards
              </p>
              <ul className="list-disc pl-5 sm:pl-6 space-y-2">
                <li>Mining rewards are distributed based on 24-hour cycles and referral networks</li>
                <li>Reward amounts may vary based on network participation and platform algorithms</li>
                <li>We reserve the right to modify reward structures with reasonable notice</li>
                <li>Mining does not guarantee fixed returns or appreciation in value</li>
              </ul>

              <p className="font-semibold text-foreground mt-4">
                4.3 No Investment Advice
              </p>
              <p>
                Nothing on our platform constitutes investment, financial, legal, or tax advice. You are solely responsible for evaluating the risks and merits of any decision related to BNT or other digital assets.
              </p>
            </div>
          </section>

          {/* Platform Services */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              5. Platform Services
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p className="font-semibold text-foreground">
                5.1 AI-Powered Recommendations (BEE)
              </p>
              <p>
                Blocnet Edge Engine provides AI-generated recommendations based on algorithms and user behavior. These recommendations are informational only and should not be construed as professional advice or guaranteed outcomes.
              </p>

              <p className="font-semibold text-foreground mt-4">
                5.2 Community Content
              </p>
              <p>
                User-generated content (updates, comments, tips) is provided by community members (&quot;Hunters&quot;). We do not endorse, verify, or guarantee the accuracy of community content. Always conduct your own research.
              </p>

              <p className="font-semibold text-foreground mt-4">
                5.3 Swap and Exchange
              </p>
              <p>
                Swap functionality is provided through third-party integrations. We act as an interface only and do not control transaction execution, pricing, or settlement. All swaps are subject to blockchain confirmation and network fees.
              </p>
            </div>
          </section>

          {/* Prohibited Activities */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              6. Prohibited Activities
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p>You agree NOT to:</p>
              <ul className="list-disc pl-5 sm:pl-6 space-y-2">
                <li>Use the Services for any illegal activity, money laundering, or fraud</li>
                <li>Create fake accounts, manipulate mining rewards, or abuse referral systems</li>
                <li>Attempt to hack, disrupt, or compromise platform security</li>
                <li>Post spam, malicious content, or misleading information</li>
                <li>Impersonate others or misrepresent your affiliation with projects</li>
                <li>Scrape, copy, or redistribute platform data without permission</li>
                <li>Violate intellectual property rights or applicable regulations</li>
                <li>Engage in market manipulation or pump-and-dump schemes</li>
              </ul>
              <p className="mt-4">
                Violation of these prohibitions may result in account suspension or termination.
              </p>
            </div>
          </section>

          {/* Risks and Disclaimers */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              7. Risks and Disclaimers
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p className="font-semibold text-foreground">
                7.1 Cryptocurrency Risks
              </p>
              <p>
                You acknowledge and accept the inherent risks of cryptocurrency, including but not limited to:
              </p>
              <ul className="list-disc pl-5 sm:pl-6 space-y-2">
                <li>Price volatility and potential loss of value</li>
                <li>Regulatory uncertainty and changing legal landscape</li>
                <li>Smart contract vulnerabilities and blockchain risks</li>
                <li>Irreversible transactions and loss of funds</li>
                <li>Network congestion and transaction delays</li>
              </ul>

              <p className="font-semibold text-foreground mt-4">
                7.2 No Guarantees
              </p>
              <p>
                Services are provided &quot;AS IS&quot; without warranties of any kind. We do not guarantee uptime, accuracy of information, transaction success, or specific outcomes.
              </p>
            </div>
          </section>

          {/* Limitation of Liability */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              8. Limitation of Liability
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p>
                TO THE MAXIMUM EXTENT PERMITTED BY LAW:
              </p>
              <ul className="list-disc pl-5 sm:pl-6 space-y-2">
                <li>Blocnet shall not be liable for any indirect, incidental, special, or consequential damages</li>
                <li>Our total liability shall not exceed $100 USD or the amount you paid us in the past 12 months, whichever is greater</li>
                <li>We are not liable for losses due to user error, forgotten passwords, compromised credentials, or blockchain failures</li>
                <li>We are not responsible for third-party services, smart contracts, or external platforms integrated with Blocnet</li>
              </ul>
            </div>
          </section>

          {/* Intellectual Property */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              9. Intellectual Property
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p>
                All platform content, including logos, designs, text, graphics, software, and the Blocnet Edge Engine algorithm, are owned by Blocnet or our licensors and protected by intellectual property laws.
              </p>
              <p>
                You retain ownership of content you submit but grant us a worldwide, non-exclusive, royalty-free license to use, display, and distribute your content within the platform.
              </p>
            </div>
          </section>

          {/* Termination */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              10. Termination
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p>
                We reserve the right to suspend or terminate your access to the Services at our sole discretion, with or without notice, for violations of these Terms or other legitimate reasons.
              </p>
              <p>
                You may discontinue use of the Services at any time. As a non-custodial platform, you retain control of your wallet and assets upon termination.
              </p>
            </div>
          </section>

          {/* Governing Law */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              11. Governing Law and Dispute Resolution
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p>
                These Terms shall be governed by and construed in accordance with the laws of [Jurisdiction], without regard to conflict of law principles.
              </p>
              <p>
                Any disputes shall first be attempted to be resolved through good-faith negotiation. If unresolved, disputes shall be settled through binding arbitration in accordance with [Arbitration Rules].
              </p>
            </div>
          </section>

          {/* Changes to Terms */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              12. Changes to Terms
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p>
                We reserve the right to modify these Terms at any time. Material changes will be communicated through the platform or email with reasonable notice. Your continued use of Services after changes constitutes acceptance of the updated Terms.
              </p>
            </div>
          </section>

          {/* Contact */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              13. Contact Information
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p>
                For questions or concerns regarding these Terms, please contact us at:
              </p>
              <div className="mt-4 p-4 sm:p-6 bg-surface-2/50 border border-border rounded-xl">
                <p className="font-semibold text-foreground">Blocnet Support</p>
                <p>Email: legal@blocnet.app</p>
                <p>Website: https://blocnet.app</p>
              </div>
            </div>
          </section>

          {/* Acknowledgment */}
          <section className="mt-10 sm:mt-12 p-4 sm:p-6 bg-teal-500/10 border border-teal-500/20 rounded-xl">
            <p className="text-sm sm:text-base text-foreground font-semibold mb-2">
              By using Blocnet Services, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.
            </p>
          </section>
        </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}
