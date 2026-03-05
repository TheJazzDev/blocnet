import { redirect } from 'next/navigation';

type CommunityPostLinkPageProps = {
  params: { id: string } | Promise<{ id: string }>;
};

export default async function CommunityPostLinkPage({
  params,
}: CommunityPostLinkPageProps) {
  const resolved = await Promise.resolve(params);
  const path = `/community/posts/${resolved.id ?? ''}`;
  redirect(`/open?path=${encodeURIComponent(path)}`);
}
