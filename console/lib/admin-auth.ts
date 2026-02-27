import { api, type AdminMe } from "@/lib/api";
import { canAccessAdminPanel } from "@/lib/rbac";

export async function getAdminProfile(): Promise<AdminMe | null> {
  try {
    return await api.getMe();
  } catch {
    return null;
  }
}

export async function getAuthorizedAdminProfile(): Promise<AdminMe | null> {
  const profile = await getAdminProfile();
  if (!profile) return null;
  return canAccessAdminPanel(profile.roles) ? profile : null;
}
