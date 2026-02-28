import { cookies } from "next/headers";
import { NextResponse } from "next/server";
import axios from "axios";

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3080/api";

const COOKIE_OPTS = {
  httpOnly: true,
  secure: process.env.NODE_ENV === "production",
  sameSite: "lax" as const,
  path: "/",
};

type VerifyBody = {
  code?: string;
  recoveryCode?: string;
};

export async function POST(req: Request) {
  const store = await cookies();
  const accessToken = store.get("admin_token")?.value;

  if (!accessToken) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  let body: VerifyBody;
  try {
    body = (await req.json()) as VerifyBody;
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const response = await axios.post<{
    sessionToken: string;
    expiresAt: string;
  }>(`${API_BASE}/admin/security/2fa/login/verify`, body, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "x-admin-panel-request": "1",
      "Content-Type": "application/json",
    },
    validateStatus: () => true,
  });

  if (response.status < 200 || response.status >= 300) {
    const message =
      typeof response.data === "string"
        ? response.data
        : JSON.stringify(response.data ?? {});

    return NextResponse.json(
      { error: message || "2FA verification failed" },
      { status: response.status },
    );
  }

  const sessionToken = response.data?.sessionToken?.trim();
  const expiresAt = new Date(response.data?.expiresAt ?? "");

  if (!sessionToken) {
    return NextResponse.json(
      { error: "2FA session token missing from backend response" },
      { status: 500 },
    );
  }

  const maxAgeSeconds = Number.isFinite(expiresAt.getTime())
    ? Math.max(60, Math.floor((expiresAt.getTime() - Date.now()) / 1000))
    : 60 * 60 * 24 * 7;

  const next = NextResponse.json({ ok: true, expiresAt: response.data.expiresAt });
  next.cookies.set("admin_2fa_session", sessionToken, {
    ...COOKIE_OPTS,
    maxAge: maxAgeSeconds,
  });

  return next;
}
