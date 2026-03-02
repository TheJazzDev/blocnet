import { constants } from "node:fs";
import { access } from "node:fs/promises";
import path from "node:path";
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

function resolveApkFilePath() {
  const channel = resolveReleaseChannel();
  return path.join(
    process.cwd(),
    "public",
    "apks",
    channel,
    "latest.apk",
  );
}

async function isApkAvailable(apkFilePath: string) {
  try {
    await access(apkFilePath, constants.R_OK);
    return true;
  } catch {
    return false;
  }
}

export async function HEAD() {
  const apkFilePath = resolveApkFilePath();
  const available = await isApkAvailable(apkFilePath);

  if (!available) {
    return new NextResponse(null, { status: 404 });
  }

  return new NextResponse(null, { status: 204 });
}

export async function GET(request: Request) {
  const apkFilePath = resolveApkFilePath();
  const available = await isApkAvailable(apkFilePath);

  if (!available) {
    return NextResponse.json(
      { message: "Android app is not available yet. Please check back soon." },
      { status: 404 },
    );
  }

  const channel = resolveReleaseChannel();
  const apkUrl = new URL(`/apks/${channel}/latest.apk`, request.url);
  return NextResponse.redirect(apkUrl);
}
