import type { Metadata } from 'next';

import SettingsPageClient from '@/components/features/settings/_components/SettingsPageClient';

export const metadata: Metadata = {
  title: 'Settings | Blocnet Console',
  description: 'Configure security, integrations, feature flags, and runtime settings for Blocnet Console.',
};

export default function SettingsPage() {
  return <SettingsPageClient />;
}
