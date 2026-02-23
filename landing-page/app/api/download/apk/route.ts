import { NextResponse } from "next/server";

function resolveReleaseChannel(): "dev" | "prod" {
  const raw = (
    process.env.NEXT_PUBLIC_APP_RELEASE_CHANNEL ??
    "prod"
  )
    .trim()
    .toLowerCase();

  if (raw === "dev" || raw === "development") {
    return "dev";
  }

  if (raw === "prod" || raw === "production" || raw === "main") {
    return "prod";
  }

  return "prod";
}

export async function GET(request: Request) {
  const channel = resolveReleaseChannel();
  const apkUrl = new URL(`/apks/${channel}/latest.apk`, request.url);
  return NextResponse.redirect(apkUrl);
}
