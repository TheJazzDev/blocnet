import type { Metadata } from 'next';
import localFont from 'next/font/local';
import './globals.css';

const geistSans = localFont({
  variable: '--font-geist-sans',
  src: [
    { path: './fonts/Geist-Regular.ttf', weight: '400', style: 'normal' },
    { path: './fonts/Geist-Medium.ttf', weight: '500', style: 'normal' },
  ],
  display: 'swap',
});

const geistMono = localFont({
  variable: '--font-geist-mono',
  src: [{ path: './fonts/Geist-Regular.ttf', weight: '400', style: 'normal' }],
  display: 'swap',
});

export const metadata: Metadata = {
  title: 'Blocnet — AI-Powered Crypto Intelligence Hub',
  description:
    'AI-powered crypto intelligence with Blocnet Edge Engine (BEE) decision system. Get smart recommendations, earn through mining, track projects, manage your multi-asset wallet, and join a thriving community.',
  keywords: [
    'blockchain',
    'crypto',
    'AI crypto',
    'Blocnet Edge Engine',
    'BEE',
    'crypto intelligence',
    'airdrop',
    'mining',
    'referral network',
    'staking',
    'web3',
    'multi-asset wallet',
    'BNT',
    'USDT',
    'SOL',
    'blocnet',
    'crypto updates',
    'decision engine',
  ],
  openGraph: {
    title: 'Blocnet — AI-Powered Crypto Intelligence Hub',
    description:
      'Experience Blocnet Edge Engine (BEE): intelligent action recommendations, urgency scoring, and personalized insights for crypto updates. Never miss what matters.',
    type: 'website',
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang='en'>
      <head>
        <link
          rel='apple-touch-icon'
          sizes='180x180'
          href='/apple-touch-icon.png'
        />
        <link
          rel='icon'
          type='image/png'
          sizes='32x32'
          href='/favicon-32x32.png'
        />
        <link
          rel='icon'
          type='image/png'
          sizes='16x16'
          href='/favicon-16x16.png'
        />
        <link rel='manifest' href='/site.webmanifest' />
      </head>
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}>
        {children}
      </body>
    </html>
  );
}
