import type { Metadata } from 'next';

import NotificationsPageClient from '@/components/features/notifications/_components/NotificationsPageClient';

export const metadata: Metadata = {
  title: 'Notifications | Blocnet Console',
  description:
    'Send push/in-app notifications and email broadcasts from dedicated admin tabs.',
};

export default function NotificationsPage() {
  return <NotificationsPageClient />;
}
