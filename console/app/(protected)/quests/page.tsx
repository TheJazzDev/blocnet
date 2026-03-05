import type { Metadata } from 'next';

import QuestsPageClient from '@/components/features/quests/_components/QuestsPageClient';

export const metadata: Metadata = {
  title: 'Quests | Blocnet Console',
  description: 'Create and manage quest definitions, rewards, and verification settings.',
};

export default function QuestsPage() {
  return <QuestsPageClient />;
}
