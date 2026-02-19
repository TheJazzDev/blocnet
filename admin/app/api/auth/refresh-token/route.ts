import { cookies } from "next/headers";
import { NextResponse } from "next/server";
import { getSupabaseClient } from "@/lib/supabase";

const COOKIE_OPTS = {
  httpOnly: true,
  secure: process.env.NODE_ENV === "production",
  sameSite: "lax" as const,
  path: "/",
};

export async function POST() {
  const store = await cookies();
  const refreshToken = store.get("admin_refresh_token")?.value;

  if (!refreshToken) {
    return NextResponse.json({ error: "No refresh token" }, { status: 401 });
  }

  const supabase = getSupabaseClient();
  const { data, error } = await supabase.auth.refreshSession({ refresh_token: refreshToken });

  if (error || !data.session) {
    // Refresh token invalid/expired — clear both cookies
    store.delete("admin_token");
    store.delete("admin_refresh_token");
    return NextResponse.json({ error: "Session expired" }, { status: 401 });
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

  return NextResponse.json({ ok: true });
}
