import type { Metadata } from 'next';

import PageClient from '@/components/features/projects/_components/PageClient';

export const metadata: Metadata = {
  title: 'Console | Blocnet Console',
  description: 'Manage Console in Blocnet Console.',
};

export default function Page() {
  return <PageClient />;
}
