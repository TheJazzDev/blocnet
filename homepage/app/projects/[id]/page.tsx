import { redirect } from 'next/navigation';

type ProjectLinkPageProps = {
  params: { id: string } | Promise<{ id: string }>;
};

export default async function ProjectLinkPage({
  params,
}: ProjectLinkPageProps) {
  const resolved = await Promise.resolve(params);
  const path = `/projects/${resolved.id ?? ''}`;
  redirect(`/open?path=${encodeURIComponent(path)}`);
}
