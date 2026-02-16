import { cookies } from "next/headers";

export async function getAdminSession() {
  const cookieStore = await cookies();
  const session = cookieStore.get("admin_session")?.value ?? null;
  const role = cookieStore.get("admin_role")?.value ?? "admin";
  return { session, role };
}

export async function isAdminAuthorized() {
  const { session, role } = await getAdminSession();
  return Boolean(session) && (role === "owner" || role === "admin");
}
