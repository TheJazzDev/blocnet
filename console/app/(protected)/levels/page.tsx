import type { Metadata } from 'next';

import LevelsPageClient from '@/components/features/levels/_components/LevelsPageClient';

export const metadata: Metadata = {
  title: 'User Levels | Blocnet Console',
  description: 'Manage user level system, thresholds, and progression.',
};

export default function LevelsPage() {
  return <LevelsPageClient />;
}
