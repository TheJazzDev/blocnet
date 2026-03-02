import axios, { type AxiosError, type AxiosRequestConfig, type Method } from "axios";
import { extractApiErrorMessage } from "@/lib/api-error";

// All client requests go through /api/proxy which reads the httpOnly cookie
// server-side and forwards the Authorization header to the backend.
const PROXY_BASE = "/api/proxy";
const REFRESH_ENDPOINT = "/api/auth/refresh-token";

type RetryableRequestConfig = AxiosRequestConfig & { _retry?: boolean };
type ApiFetchOptions = RequestInit & {
  successMessage?: string;
  errorMessage?: string;
  suppressSuccessToast?: boolean;
  suppressErrorToast?: boolean;
};

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
const MAX_AUTH_RETRIES = 2;
const AUTH_RETRY_DELAY_MS = 350;

function wait(ms: number): Promise<void> {
  return new Promise((resolve) => {
    globalThis.setTimeout(resolve, ms);
  });
}

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

function isMutationMethod(method: Method): boolean {
  return method === "POST" || method === "PUT" || method === "PATCH" || method === "DELETE";
}

function extractMessageFromPayload(payload: unknown): string | null {
  if (!payload || typeof payload !== "object") {
    return null;
  }

  const candidate = payload as Record<string, unknown>;
  const value = candidate.message;
  return typeof value === "string" && value.trim().length > 0 ? value : null;
}

async function showToast(kind: "success" | "error", message: string): Promise<void> {
  if (typeof window === "undefined") {
    return;
  }

  const { toast } = await import("sonner");
  if (kind === "success") {
    toast.success(message);
    return;
  }
  toast.error(message);
}

async function refreshSessionOnce(): Promise<void> {
  if (!inFlightRefresh) {
    inFlightRefresh = refreshApi
      .post<{ ok?: boolean; concurrent?: boolean }>(REFRESH_ENDPOINT, undefined, {
        validateStatus: () => true,
      })
      .then((res) => {
        if (res.status === 200) {
          return;
        }

        if (res.status >= 200 && res.status < 300) {
          return;
        }

        if (res.status === 503) {
          throw new Error("Refresh temporarily unavailable");
        }

        if (res.status === 401) {
          throw new Error("Refresh token invalid");
        }

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
    const request = error.config as (RetryableRequestConfig & {
      _authRetryCount?: number;
    }) | undefined;

    if (status === 401 && request) {
      const retryCount = request._authRetryCount ?? 0;
      if (retryCount < MAX_AUTH_RETRIES) {
        request._authRetryCount = retryCount + 1;
        request._retry = true;
        try {
          await refreshSessionOnce();
          return await proxyApi.request(request);
        } catch {
          if (request._authRetryCount < MAX_AUTH_RETRIES) {
            await wait(AUTH_RETRY_DELAY_MS);
            return await proxyApi.request(request);
          }
        }
      }
    }

    if (status === 401 && typeof window !== "undefined") {
      try {
        // One final grace attempt before hard redirect; helps with refresh-rotation races.
        await wait(AUTH_RETRY_DELAY_MS);
      } catch {
        // Ignore wait errors.
      }
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
  options: ApiFetchOptions = {},
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

    if (isMutationMethod(method) && !options.suppressSuccessToast) {
      const successMessage =
        options.successMessage ??
        extractMessageFromPayload(response.data) ??
        "Action completed successfully.";
      void showToast("success", successMessage);
    }

    return response.data;
  } catch (error) {
    let toastMessage = options.errorMessage ?? "Request failed";

    if (axios.isAxiosError(error)) {
      const status = error.response?.status ?? "ERR";
      const data = error.response?.data;
      const fallback =
        status === "ERR"
          ? "Network error. Please try again."
          : "Request failed. Please try again.";
      const detail = extractApiErrorMessage(data, fallback);
      toastMessage = detail;
      if (!options.suppressErrorToast) {
        void showToast("error", toastMessage);
      }
      throw new Error(detail);
    }

    if (!options.suppressErrorToast) {
      const fallbackMessage =
        error instanceof Error ? error.message : toastMessage;
      void showToast("error", fallbackMessage);
    }
    throw error instanceof Error ? error : new Error("Unknown API error");
  }
}
