import { redirect } from 'next/navigation';

type ReferralLinkPageProps = {
  params: { code: string } | Promise<{ code: string }>;
};

export default async function ReferralLinkPage({ params }: ReferralLinkPageProps) {
  const resolved = await Promise.resolve(params);
  const path = `/ref/${resolved.code ?? ''}`;
  redirect(`/open?path=${encodeURIComponent(path)}`);
}
