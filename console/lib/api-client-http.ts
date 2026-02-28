import axios, { type AxiosError, type AxiosRequestConfig, type Method } from "axios";

// All client requests go through /api/proxy which reads the httpOnly cookie
// server-side and forwards the Authorization header to the backend.
const PROXY_BASE = "/api/proxy";
const REFRESH_ENDPOINT = "/api/auth/refresh-token";

type RetryableRequestConfig = AxiosRequestConfig & { _retry?: boolean };

const proxyApi = axios.create({
  baseURL: PROXY_BASE,
  withCredentials: true,
  headers: {
    "Content-Type": "application/json",
  },
});
const refreshApi = axios.create({
  withCredentials: true,
});

let inFlightRefresh: Promise<void> | null = null;

function normalizeHeaders(headers?: HeadersInit): Record<string, string> {
  if (!headers) return {};

  if (headers instanceof Headers) {
    const entries: Record<string, string> = {};
    headers.forEach((value, key) => {
      entries[key] = value;
    });
    return entries;
  }

  if (Array.isArray(headers)) {
    return Object.fromEntries(
      headers.map(([key, value]) => [key, String(value)]),
    );
  }

  const normalized: Record<string, string> = {};
  for (const [key, value] of Object.entries(headers)) {
    if (value === undefined) continue;
    normalized[key] = String(value);
  }
  return normalized;
}

async function refreshSessionOnce(): Promise<void> {
  if (!inFlightRefresh) {
    inFlightRefresh = refreshApi
      .post(REFRESH_ENDPOINT)
      .then((res) => {
        if (res.status < 200 || res.status >= 300) {
          throw new Error(`Refresh failed with ${res.status}`);
        }
      })
      .finally(() => {
        inFlightRefresh = null;
      });
  }

  return inFlightRefresh;
}

proxyApi.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const status = error.response?.status;
    const request = error.config as RetryableRequestConfig | undefined;

    if (status === 401 && request && !request._retry) {
      request._retry = true;
      try {
        await refreshSessionOnce();
        return await proxyApi.request(request);
      } catch {
        // Fall through to sign-in redirect + error propagation.
      }
    }

    if (status === 401 && typeof window !== "undefined") {
      window.location.href = `/signin?next=${encodeURIComponent(window.location.pathname)}`;
    }

    return Promise.reject(error);
  },
);

export function toQuery(
  params: Record<string, string | number | undefined | null>,
): string {
  const query = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined || value === null || value === "") continue;
    query.set(key, String(value));
  }
  const encoded = query.toString();
  return encoded ? `?${encoded}` : "";
}

export async function apiFetch<T>(
  path: string,
  options: RequestInit = {},
): Promise<T> {
  const method = (options.method ?? "GET").toUpperCase() as Method;
  const requestConfig: RetryableRequestConfig = {
    url: path,
    method,
    headers: {
      "Content-Type": "application/json",
      ...normalizeHeaders(options.headers),
    },
    signal: options.signal ?? undefined,
  };

  if (method !== "GET" && method !== "HEAD" && options.body != null) {
    requestConfig.data = options.body;
  }

  try {
    const response = await proxyApi.request<T>(requestConfig);
    return response.data;
  } catch (error) {
    if (axios.isAxiosError(error)) {
      const status = error.response?.status ?? "ERR";
      const data = error.response?.data;
      let detail = error.message;
      if (typeof data === "string" && data.trim().length > 0) {
        detail = data;
      } else if (data && typeof data === "object") {
        detail = JSON.stringify(data);
      }
      throw new Error(`API ${status}: ${detail}`);
    }

    throw error instanceof Error ? error : new Error("Unknown API error");
  }
}
