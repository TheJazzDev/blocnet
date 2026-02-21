import { cookies } from "next/headers";
import { NextResponse } from "next/server";

export async function POST() {
  const store = await cookies();
  store.delete("admin_token");
  store.delete("admin_refresh_token");
  store.delete("admin_view_as_role");
  return NextResponse.json({ ok: true });
}
