import { NextResponse } from "next/server";

const COOKIE_OPTS = {
  httpOnly: true,
  secure: process.env.NODE_ENV === "production",
  sameSite: "lax" as const,
  path: "/",
};

export async function POST(req: Request) {
  let body: { sessionToken?: string; expiresAt?: string };

  try {
    body = (await req.json()) as { sessionToken?: string; expiresAt?: string };
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const sessionToken = body.sessionToken?.trim();
  if (!sessionToken) {
    return NextResponse.json({ error: "Missing sessionToken" }, { status: 400 });
  }

  const expiresAt = new Date(body.expiresAt ?? "");
  const maxAgeSeconds = Number.isFinite(expiresAt.getTime())
    ? Math.max(60, Math.floor((expiresAt.getTime() - Date.now()) / 1000))
    : 60 * 60 * 24 * 7;

  const response = NextResponse.json({ ok: true });
  response.cookies.set("admin_2fa_session", sessionToken, {
    ...COOKIE_OPTS,
    maxAge: maxAgeSeconds,
  });

  return response;
}
