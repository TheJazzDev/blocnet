import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

const PROTECTED_PREFIXES = [
  "/dashboard",
  "/projects",
  "/updates",
  "/comments",
  "/community",
  "/mining",
  "/badges",
  "/quests",
  "/quest-submissions",
  "/notifications",
  "/wallet-users",
  "/wallet-withdrawals",
  "/wallet-kyc",
  "/wallet-settings",
  "/tips-transactions",
  "/tip-settings",
  "/users",
  "/admin-access",
  "/roles",
  "/applications",
  "/edge-engine",
  "/audit-log",
  "/tags",
  "/settings",
];

const COOKIE_OPTS = {
  httpOnly: true,
  secure: process.env.NODE_ENV === "production",
  sameSite: "lax" as const,
  path: "/",
};

const ACCESS_TOKEN_MAX_AGE_SECONDS = 60 * 60;
const REFRESH_TOKEN_MAX_AGE_SECONDS = 60 * 60 * 24 * 7;
const REFRESH_LEEWAY_SECONDS = 90;

type RefreshOutcome =
  | { ok: true; accessToken: string; refreshToken: string }
  | { ok: false; concurrent: boolean };

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

function isConcurrentRefreshError(message: string | undefined): boolean {
  const normalized = message?.toLowerCase() ?? "";
  return normalized.includes("already used") || normalized.includes("reuse interval");
}

async function refreshWithSupabase(refreshToken: string): Promise<RefreshOutcome> {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const publishableKey = process.env.NEXT_PUBLIC_PUBLISHABLE_KEY;
  if (!supabaseUrl || !publishableKey) {
    return { ok: false, concurrent: false };
  }

  try {
    const res = await fetch(`${supabaseUrl}/auth/v1/token?grant_type=refresh_token`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: publishableKey,
        Authorization: `Bearer ${publishableKey}`,
      },
      body: JSON.stringify({ refresh_token: refreshToken }),
      cache: "no-store",
    });

    const body = (await res.json().catch(() => ({}))) as {
      access_token?: string;
      refresh_token?: string;
      error_description?: string;
      msg?: string;
      message?: string;
    };

    if (!res.ok || !body.access_token || !body.refresh_token) {
      const message =
        body.error_description ?? body.msg ?? body.message ?? `HTTP ${res.status}`;
      return { ok: false, concurrent: isConcurrentRefreshError(message) };
    }

    return {
      ok: true,
      accessToken: body.access_token,
      refreshToken: body.refresh_token,
    };
  } catch {
    return { ok: false, concurrent: false };
  }
}

function redirectToSignIn(request: NextRequest): NextResponse {
  const url = request.nextUrl.clone();
  url.pathname = "/signin";
  url.searchParams.set("next", request.nextUrl.pathname);
  return NextResponse.redirect(url);
}

export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const isProtected = PROTECTED_PREFIXES.some((prefix) =>
    pathname.startsWith(prefix),
  );

  if (!isProtected) {
    return NextResponse.next();
  }

  const accessToken = request.cookies.get("admin_token")?.value ?? null;
  const refreshToken = request.cookies.get("admin_refresh_token")?.value ?? null;

  if (!accessToken && !refreshToken) {
    return redirectToSignIn(request);
  }

  const needsRefresh = !accessToken || shouldRefreshAccessToken(accessToken);
  if (needsRefresh) {
    if (!refreshToken) {
      return redirectToSignIn(request);
    }

    const refreshed = await refreshWithSupabase(refreshToken);
    if (refreshed.ok) {
      // 1. Update request cookies so Server Components see the new token immediately
      request.cookies.set("admin_token", refreshed.accessToken);
      request.cookies.set("admin_refresh_token", refreshed.refreshToken);

      // 2. Pass the updated request headers to the downstream application
      const response = NextResponse.next({
        request: {
          headers: request.headers,
        },
      });

      // 3. Set cookies on the response so the browser persists them
      response.cookies.set("admin_token", refreshed.accessToken, {
        ...COOKIE_OPTS,
        maxAge: ACCESS_TOKEN_MAX_AGE_SECONDS,
      });
      response.cookies.set("admin_refresh_token", refreshed.refreshToken, {
        ...COOKIE_OPTS,
        maxAge: REFRESH_TOKEN_MAX_AGE_SECONDS,
      });
      return response;
    }

    // Do not continue if access token is missing or already expired.
    if (!accessToken || isExpiredAccessToken(accessToken)) {
      return redirectToSignIn(request);
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    "/dashboard/:path*",
    "/projects/:path*",
    "/updates/:path*",
    "/comments/:path*",
    "/community/:path*",
    "/mining/:path*",
    "/badges/:path*",
    "/quests/:path*",
    "/quest-submissions/:path*",
    "/notifications/:path*",
    "/wallet-users/:path*",
    "/wallet-withdrawals/:path*",
    "/wallet-kyc/:path*",
    "/wallet-settings/:path*",
    "/tips-transactions/:path*",
    "/tip-settings/:path*",
    "/users/:path*",
    "/admin-access/:path*",
    "/roles/:path*",
    "/applications/:path*",
    "/edge-engine/:path*",
    "/audit-log/:path*",
    "/tags/:path*",
    "/settings/:path*",
  ],
};
