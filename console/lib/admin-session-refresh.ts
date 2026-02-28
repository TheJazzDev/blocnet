import { getSupabaseClient } from "@/lib/supabase";

export const ADMIN_ACCESS_COOKIE = "admin_token";
export const ADMIN_REFRESH_COOKIE = "admin_refresh_token";
export const ADMIN_TWO_FACTOR_COOKIE = "admin_2fa_session";

export const ADMIN_COOKIE_OPTS = {
  httpOnly: true,
  secure: process.env.NODE_ENV === "production",
  sameSite: "lax" as const,
  path: "/",
};

export const ADMIN_ACCESS_TOKEN_MAX_AGE_SECONDS = 60 * 60;
export const ADMIN_REFRESH_TOKEN_MAX_AGE_SECONDS = 60 * 60 * 24 * 7;

export type AdminSessionRefreshResult =
  | {
      ok: true;
      accessToken: string;
      refreshToken: string;
    }
  | {
      ok: false;
      concurrent: boolean;
    };

type CookieDeleteStore = {
  delete: (name: string) => void;
};

type CookieSetStore = {
  set: (name: string, value: string, options?: typeof ADMIN_COOKIE_OPTS & { maxAge?: number }) => void;
};

const inFlightRefreshByToken = new Map<string, Promise<unknown>>();

export function runRefreshWithTokenLock<T>(
  refreshToken: string,
  refresher: () => Promise<T>,
): Promise<T> {
  const inFlight = inFlightRefreshByToken.get(refreshToken) as Promise<T> | undefined;
  if (inFlight) {
    return inFlight;
  }

  const refreshPromise = refresher().finally(() => {
    const current = inFlightRefreshByToken.get(refreshToken);
    if (current === refreshPromise) {
      inFlightRefreshByToken.delete(refreshToken);
    }
  });

  inFlightRefreshByToken.set(refreshToken, refreshPromise);
  return refreshPromise;
}

export function resetRefreshTokenLockForTests(): void {
  inFlightRefreshByToken.clear();
}

export function isConcurrentRefreshError(message: string | undefined): boolean {
  const normalized = message?.toLowerCase() ?? "";
  return normalized.includes("already used") || normalized.includes("reuse interval");
}

export async function refreshAdminSession(
  refreshToken: string,
): Promise<AdminSessionRefreshResult> {
  try {
    const supabase = getSupabaseClient();
    const { data, error } = await supabase.auth.refreshSession({
      refresh_token: refreshToken,
    });

    if (error || !data.session) {
      return { ok: false, concurrent: isConcurrentRefreshError(error?.message) };
    }

    return {
      ok: true,
      accessToken: data.session.access_token,
      refreshToken: data.session.refresh_token,
    };
  } catch {
    return { ok: false, concurrent: false };
  }
}

export function setAdminSessionCookies(
  store: CookieSetStore,
  session: { accessToken: string; refreshToken: string },
): void {
  store.set(ADMIN_ACCESS_COOKIE, session.accessToken, {
    ...ADMIN_COOKIE_OPTS,
    maxAge: ADMIN_ACCESS_TOKEN_MAX_AGE_SECONDS,
  });

  store.set(ADMIN_REFRESH_COOKIE, session.refreshToken, {
    ...ADMIN_COOKIE_OPTS,
    maxAge: ADMIN_REFRESH_TOKEN_MAX_AGE_SECONDS,
  });
}

export function clearAdminSessionCookies(
  store: CookieDeleteStore,
  options?: { clearTwoFactor?: boolean },
): void {
  store.delete(ADMIN_ACCESS_COOKIE);
  store.delete(ADMIN_REFRESH_COOKIE);
  if (options?.clearTwoFactor) {
    store.delete(ADMIN_TWO_FACTOR_COOKIE);
  }
}
