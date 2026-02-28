import { redirect } from "next/navigation";
import { cookies, headers } from "next/headers";
import { AdminShell } from "@/components/admin-shell";
import { getAuthorizedAdminProfile } from "@/lib/admin-auth";
import { api } from "@/lib/api";
import {
  getAdminGovernanceRole,
  getRoleViewOptions,
  normalizeAdminPanelRole,
} from "@/lib/rbac";
import { resolveAdminEnvironmentFromHost } from "@/lib/environment";

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
  const twoFactorSession = cookieStore.get("admin_2fa_session")?.value;

  const twoFactorPreflight = await api
    .getAdminTwoFactorPreflight()
    .catch(() => null);

  if (twoFactorPreflight?.challengeRequired) {
    if (!twoFactorSession) {
      redirect("/signin?reason=2fa_required");
    }

    const validation = await api
      .validateAdminTwoFactorSession(twoFactorSession)
      .catch(() => null);

    if (!validation?.valid) {
      redirect("/signin?reason=2fa_required");
    }
  }

  const headerStore = await headers();
  const host =
    headerStore.get("x-forwarded-host") ??
    headerStore.get("host");
  const environment = resolveAdminEnvironmentFromHost(host);
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
        environment,
        hostName: host,
      }}
    >
      {children}
    </AdminShell>
  );
}
