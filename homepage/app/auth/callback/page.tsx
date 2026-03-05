import { OpenAppBridge } from '@/components/open/OpenAppBridge';

type AuthCallbackPageProps = {
  searchParams?:
    | Record<string, string | string[] | undefined>
    | Promise<Record<string, string | string[] | undefined>>;
};

function firstValue(value: string | string[] | undefined): string {
  if (Array.isArray(value)) return value[0] ?? '';
  return value ?? '';
}

export default async function AuthCallbackPage({
  searchParams,
}: AuthCallbackPageProps) {
  const resolved = await Promise.resolve(searchParams ?? {});
  const code = firstValue(resolved.code);
  const type = firstValue(resolved.type);
  const query = new URLSearchParams();
  if (code) query.set('code', code);
  if (type) query.set('type', type);
  const path = query.toString()
    ? `/auth/callback?${query.toString()}`
    : '/auth/callback';
  return <OpenAppBridge path={path} />;
}
