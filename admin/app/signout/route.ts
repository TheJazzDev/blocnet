import { NextResponse } from "next/server";

export async function POST(request: Request) {
  const url = new URL(request.url);
  const response = NextResponse.redirect(new URL("/signin", url));
  response.cookies.delete("admin_token");
  response.cookies.delete("admin_session");
  response.cookies.delete("admin_role");
  return response;
}
