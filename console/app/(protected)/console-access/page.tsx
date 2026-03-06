import type { Metadata } from 'next';

import AdminAccessPageClient from '@/components/features/admin-access/_components/AdminAccessPageClient';

export const metadata: Metadata = {
  title: 'Console Access | Blocnet Console',
  description:
    'Manage owner, dev, and admin console access and governance controls.',
};

export default function ConsoleAccessPage() {
  return <AdminAccessPageClient />;
}
