export type AdminEnvironment = "production" | "development";

const PRODUCTION_HOSTNAMES = new Set([
  "console.blocnet.app",
  "blocnet-console.vercel.app",
]);

function normalizeHostname(host: string | null | undefined): string | null {
  if (!host) return null;
  const trimmed = host.trim().toLowerCase();
  if (!trimmed) return null;
  const [hostnameOnly] = trimmed.split(":");
  return hostnameOnly || null;
}

export function resolveAdminEnvironmentFromHost(
  host: string | null | undefined,
): AdminEnvironment {
  const normalizedHost = normalizeHostname(host);
  if (!normalizedHost) {
    return "development";
  }
  return PRODUCTION_HOSTNAMES.has(normalizedHost)
    ? "production"
    : "development";
}

export function getAdminEnvironmentLabel(env: AdminEnvironment): string {
  return env === "production" ? "Production" : "Development";
}
