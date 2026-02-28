import { NextResponse } from "next/server";

export const revalidate = 300;

function parseCsv(input: string | undefined): string[] {
  return (input ?? "")
    .split(",")
    .map((value) => value.trim())
    .filter((value) => value.length > 0);
}

export async function GET() {
  const packageName =
    process.env.BLOCNET_ANDROID_APP_ID?.trim() || "io.blocnet.app";
  const fingerprints = parseCsv(
    process.env.BLOCNET_ANDROID_SHA256_CERT_FINGERPRINTS,
  );

  return NextResponse.json([
    {
      relation: ["delegate_permission/common.handle_all_urls"],
      target: {
        namespace: "android_app",
        package_name: packageName,
        sha256_cert_fingerprints: fingerprints,
      },
    },
  ]);
}
