import { cookies } from "next/headers";
import { NextResponse } from "next/server";
import {
  ADMIN_REFRESH_COOKIE,
  clearAdminSessionCookies,
  refreshAdminSession,
  runRefreshWithTokenLock,
  setAdminSessionCookies,
} from "@/lib/admin-session-refresh";

export async function POST() {
  const store = await cookies();
  const refreshToken = store.get(ADMIN_REFRESH_COOKIE)?.value;

  if (!refreshToken) {
    return NextResponse.json({ error: "No refresh token" }, { status: 401 });
  }

  const result = await runRefreshWithTokenLock(refreshToken, () =>
    refreshAdminSession(refreshToken),
  );

  if (!result.ok) {
    // Another in-flight request may have already rotated the refresh token.
    if (result.concurrent) {
      return NextResponse.json({ ok: true, concurrent: true });
    }

    clearAdminSessionCookies(store, { clearTwoFactor: true });
    return NextResponse.json({ error: "Session expired" }, { status: 401 });
  }

  setAdminSessionCookies(store, {
    accessToken: result.accessToken,
    refreshToken: result.refreshToken,
  });
  return NextResponse.json({ ok: true, concurrent: false });
}
