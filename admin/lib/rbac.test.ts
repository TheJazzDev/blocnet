import { describe, expect, it } from "vitest";
import {
  buildLocalRolesMatrix,
  canAccessAdminPanel,
  canManageAdmins,
  canManageModerators,
  canMutateWallet,
  diffRoleCapabilities,
  getRoleViewOptions,
  isModeratorOnly,
  resolveEffectiveRoles,
} from "./rbac";

describe("rbac", () => {
  it("allows owner/admin/moderator into admin panel", () => {
    expect(canAccessAdminPanel(["owner"])).toBe(true);
    expect(canAccessAdminPanel(["admin"])).toBe(true);
    expect(canAccessAdminPanel(["moderator"])).toBe(true);
    expect(canAccessAdminPanel(["user"])).toBe(false);
  });

  it("restricts admin management to owner", () => {
    expect(canManageAdmins(["owner"])).toBe(true);
    expect(canManageAdmins(["admin"])).toBe(false);
    expect(canManageAdmins(["moderator"])).toBe(false);
  });

  it("allows owner/admin to manage moderators and wallet mutation", () => {
    expect(canManageModerators(["owner"])).toBe(true);
    expect(canManageModerators(["admin"])).toBe(true);
    expect(canManageModerators(["moderator"])).toBe(false);

    expect(canMutateWallet(["owner"])).toBe(true);
    expect(canMutateWallet(["admin"])).toBe(true);
    expect(canMutateWallet(["moderator"])).toBe(false);
  });

  it("identifies moderator-only role correctly", () => {
    expect(isModeratorOnly(["moderator"])).toBe(true);
    expect(isModeratorOnly(["moderator", "admin"])).toBe(false);
    expect(isModeratorOnly(["moderator", "owner"])).toBe(false);
  });

  it("resolves effective roles for view mode without allowing escalation", () => {
    expect(resolveEffectiveRoles(["owner", "hunter"], "admin")).toEqual(["hunter", "admin"]);
    expect(resolveEffectiveRoles(["admin", "hunter"], "moderator")).toEqual(["hunter", "moderator"]);
    expect(resolveEffectiveRoles(["moderator"], "admin")).toEqual(["moderator"]);
    expect(resolveEffectiveRoles(["owner"], "super")).toEqual(["owner"]);
  });

  it("returns correct role-view options", () => {
    expect(getRoleViewOptions(["owner"])).toEqual(["owner", "admin", "moderator"]);
    expect(getRoleViewOptions(["admin"])).toEqual(["admin", "moderator"]);
    expect(getRoleViewOptions(["moderator"])).toEqual(["moderator"]);
    expect(getRoleViewOptions(["hunter"])).toEqual([]);
  });

  it("computes role capability diffs", () => {
    const diff = diffRoleCapabilities("moderator", "admin");
    expect(diff.gained.some((entry) => entry.key === "wallet.settings.mutate")).toBe(true);
    expect(diff.removed).toHaveLength(0);
  });

  it("builds local role matrix with governance and space roles", () => {
    const matrix = buildLocalRolesMatrix();
    expect(matrix.governanceRoles.map((entry) => entry.role)).toEqual([
      "owner",
      "admin",
      "moderator",
    ]);
    expect(matrix.spaceRoles.map((entry) => entry.role)).toEqual([
      "user",
      "core_team",
      "hunter",
    ]);
    expect(matrix.sections.some((entry) => entry.id === "access")).toBe(true);
  });
});
