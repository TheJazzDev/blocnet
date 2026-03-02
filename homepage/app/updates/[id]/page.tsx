import { redirect } from 'next/navigation';

type UpdateLinkPageProps = {
  params: { id: string } | Promise<{ id: string }>;
};

export default async function UpdateLinkPage({ params }: UpdateLinkPageProps) {
  const resolved = await Promise.resolve(params);
  const path = `/updates/${resolved.id ?? ''}`;
  redirect(`/open?path=${encodeURIComponent(path)}`);
}
