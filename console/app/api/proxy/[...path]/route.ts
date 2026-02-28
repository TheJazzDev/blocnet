import { cookies } from "next/headers";
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import axios, { type Method } from "axios";
import {
  ADMIN_ACCESS_COOKIE,
  ADMIN_COOKIE_OPTS,
  ADMIN_REFRESH_COOKIE,
  ADMIN_TWO_FACTOR_COOKIE,
  ADMIN_TWO_FACTOR_COOKIE_MAX_AGE_SECONDS,
  clearAdminSessionCookies,
  refreshAdminSession,
  runRefreshWithTokenLock,
  setAdminSessionCookies,
} from "@/lib/admin-session-refresh";

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3080/api";
const REFRESH_LEEWAY_SECONDS = 90;

type RefreshedSession = {
  accessToken: string;
  refreshToken: string;
};

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

async function refreshAccessToken(): Promise<RefreshedSession | undefined> {
  const store = await cookies();
  const refreshToken = store.get(ADMIN_REFRESH_COOKIE)?.value;
  if (!refreshToken) return undefined;

  return runRefreshWithTokenLock(refreshToken, async () => {
    const result = await refreshAdminSession(refreshToken);
    if (!result.ok) {
      // Avoid deleting cookies when refresh rotation races across parallel requests.
      if (result.reason === "invalid") {
        clearAdminSessionCookies(store);
      }
      return undefined;
    }

    return {
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    };
  });
}

async function handler(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> },
) {
  const store = await cookies();
  let token = store.get(ADMIN_ACCESS_COOKIE)?.value;
  const viewAsRole = store.get("admin_view_as_role")?.value;
  const twoFactorSession = store.get(ADMIN_TWO_FACTOR_COOKIE)?.value;
  let refreshedSession: RefreshedSession | null = null;

  if (!token || shouldRefreshAccessToken(token)) {
    const refreshed = await refreshAccessToken();
    if (refreshed?.accessToken) {
      refreshedSession = refreshed;
      token = refreshed.accessToken;
    }
  }

  if (!token) {
    if (!refreshedSession) {
      return NextResponse.json({ message: "Unauthorized" }, { status: 401 });
    }
    token = refreshedSession.accessToken;
  }

  const { path } = await params;
  const backendPath = path.join("/");
  const search = request.nextUrl.search;
  const url = `${API_BASE}/${backendPath}${search}`;

  const body =
    request.method !== "GET" && request.method !== "HEAD"
      ? await request.text()
      : undefined;

  const runWithToken = async (accessToken: string) =>
    axios.request<string>({
      url,
      method: request.method as Method,
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
        "x-admin-panel-request": "1",
        ...(viewAsRole ? { "x-admin-view-as-role": viewAsRole } : {}),
        ...(twoFactorSession
          ? { "x-admin-2fa-session": twoFactorSession }
          : {}),
      },
      data: body,
      responseType: "text",
      transformResponse: [(raw) => raw],
      validateStatus: () => true,
    });

  let res = await runWithToken(token);
  if (res.status === 401) {
    const refreshed = await refreshAccessToken();
    if (refreshed?.accessToken) {
      refreshedSession = refreshed;
      res = await runWithToken(refreshed.accessToken);
    }
  }

  const data = typeof res.data === "string" ? res.data : JSON.stringify(res.data ?? {});
  const contentType = res.headers["content-type"];

  const response = new NextResponse(data, {
    status: res.status,
    headers: {
      "Content-Type": contentType ?? "application/json",
    },
  });

  if (refreshedSession) {
    setAdminSessionCookies(response.cookies, refreshedSession);
  }
  if (twoFactorSession) {
    response.cookies.set(ADMIN_TWO_FACTOR_COOKIE, twoFactorSession, {
      ...ADMIN_COOKIE_OPTS,
      maxAge: ADMIN_TWO_FACTOR_COOKIE_MAX_AGE_SECONDS,
    });
  }

  return response;
}

export const GET = handler;
export const POST = handler;
export const PATCH = handler;
export const PUT = handler;
export const DELETE = handler;
