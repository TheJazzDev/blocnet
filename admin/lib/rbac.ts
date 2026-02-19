export type AdminPanelRole = "owner" | "admin" | "moderator";

export function hasRole(roles: string[], role: string): boolean {
  return roles.includes(role);
}

export function canAccessAdminPanel(roles: string[]): boolean {
  return roles.some((role) => role === "owner" || role === "admin" || role === "moderator");
}

export function canManageAdmins(roles: string[]): boolean {
  return hasRole(roles, "owner");
}

export function canManageModerators(roles: string[]): boolean {
  return hasRole(roles, "owner") || hasRole(roles, "admin");
}

export function canManageHunters(roles: string[]): boolean {
  return hasRole(roles, "owner") || hasRole(roles, "admin");
}

export function canReviewAdminApplications(roles: string[]): boolean {
  return hasRole(roles, "owner");
}

export function canReviewProjectProposals(roles: string[]): boolean {
  return canAccessAdminPanel(roles);
}

export function canManageTags(roles: string[]): boolean {
  return hasRole(roles, "owner") || hasRole(roles, "admin");
}

export function canMutateSettings(roles: string[]): boolean {
  return hasRole(roles, "owner");
}

export function canSendNotifications(roles: string[]): boolean {
  return hasRole(roles, "owner") || hasRole(roles, "admin");
}

export function isModeratorOnly(roles: string[]): boolean {
  return hasRole(roles, "moderator") && !hasRole(roles, "owner") && !hasRole(roles, "admin");
}
