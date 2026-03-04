import type { Metadata } from 'next';

import BadgesPageClient from '@/components/features/badges/_components/BadgesPageClient';

export const metadata: Metadata = {
  title: 'Badges | Blocnet Console',
  description: 'Manage badge catalog, categories, rarity, and manual badge grants.',
};

export default function BadgesPage() {
  return <BadgesPageClient />;
}
