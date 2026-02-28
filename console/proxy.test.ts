import { describe, expect, it } from "vitest";
import { config, isProtectedAdminPath } from "./proxy";

describe("admin middleware protection strategy", () => {
  it("keeps sign-in and sign-out public", () => {
    expect(isProtectedAdminPath("/signin")).toBe(false);
    expect(isProtectedAdminPath("/signin/reset")).toBe(false);
    expect(isProtectedAdminPath("/signout")).toBe(false);
  });

  it("never protects platform/static paths", () => {
    expect(isProtectedAdminPath("/api/proxy/me")).toBe(false);
    expect(isProtectedAdminPath("/_next/static/chunks/a.js")).toBe(false);
    expect(isProtectedAdminPath("/favicon.ico")).toBe(false);
  });

  it("protects admin application routes by default", () => {
    expect(isProtectedAdminPath("/dashboard")).toBe(true);
    expect(isProtectedAdminPath("/users/abc")).toBe(true);
    expect(isProtectedAdminPath("/wallet-settings")).toBe(true);
  });

  it("uses a single broad matcher for non-api pages", () => {
    expect(config.matcher).toEqual([
      "/((?!api|_next/static|_next/image|favicon.ico).*)",
    ]);
  });
});
