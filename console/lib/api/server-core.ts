import 'server-only';
import { cookies } from 'next/headers';
import axios, { type AxiosRequestConfig, type Method } from 'axios';
import { extractApiErrorMessage } from '@/lib/api-error';

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3080/api';

async function getToken(): Promise<string | null> {
  const store = await cookies();
  return store.get('admin_token')?.value ?? null;
}

export function toQuery(
  params: Record<string, string | number | undefined | null>,
): string {
  const query = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined || value === null || value === '') continue;
    query.set(key, String(value));
  }
  const encoded = query.toString();
  return encoded ? `?${encoded}` : '';
}

export async function apiFetch<T>(
  path: string,
  options: RequestInit = {},
): Promise<T> {
  const token = await getToken();

  const method = (options.method ?? 'GET').toUpperCase() as Method;
  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...Object.fromEntries(new Headers(options.headers ?? {})),
  };

  const requestConfig: AxiosRequestConfig = {
    url: `${API_BASE}${path}`,
    method,
    headers,
    validateStatus: () => true,
  };

  if (method !== 'GET' && method !== 'HEAD' && options.body != null) {
    requestConfig.data = options.body;
  }

  const response = await axios.request<T>(requestConfig);

  if (response.status < 200 || response.status >= 300) {
    const detail = extractApiErrorMessage(
      response.data,
      `Request failed with status ${response.status}`,
    );
    throw new Error(detail);
  }

  return response.data;
}
