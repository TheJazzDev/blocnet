import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Blocnet — The Future of Crypto Connections",
  description:
    "Your one-stop hub for blockchain intelligence. Real-time airdrop alerts, mining updates, staking opportunities, Web3 jobs, and a decentralised wallet — all in one place.",
  keywords: ["blockchain", "crypto", "airdrop", "mining", "staking", "web3", "BNT", "blocnet"],
  openGraph: {
    title: "Blocnet — The Future of Crypto Connections",
    description:
      "Stay informed on projects you care about. Never miss an airdrop or mining update again.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${geistSans.variable} ${geistMono.variable} antialiased`}>
        {children}
      </body>
    </html>
  );
}
