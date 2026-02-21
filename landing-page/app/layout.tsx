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
  title: 'Blocnet — The Future of Crypto Connections',
  description:
    'Your one-stop hub for blockchain intelligence. Real-time airdrop alerts, mining updates, staking opportunities, Web3 jobs, and a decentralised wallet — all in one place.',
  keywords: [
    'blockchain',
    'crypto',
    'airdrop',
    'mining',
    'staking',
    'web3',
    'BNT',
    'blocnet',
  ],
  openGraph: {
    title: 'Blocnet — The Future of Crypto Connections',
    description:
      'Stay informed on projects you care about. Never miss an airdrop or mining update again.',
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
