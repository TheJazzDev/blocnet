import type { Metadata } from 'next';

import AdminAccessPageClient from '@/components/features/admin-access/_components/AdminAccessPageClient';

export const metadata: Metadata = {
  title: 'Admin Access | Blocnet Console',
  description:
    'Manage owner, dev, and admin panel access and governance controls.',
};

export default function AdminAccessPage() {
  return <AdminAccessPageClient />;
}
