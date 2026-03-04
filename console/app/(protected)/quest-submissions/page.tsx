import type { Metadata } from 'next';

import QuestSubmissionsPageClient from '@/components/features/quest-submissions/_components/QuestSubmissionsPageClient';

export const metadata: Metadata = {
  title: 'Quest Submissions | Blocnet Console',
  description: 'Review, approve, and reject quest submissions with moderation notes.',
};

export default function QuestSubmissionsPage() {
  return <QuestSubmissionsPageClient />;
}
