import { cookies } from "next/headers";

/**
 * Returns the Supabase access token stored in the session cookie,
 * or null if the user is not signed in.
 */
export async function getAdminSession(): Promise<{ token: string | null }> {
  const cookieStore = await cookies();
  const token = cookieStore.get("admin_token")?.value ?? null;
  return { token };
}

export async function isAdminAuthorized(): Promise<boolean> {
  const { token } = await getAdminSession();
  return Boolean(token);
}
