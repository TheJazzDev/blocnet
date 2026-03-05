import { redirect } from 'next/navigation';

type CommunityLinkPageProps = {
  params: { id: string } | Promise<{ id: string }>;
};

export default async function CommunityLinkPage({
  params,
}: CommunityLinkPageProps) {
  const resolved = await Promise.resolve(params);
  const path = `/community/${resolved.id ?? ''}`;
  redirect(`/open?path=${encodeURIComponent(path)}`);
}
