import { NextResponse } from "next/server";

export const revalidate = 300;

function parseCsv(input: string | undefined): string[] {
  return (input ?? "")
    .split(",")
    .map((value) => value.trim())
    .filter((value) => value.length > 0);
}

export async function GET() {
  const configuredAppIds = parseCsv(process.env.BLOCNET_IOS_APP_IDS);
  const fallbackTeamId = process.env.BLOCNET_IOS_TEAM_ID?.trim() || "";
  const fallbackBundleId =
    process.env.BLOCNET_IOS_BUNDLE_ID?.trim() || "io.blocnet.app";
  const appIds =
    configuredAppIds.length > 0
      ? configuredAppIds
      : fallbackTeamId.length > 0
        ? [`${fallbackTeamId}.${fallbackBundleId}`]
        : [];

  const payload = {
    applinks: {
      apps: [],
      details: [
        {
          appIDs: appIds,
          components: [
            { "/": "/*" },
          ],
        },
      ],
    },
  };

  return new NextResponse(JSON.stringify(payload), {
    headers: {
      "Content-Type": "application/json",
    },
  });
}
