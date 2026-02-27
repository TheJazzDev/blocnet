import { cookies } from "next/headers";
import { NextResponse } from "next/server";

const COOKIE_OPTS = {
  httpOnly: true,
  secure: process.env.NODE_ENV === "production",
  sameSite: "lax" as const,
  path: "/",
};

export async function POST(req: Request) {
  const body = (await req.json()) as { token?: string; refreshToken?: string };

  if (!body.token || typeof body.token !== "string") {
    return NextResponse.json({ error: "Missing token" }, { status: 400 });
  }

  const store = await cookies();

  // Access token — keep a short TTL so an abandoned session doesn't linger
  store.set("admin_token", body.token, {
    ...COOKIE_OPTS,
    maxAge: 60 * 60, // 1 hour
  });

  // Refresh token — valid for 7 days (Supabase default)
  if (body.refreshToken && typeof body.refreshToken === "string") {
    store.set("admin_refresh_token", body.refreshToken, {
      ...COOKIE_OPTS,
      maxAge: 60 * 60 * 24 * 7, // 7 days
    });
  }

  return NextResponse.json({ ok: true });
}
