import type { AdminUser } from "@/lib/api-client";
import type { AdminPanelRole } from "@/lib/rbac";

export type GovernanceRole = AdminPanelRole;
export type GovernanceFilter = "all" | GovernanceRole;
export type StatusFilter = "all" | "active" | "deactivated";

export type GovernanceAction =
  | "grant_owner"
  | "revoke_owner"
  | "grant_dev"
  | "revoke_dev"
  | "grant_admin"
  | "revoke_admin";

export type PendingGovernanceAction = {
  user: AdminUser;
  action: GovernanceAction;
} | null;

export function getInitials(name: string | null, email: string) {
  const source = name ?? email;
  return source
    .split(/[\s@]/)
    .filter(Boolean)
    .map((word) => word[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}
