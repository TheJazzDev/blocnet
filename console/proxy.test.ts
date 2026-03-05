import { describe, expect, it } from "vitest";
import { config, isBlockedMobileUserAgent, isProtectedAdminPath } from "./proxy";

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
    expect(isProtectedAdminPath("/unsupported-device")).toBe(false);
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

  it("blocks phone browsers and allows tablet/desktop user agents", () => {
    expect(
      isBlockedMobileUserAgent(
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
      ),
    ).toBe(true);
    expect(
      isBlockedMobileUserAgent(
        "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Mobile Safari/537.36",
      ),
    ).toBe(true);
    expect(
      isBlockedMobileUserAgent(
        "Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
      ),
    ).toBe(false);
    expect(
      isBlockedMobileUserAgent(
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36",
      ),
    ).toBe(false);
  });
});
