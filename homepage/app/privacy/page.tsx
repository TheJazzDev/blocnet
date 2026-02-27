import type { Metadata } from 'next';
import { Navbar } from '@/components/ui/Navbar';
import { Footer } from '@/components/sections/Footer';

export const metadata: Metadata = {
  title: 'Privacy Policy — Blocnet',
  description: 'Privacy Policy for Blocnet — how we collect, use, and protect your data.',
};

export default function PrivacyPage() {
  return (
    <div className="min-h-screen bg-[#09090b] text-foreground">
      <Navbar />
      <main className="pt-20 sm:pt-24 md:pt-28 pb-16 sm:pb-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-4xl mx-auto">
        <div className="mb-10 sm:mb-12">
          <h1 className="text-3xl sm:text-4xl md:text-5xl font-bold text-foreground mb-4">
            Privacy Policy
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
                At Blocnet ("we", "us", "our"), we respect your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, store, and protect your information when you use our platform, mobile application, and services.
              </p>
              <p>
                As a Web3 platform, we prioritize data minimization, user sovereignty, and decentralization. We collect only what is necessary to provide our services and give you control over your data.
              </p>
            </div>
          </section>

          {/* Information We Collect */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              2. Information We Collect
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p className="font-semibold text-foreground">
                2.1 Information You Provide
              </p>
              <ul className="list-disc pl-5 sm:pl-6 space-y-2">
                <li><span className="font-medium text-foreground">Account Information:</span> Email address (optional), username, profile picture</li>
                <li><span className="font-medium text-foreground">Authentication Data:</span> Login credentials through Supabase authentication</li>
                <li><span className="font-medium text-foreground">User Content:</span> Updates, comments, project submissions, tips, and other content you create</li>
                <li><span className="font-medium text-foreground">Preferences:</span> Followed projects, notification settings, display preferences</li>
              </ul>

              <p className="font-semibold text-foreground mt-4">
                2.2 Blockchain and Wallet Data
              </p>
              <ul className="list-disc pl-5 sm:pl-6 space-y-2">
                <li><span className="font-medium text-foreground">Wallet Addresses:</span> Public wallet addresses you connect to the platform</li>
                <li><span className="font-medium text-foreground">Transaction Data:</span> On-chain transaction history (publicly visible on blockchain)</li>
                <li><span className="font-medium text-foreground">Mining Activity:</span> Mining cycles, rewards earned, referral network data</li>
                <li><span className="font-medium text-foreground">Token Balances:</span> BNT and other token holdings (derived from blockchain)</li>
              </ul>

              <p className="font-semibold text-foreground mt-4">
                2.3 Automatically Collected Information
              </p>
              <ul className="list-disc pl-5 sm:pl-6 space-y-2">
                <li><span className="font-medium text-foreground">Device Information:</span> Device type, operating system, browser type, mobile app version</li>
                <li><span className="font-medium text-foreground">Usage Data:</span> Features used, time spent, interactions, navigation patterns</li>
                <li><span className="font-medium text-foreground">Analytics:</span> Aggregated and anonymized usage statistics</li>
                <li><span className="font-medium text-foreground">Device Tokens:</span> Push notification tokens (with your consent)</li>
                <li><span className="font-medium text-foreground">IP Address:</span> For security, fraud prevention, and geo-location (not stored long-term)</li>
              </ul>

              <p className="font-semibold text-foreground mt-4">
                2.4 Information We DO NOT Collect
              </p>
              <ul className="list-disc pl-5 sm:pl-6 space-y-2">
                <li>Private keys, seed phrases, or wallet passwords</li>
                <li>Social security numbers or government IDs</li>
                <li>Banking or credit card information</li>
                <li>Detailed personal financial records</li>
              </ul>
            </div>
          </section>

          {/* How We Use Your Information */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              3. How We Use Your Information
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p>We use your information to:</p>
              <ul className="list-disc pl-5 sm:pl-6 space-y-2">
                <li><span className="font-medium text-foreground">Provide Services:</span> Enable account creation, mining, wallet functionality, and platform features</li>
                <li><span className="font-medium text-foreground">Personalization:</span> Deliver AI-powered recommendations through BEE based on your preferences and behavior</li>
                <li><span className="font-medium text-foreground">Communications:</span> Send notifications about updates, mining cycles, comments, and important announcements</li>
                <li><span className="font-medium text-foreground">Security:</span> Detect fraud, prevent abuse, ensure platform integrity</li>
                <li><span className="font-medium text-foreground">Improvement:</span> Analyze usage patterns to enhance features and user experience</li>
                <li><span className="font-medium text-foreground">Compliance:</span> Meet legal obligations and enforce our Terms of Service</li>
                <li><span className="font-medium text-foreground">Support:</span> Respond to inquiries, troubleshoot issues, provide customer assistance</li>
              </ul>
            </div>
          </section>

          {/* Data Sharing and Disclosure */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              4. Data Sharing and Disclosure
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p className="font-semibold text-foreground">
                4.1 We DO NOT Sell Your Data
              </p>
              <p>
                We do not sell, rent, or trade your personal information to third parties for marketing purposes.
              </p>

              <p className="font-semibold text-foreground mt-4">
                4.2 When We Share Information
              </p>
              <ul className="list-disc pl-5 sm:pl-6 space-y-2">
                <li><span className="font-medium text-foreground">Public Blockchain:</span> Wallet addresses and transactions are public on BNB Smart Chain</li>
                <li><span className="font-medium text-foreground">Service Providers:</span> Trusted third-party services (hosting, analytics, authentication) under strict data protection agreements</li>
                <li><span className="font-medium text-foreground">Community Content:</span> Updates, comments, and profiles are visible to other users as intended by the platform</li>
                <li><span className="font-medium text-foreground">Legal Requirements:</span> When required by law, court order, or to protect rights and safety</li>
                <li><span className="font-medium text-foreground">Business Transfers:</span> In the event of merger, acquisition, or sale of assets (with user notification)</li>
                <li><span className="font-medium text-foreground">With Your Consent:</span> Any other sharing will require your explicit consent</li>
              </ul>

              <p className="font-semibold text-foreground mt-4">
                4.3 Third-Party Services
              </p>
              <p>
                We integrate with third-party services including:
              </p>
              <ul className="list-disc pl-5 sm:pl-6 space-y-2">
                <li>Supabase (authentication and database hosting)</li>
                <li>BNB Smart Chain network</li>
                <li>Analytics providers (anonymized data)</li>
                <li>Cloud infrastructure providers</li>
              </ul>
              <p className="mt-2">
                These providers have their own privacy policies and data practices.
              </p>
            </div>
          </section>

          {/* Data Security */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              5. Data Security
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p>
                We implement industry-standard security measures to protect your data:
              </p>
              <ul className="list-disc pl-5 sm:pl-6 space-y-2">
                <li>Encryption of data in transit (TLS/SSL) and at rest</li>
                <li>Secure authentication through Supabase with JWT tokens</li>
                <li>Regular security audits and vulnerability assessments</li>
                <li>Access controls and least-privilege principles</li>
                <li>Non-custodial wallet architecture (you control your keys)</li>
                <li>Secure cloud infrastructure with reputable providers</li>
              </ul>
              <p className="mt-4">
                However, no system is 100% secure. You are responsible for safeguarding your credentials, private keys, and seed phrases. We are not liable for losses due to compromised user credentials.
              </p>
            </div>
          </section>

          {/* Data Retention */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              6. Data Retention
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p>
                We retain your data for as long as necessary to provide services and comply with legal obligations:
              </p>
              <ul className="list-disc pl-5 sm:pl-6 space-y-2">
                <li><span className="font-medium text-foreground">Account Data:</span> Until you delete your account or request deletion</li>
                <li><span className="font-medium text-foreground">Blockchain Data:</span> Permanently recorded on public blockchain (immutable)</li>
                <li><span className="font-medium text-foreground">Logs and Analytics:</span> Typically 90 days, anonymized data may be retained longer</li>
                <li><span className="font-medium text-foreground">Legal Compliance:</span> Longer retention if required by law or ongoing disputes</li>
              </ul>
              <p className="mt-4">
                After account deletion, some data may remain in backups for a limited period or as required by law.
              </p>
            </div>
          </section>

          {/* Your Rights */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              7. Your Privacy Rights
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p>
                Depending on your jurisdiction, you may have the following rights:
              </p>
              <ul className="list-disc pl-5 sm:pl-6 space-y-2">
                <li><span className="font-medium text-foreground">Access:</span> Request a copy of your personal data we hold</li>
                <li><span className="font-medium text-foreground">Correction:</span> Update or correct inaccurate information</li>
                <li><span className="font-medium text-foreground">Deletion:</span> Request deletion of your account and associated data (subject to legal obligations)</li>
                <li><span className="font-medium text-foreground">Portability:</span> Receive your data in a machine-readable format</li>
                <li><span className="font-medium text-foreground">Opt-Out:</span> Unsubscribe from marketing communications and disable push notifications</li>
                <li><span className="font-medium text-foreground">Object:</span> Object to certain data processing activities</li>
                <li><span className="font-medium text-foreground">Withdraw Consent:</span> Revoke previously granted consent</li>
              </ul>
              <p className="mt-4">
                To exercise these rights, contact us at <span className="text-teal-400">privacy@blocnet.app</span>. We will respond within 30 days.
              </p>
              <p className="mt-4 font-semibold text-foreground">
                Note: Blockchain data cannot be deleted due to its immutable nature.
              </p>
            </div>
          </section>

          {/* Cookies and Tracking */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              8. Cookies and Tracking Technologies
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p>
                We use cookies and similar technologies for:
              </p>
              <ul className="list-disc pl-5 sm:pl-6 space-y-2">
                <li><span className="font-medium text-foreground">Essential Cookies:</span> Required for authentication and basic functionality</li>
                <li><span className="font-medium text-foreground">Analytics Cookies:</span> To understand usage patterns (anonymized)</li>
                <li><span className="font-medium text-foreground">Preference Cookies:</span> To remember your settings and preferences</li>
              </ul>
              <p className="mt-4">
                You can control cookies through your browser settings. Disabling essential cookies may impact platform functionality.
              </p>
            </div>
          </section>

          {/* International Transfers */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              9. International Data Transfers
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p>
                As a global platform, your data may be transferred to and processed in countries outside your jurisdiction. We ensure appropriate safeguards are in place, including:
              </p>
              <ul className="list-disc pl-5 sm:pl-6 space-y-2">
                <li>Standard contractual clauses</li>
                <li>Data processing agreements with service providers</li>
                <li>Compliance with GDPR, CCPA, and other privacy regulations</li>
              </ul>
            </div>
          </section>

          {/* Children's Privacy */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              10. Children's Privacy
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p>
                Our Services are not intended for users under 18 years of age. We do not knowingly collect information from children. If we discover that a child has provided personal data, we will delete it immediately.
              </p>
              <p>
                Parents or guardians who believe their child has provided information should contact us at <span className="text-teal-400">privacy@blocnet.app</span>.
              </p>
            </div>
          </section>

          {/* Web3-Specific Considerations */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              11. Web3-Specific Privacy Considerations
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p className="font-semibold text-foreground">
                11.1 Blockchain Transparency
              </p>
              <p>
                Blockchain transactions are public and permanent. Wallet addresses, token transfers, and smart contract interactions are visible to anyone. Do not share sensitive information in on-chain transactions.
              </p>

              <p className="font-semibold text-foreground mt-4">
                11.2 Pseudonymity
              </p>
              <p>
                While wallet addresses are pseudonymous, they can potentially be linked to your identity through various means (KYC, IP addresses, transaction patterns). Consider privacy best practices when using blockchain services.
              </p>

              <p className="font-semibold text-foreground mt-4">
                11.3 Non-Custodial Model
              </p>
              <p>
                We do not control your wallet or assets. This enhances privacy and security but also means we cannot recover lost credentials or reverse transactions.
              </p>
            </div>
          </section>

          {/* Changes to Privacy Policy */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              12. Changes to This Privacy Policy
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p>
                We may update this Privacy Policy from time to time to reflect changes in our practices, technology, legal requirements, or other factors. Material changes will be communicated through:
              </p>
              <ul className="list-disc pl-5 sm:pl-6 space-y-2">
                <li>In-app notifications</li>
                <li>Email announcements</li>
                <li>Website banner or notice</li>
              </ul>
              <p className="mt-4">
                Continued use of the Services after changes constitutes acceptance of the updated Privacy Policy. The "Last Updated" date at the top of this page indicates when changes were made.
              </p>
            </div>
          </section>

          {/* Contact Information */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              13. Contact Us
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p>
                For questions, concerns, or requests regarding this Privacy Policy or your personal data, please contact us:
              </p>
              <div className="mt-4 p-4 sm:p-6 bg-surface-2/50 border border-border rounded-xl">
                <p className="font-semibold text-foreground">Blocnet Privacy Team</p>
                <p>Email: privacy@blocnet.app</p>
                <p>Support: support@blocnet.app</p>
                <p>Website: https://blocnet.app</p>
              </div>
            </div>
          </section>

          {/* GDPR/CCPA Compliance */}
          <section>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4">
              14. Regional Privacy Rights
            </h2>
            <div className="space-y-3 text-sm sm:text-base leading-relaxed">
              <p className="font-semibold text-foreground">
                14.1 GDPR (European Users)
              </p>
              <p>
                If you are located in the European Economic Area (EEA), you have specific rights under the General Data Protection Regulation (GDPR), including access, rectification, erasure, restriction, portability, and the right to lodge a complaint with a supervisory authority.
              </p>

              <p className="font-semibold text-foreground mt-4">
                14.2 CCPA (California Users)
              </p>
              <p>
                If you are a California resident, you have rights under the California Consumer Privacy Act (CCPA), including the right to know what personal information is collected, sold, or disclosed, and the right to opt-out of the sale of personal information.
              </p>
              <p>
                <span className="font-medium text-foreground">Note:</span> We do not sell personal information.
              </p>
            </div>
          </section>

          {/* Acknowledgment */}
          <section className="mt-10 sm:mt-12 p-4 sm:p-6 bg-teal-500/10 border border-teal-500/20 rounded-xl">
            <p className="text-sm sm:text-base text-foreground font-semibold mb-2">
              By using Blocnet Services, you acknowledge that you have read and understood this Privacy Policy and consent to the collection, use, and sharing of your information as described herein.
            </p>
          </section>
        </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}
