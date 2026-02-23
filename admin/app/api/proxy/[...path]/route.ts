import { cookies } from "next/headers";
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { getSupabaseClient } from "@/lib/supabase";

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3080/api";
const COOKIE_OPTS = {
  httpOnly: true,
  secure: process.env.NODE_ENV === "production",
  sameSite: "lax" as const,
  path: "/",
};

const inFlightRefreshByToken = new Map<string, Promise<string | undefined>>();

export function runRefreshWithTokenLock(
  refreshToken: string,
  refresher: () => Promise<string | undefined>,
): Promise<string | undefined> {
  const inFlight = inFlightRefreshByToken.get(refreshToken);
  if (inFlight) {
    return inFlight;
  }

  const refreshPromise = refresher().finally(() => {
    const current = inFlightRefreshByToken.get(refreshToken);
    if (current === refreshPromise) {
      inFlightRefreshByToken.delete(refreshToken);
    }
  });

  inFlightRefreshByToken.set(refreshToken, refreshPromise);
  return refreshPromise;
}

export function resetRefreshTokenLockForTests(): void {
  inFlightRefreshByToken.clear();
}

function isConcurrentRefreshError(message: string | undefined): boolean {
  const normalized = message?.toLowerCase() ?? "";
  return normalized.includes("already used") || normalized.includes("reuse interval");
}

async function refreshAccessToken(): Promise<string | undefined> {
  const store = await cookies();
  const refreshToken = store.get("admin_refresh_token")?.value;
  if (!refreshToken) return undefined;

  return runRefreshWithTokenLock(refreshToken, async () => {
    const supabase = getSupabaseClient();
    const { data, error } = await supabase.auth.refreshSession({
      refresh_token: refreshToken,
    });

    if (error || !data.session) {
      // Avoid deleting cookies when refresh rotation races across parallel requests.
      if (!isConcurrentRefreshError(error?.message)) {
        store.delete("admin_token");
        store.delete("admin_refresh_token");
      }
      return undefined;
    }

    const { access_token, refresh_token } = data.session;

    store.set("admin_token", access_token, {
      ...COOKIE_OPTS,
      maxAge: 60 * 60,
    });

    store.set("admin_refresh_token", refresh_token, {
      ...COOKIE_OPTS,
      maxAge: 60 * 60 * 24 * 7,
    });

    return access_token;
  });
}

async function handler(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> },
) {
  const store = await cookies();
  let token = store.get("admin_token")?.value;
  const viewAsRole = store.get("admin_view_as_role")?.value;

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
    fetch(url, {
      method: request.method,
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
        ...(viewAsRole ? { "x-admin-view-as-role": viewAsRole } : {}),
      },
      body,
    });

  let res = await runWithToken(token);
  if (res.status === 401) {
    const refreshedToken = await refreshAccessToken();
    if (refreshedToken) {
      res = await runWithToken(refreshedToken);
    }
  }

  const data = await res.text();

  return new NextResponse(data, {
    status: res.status,
    headers: {
      "Content-Type": res.headers.get("content-type") ?? "application/json",
    },
  });
}

export const GET = handler;
export const POST = handler;
export const PATCH = handler;
export const PUT = handler;
export const DELETE = handler;
