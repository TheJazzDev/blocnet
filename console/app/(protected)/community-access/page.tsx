import type { Metadata } from 'next';

import CommunityAccessPageClient from '@/components/features/community-access/_components/CommunityAccessPageClient';

export const metadata: Metadata = {
  title: 'Community Access | Blocnet Console',
  description:
    'Manage community admin and moderator role assignments for ecosystem operations.',
};

export default function CommunityAccessPage() {
  return <CommunityAccessPageClient />;
}
