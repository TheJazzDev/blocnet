import { NextResponse } from "next/server";

const COOKIE_OPTS = {
  httpOnly: true,
  secure: process.env.NODE_ENV === "production",
  sameSite: "lax" as const,
  path: "/",
};

export async function POST(req: Request) {
  let body: { token?: string; refreshToken?: string };
  try {
    body = (await req.json()) as { token?: string; refreshToken?: string };
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  if (!body.token || typeof body.token !== "string") {
    return NextResponse.json({ error: "Missing token" }, { status: 400 });
  }

  const response = NextResponse.json({ ok: true });
  let accessTokenStored = false;
  let refreshTokenStored = false;

  // New sign-ins must establish a fresh 2FA admin session.
  response.cookies.delete("admin_2fa_session");

  // Access token is best-effort; refresh cookie is enough for proxy refresh.
  try {
    response.cookies.set("admin_token", body.token, {
      ...COOKIE_OPTS,
      maxAge: 60 * 60, // 1 hour
    });
    accessTokenStored = true;
  } catch {
    accessTokenStored = false;
  }

  // Refresh token — valid for 7 days (Supabase default)
  if (body.refreshToken && typeof body.refreshToken === "string") {
    try {
      response.cookies.set("admin_refresh_token", body.refreshToken, {
        ...COOKIE_OPTS,
        maxAge: 60 * 60 * 24 * 7, // 7 days
      });
      refreshTokenStored = true;
    } catch {
      refreshTokenStored = false;
    }
  }

  if (!accessTokenStored && !refreshTokenStored) {
    return NextResponse.json(
      { error: "Failed to persist auth cookies" },
      { status: 500 },
    );
  }

  return response;
}
