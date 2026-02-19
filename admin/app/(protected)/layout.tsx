import { redirect } from "next/navigation";
import { AdminShell } from "@/components/admin-shell";
import { getAuthorizedAdminProfile } from "@/lib/admin-auth";

export default async function ProtectedLayout({
  children
}: {
  children: React.ReactNode;
}) {
  const profile = await getAuthorizedAdminProfile();
  if (!profile) {
    redirect("/signin");
  }

  return (
    <AdminShell
      currentUser={{
        id: profile.id,
        email: profile.email,
        displayName: profile.displayName,
        roles: profile.roles,
      }}
    >
      {children}
    </AdminShell>
  );
}
