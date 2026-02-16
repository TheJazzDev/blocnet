import { redirect } from "next/navigation";
import { AdminShell } from "@/components/admin-shell";
import { isAdminAuthorized } from "@/lib/admin-auth";

export default async function ProtectedLayout({
  children
}: {
  children: React.ReactNode;
}) {
  const allowed = await isAdminAuthorized();
  if (!allowed) {
    redirect("/signin");
  }

  return <AdminShell>{children}</AdminShell>;
}
