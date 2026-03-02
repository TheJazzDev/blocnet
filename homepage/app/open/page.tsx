import { OpenAppBridge } from '@/components/open/OpenAppBridge';

type OpenPageProps = {
  searchParams?:
    | Record<string, string | string[] | undefined>
    | Promise<Record<string, string | string[] | undefined>>;
};

function firstValue(value: string | string[] | undefined): string {
  if (Array.isArray(value)) return value[0] ?? '';
  return value ?? '';
}

export default async function OpenPage({ searchParams }: OpenPageProps) {
  const resolved = (await Promise.resolve(searchParams ?? {})) ?? {};
  const path =
    firstValue(resolved.path) ||
    firstValue(resolved.deeplink) ||
    firstValue(resolved.target) ||
    '/';

  return <OpenAppBridge path={path} />;
}
