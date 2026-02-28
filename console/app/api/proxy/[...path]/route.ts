import { cookies } from "next/headers";
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import axios, { type Method } from "axios";
import {
  ADMIN_ACCESS_COOKIE,
  ADMIN_REFRESH_COOKIE,
  ADMIN_TWO_FACTOR_COOKIE,
  clearAdminSessionCookies,
  refreshAdminSession,
  runRefreshWithTokenLock,
  setAdminSessionCookies,
} from "@/lib/admin-session-refresh";

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3080/api";

async function refreshAccessToken(): Promise<string | undefined> {
  const store = await cookies();
  const refreshToken = store.get(ADMIN_REFRESH_COOKIE)?.value;
  if (!refreshToken) return undefined;

  return runRefreshWithTokenLock(refreshToken, async () => {
    const result = await refreshAdminSession(refreshToken);
    if (!result.ok) {
      // Avoid deleting cookies when refresh rotation races across parallel requests.
      if (!result.concurrent) {
        clearAdminSessionCookies(store);
      }
      return undefined;
    }

    setAdminSessionCookies(store, {
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    });
    return result.accessToken;
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

  if (!token) {
    token = await refreshAccessToken();
    if (!token) {
      return NextResponse.json({ message: "Unauthorized" }, { status: 401 });
    }
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
    const refreshedToken = await refreshAccessToken();
    if (refreshedToken) {
      res = await runWithToken(refreshedToken);
    }
  }

  const data = typeof res.data === "string" ? res.data : JSON.stringify(res.data ?? {});
  const contentType = res.headers["content-type"];

  return new NextResponse(data, {
    status: res.status,
    headers: {
      "Content-Type": contentType ?? "application/json",
    },
  });
}

export const GET = handler;
export const POST = handler;
export const PATCH = handler;
export const PUT = handler;
export const DELETE = handler;
