import type { Metadata } from 'next';

import DashboardPageClient from '@/components/features/dashboard/_components/DashboardPageClient';

export const metadata: Metadata = {
  title: 'Dashboard | Blocnet Console',
  description: 'View ecosystem metrics, moderation health, and operational alerts in one place.',
};

export default function DashboardPage() {
  return <DashboardPageClient />;
}
