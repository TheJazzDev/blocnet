import { cookies } from "next/headers";
import { NextResponse } from "next/server";

export async function POST(req: Request) {
  const body = (await req.json()) as { token?: string };

  if (!body.token || typeof body.token !== "string") {
    return NextResponse.json({ error: "Missing token" }, { status: 400 });
  }

  const store = await cookies();
  store.set("admin_token", body.token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    // Token expires in 1 hour (Supabase default); we'll let Supabase handle refresh
    maxAge: 60 * 60,
  });

  return NextResponse.json({ ok: true });
}
