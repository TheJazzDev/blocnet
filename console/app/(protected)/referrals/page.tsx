import type { Metadata } from 'next';

import PageClient from '@/components/features/referrals/_components/PageClient';

export const metadata: Metadata = {
  title: 'Referrals | Blocnet Console',
  description: 'Manage referrals and bind users to referral codes.',
};

export default function Page() {
  return <PageClient />;
}
