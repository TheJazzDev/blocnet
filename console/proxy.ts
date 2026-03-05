import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import {
  ADMIN_ACCESS_COOKIE,
  ADMIN_REFRESH_COOKIE,
  refreshAdminSession,
  runRefreshWithTokenLock,
  setAdminSessionCookies,
} from "@/lib/admin-session-refresh";

const PUBLIC_PATH_PREFIXES = ["/signin", "/signout"];
const PUBLIC_PLATFORM_PREFIXES = ["/api", "/_next"];
const PUBLIC_EXACT_PATHS = new Set(["/favicon.ico", "/unsupported-device"]);
const REFRESH_LEEWAY_SECONDS = 90;
const MOBILE_BLOCK_REDIRECT_PATH = "/unsupported-device";

function parseJwtExp(token: string): number | null {
  const parts = token.split(".");
  if (parts.length < 2) return null;
  try {
    const base64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const padded = base64.padEnd(Math.ceil(base64.length / 4) * 4, "=");
    const payload = JSON.parse(atob(padded)) as { exp?: unknown };
    const exp = Number(payload.exp);
    return Number.isFinite(exp) ? exp : null;
  } catch {
    return null;
  }
}

function shouldRefreshAccessToken(token: string): boolean {
  const exp = parseJwtExp(token);
  if (!exp) return true;
  const now = Math.floor(Date.now() / 1000);
  return exp - now <= REFRESH_LEEWAY_SECONDS;
}

function isExpiredAccessToken(token: string): boolean {
  const exp = parseJwtExp(token);
  if (!exp) return true;
  const now = Math.floor(Date.now() / 1000);
  return exp <= now;
}

export function isProtectedAdminPath(pathname: string): boolean {
  if (!pathname.startsWith("/")) return false;
  if (PUBLIC_EXACT_PATHS.has(pathname)) return false;

  if (
    PUBLIC_PATH_PREFIXES.some(
      (prefix) => pathname === prefix || pathname.startsWith(`${prefix}/`),
    )
  ) {
    return false;
  }

  return !PUBLIC_PLATFORM_PREFIXES.some(
    (prefix) => pathname === prefix || pathname.startsWith(`${prefix}/`),
  );
}

export function isBlockedMobileUserAgent(userAgent: string | null): boolean {
  if (!userAgent) return false;
  const agent = userAgent.toLowerCase();

  if (agent.includes("ipad") || agent.includes("tablet")) {
    return false;
  }

  if (
    agent.includes("iphone") ||
    agent.includes("ipod") ||
    agent.includes("windows phone")
  ) {
    return true;
  }

  const isAndroid = agent.includes("android");
  const isMobile = agent.includes("mobile");
  return isAndroid && isMobile;
}

function redirectToSignIn(request: NextRequest): NextResponse {
  const url = request.nextUrl.clone();
  url.pathname = "/signin";
  url.searchParams.set("next", request.nextUrl.pathname);
  return NextResponse.redirect(url);
}

export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const userAgent = request.headers.get("user-agent");
  const shouldBlockMobile = isBlockedMobileUserAgent(userAgent);

  if (shouldBlockMobile && pathname !== MOBILE_BLOCK_REDIRECT_PATH) {
    const url = request.nextUrl.clone();
    url.pathname = MOBILE_BLOCK_REDIRECT_PATH;
    url.search = "";
    return NextResponse.redirect(url);
  }

  if (!isProtectedAdminPath(pathname)) {
    return NextResponse.next();
  }

  const accessToken = request.cookies.get(ADMIN_ACCESS_COOKIE)?.value ?? null;
  const refreshToken = request.cookies.get(ADMIN_REFRESH_COOKIE)?.value ?? null;

  if (!accessToken && !refreshToken) {
    return redirectToSignIn(request);
  }

  const needsRefresh = !accessToken || shouldRefreshAccessToken(accessToken);
  if (needsRefresh) {
    if (!refreshToken) {
      return redirectToSignIn(request);
    }

    const refreshed = await runRefreshWithTokenLock(refreshToken, () =>
      refreshAdminSession(refreshToken),
    );

    if (refreshed.ok) {
      request.cookies.set(ADMIN_ACCESS_COOKIE, refreshed.accessToken);
      request.cookies.set(ADMIN_REFRESH_COOKIE, refreshed.refreshToken);

      const response = NextResponse.next({
        request: {
          headers: request.headers,
        },
      });
      setAdminSessionCookies(response.cookies, {
        accessToken: refreshed.accessToken,
        refreshToken: refreshed.refreshToken,
      });
      return response;
    }

    if (!accessToken || isExpiredAccessToken(accessToken)) {
      return redirectToSignIn(request);
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!api|_next/static|_next/image|favicon.ico).*)"],
};
