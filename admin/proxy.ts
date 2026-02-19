import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

const PROTECTED_PREFIXES = [
  "/dashboard",
  "/projects",
  "/updates",
  "/comments",
  "/community",
  "/users",
  "/applications",
  "/audit-log",
  "/tags",
  "/settings",
];

export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const isProtected = PROTECTED_PREFIXES.some((prefix) =>
    pathname.startsWith(prefix),
  );

  if (!isProtected) {
    return NextResponse.next();
  }

  const hasSession = Boolean(request.cookies.get("admin_token")?.value);
  if (!hasSession) {
    const url = request.nextUrl.clone();
    url.pathname = "/signin";
    url.searchParams.set("next", pathname);
    return NextResponse.redirect(url);
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    "/dashboard/:path*",
    "/projects/:path*",
    "/updates/:path*",
    "/comments/:path*",
    "/community/:path*",
    "/users/:path*",
    "/applications/:path*",
    "/audit-log/:path*",
    "/tags/:path*",
    "/settings/:path*",
  ],
};
