"use client";

import { Badge } from "@/components/ui/badge";

export function roleBadge(role: "core_team" | "hunter" | "user") {
  if (role === "core_team") {
    return (
      <Badge
        className="border-sky-500/25 bg-sky-500/10 text-sky-300"
        variant="outline"
      >
        Core Team
      </Badge>
    );
  }

  if (role === "hunter") {
    return (
      <Badge
        className="border-emerald-500/20 bg-emerald-500/10 text-emerald-400"
        variant="outline"
      >
        Hunter
      </Badge>
    );
  }

  return <Badge variant="secondary">User</Badge>;
}

export function accountStatusBadge(isDeactivated: boolean) {
  if (isDeactivated) {
    return <Badge className="bg-red-500/15 text-red-300">Deactivated</Badge>;
  }
  return <Badge className="bg-emerald-500/15 text-emerald-300">Active</Badge>;
}

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

export function getHighestMemberRole(
  roles: string[],
): "core_team" | "hunter" | "user" {
  if (roles.includes("core_team")) return "core_team";
  if (roles.includes("hunter")) return "hunter";
  return "user";
}
