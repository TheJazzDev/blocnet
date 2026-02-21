import { redirect } from "next/navigation";
import { cookies } from "next/headers";
import { AdminShell } from "@/components/admin-shell";
import { getAuthorizedAdminProfile } from "@/lib/admin-auth";
import {
  getAdminGovernanceRole,
  getRoleViewOptions,
  normalizeAdminPanelRole,
} from "@/lib/rbac";

export default async function ProtectedLayout({
  children
}: {
  children: React.ReactNode;
}) {
  const profile = await getAuthorizedAdminProfile();
  if (!profile) {
    redirect("/signin");
  }

  const cookieStore = await cookies();
  const requestedRole = normalizeAdminPanelRole(cookieStore.get("admin_view_as_role")?.value);
  const topRole = getAdminGovernanceRole(profile.roles);
  const allowedViewOptions = getRoleViewOptions(profile.roles);
  const actingAsRole =
    requestedRole && requestedRole !== topRole && allowedViewOptions.includes(requestedRole)
      ? requestedRole
      : null;

  return (
    <AdminShell
      currentUser={{
        id: profile.id,
        email: profile.email,
        displayName: profile.displayName,
        roles: profile.roles,
        actingAsRole,
      }}
    >
      {children}
    </AdminShell>
  );
}
